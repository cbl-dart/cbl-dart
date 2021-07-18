import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';
import 'package:synchronized/synchronized.dart';

import '../couchbase_lite.dart';
import '../database.dart';
import '../errors.dart';
import '../fleece/encoder.dart';
import '../fleece/fleece.dart';
import '../fleece/fleece.dart' as fl;
import '../native_object.dart';
import '../resource.dart';
import '../streams.dart';
import '../utils.dart';
import '../worker/cbl_worker.dart';
import '../worker/cbl_worker/blob.dart';
import 'common.dart';
import 'document.dart';

late final _blobBindings = CBLBindings.instance.blobs.blob;
late final _blobWriteStreamBindings = CBLBindings.instance.blobs.writeStream;

/// Max size of data that will be cached in memory with the [Blob].
const _maxCachedContentLength = 8 * 1024;

/// Size of the chunks which a blob read stream emits.
const _readStreamChunkSize = 8 * 1024;

const _typeProperty = '@type';
const _blobType = 'blob';

const _blobDigestProperty = 'digest';
// TODO: _blobDataProperty
// const _blobDataProperty = 'data';
const _blobLengthProperty = 'length';
const _blobContentTypeProperty = 'content_type';

/// A Blob contains arbitrary binary data, tagged with a MIME type.
///
/// Blobs can be arbitrarily large, and their data is loaded only on demand
/// (when the [content] or [contentStream] properties are accessed), not when
/// the [Document] is loaded. The document’s raw JSON form only contains the
/// Blob’s metadata (type, [length] and a [digest] of the data) in a small
/// object. The data itself is stored externally to the document, keyed by the
/// digest.
abstract class Blob {
  /// Creates a [Blob] with the given in-memory data.
  factory Blob.fromData(String contentType, Uint8List data) =>
      BlobImpl.fromData(contentType, data);

  /// Creates a [Blob] with the given stream of data.
  factory Blob.fromStream(String contentType, Stream<Uint8List> stream) =>
      BlobImpl.fromStream(contentType, stream);

  /// Creates a [Blob] with the contents of a file.
  factory Blob.fromFileUrl(String contentType, Uri url) {
    if (!FileSystemEntity.isFileSync(url.toFilePath())) {
      throw ArgumentError.value(url, 'url', 'is not a path to a file');
    }

    return BlobImpl.fromStream(
      contentType,
      File.fromUri(url).openRead().cast(),
    );
  }

  /// Gets the contents of this [Blob] as a block of memory.
  ///
  /// Not recommended for very large blobs, as it may be slow and use up lots of
  /// RAM.
  ///
  /// See also:
  ///  * [contentStream] for streaming of the Blob's contents in chunks.
  Future<Uint8List> content();

  /// A stream of the content of this [Blob].
  Stream<Uint8List> contentStream();

  /// The type of content this [Blob] represents.
  ///
  /// By convention this is a MIME type.
  String? get contentType;

  /// The binary length of this [Blob].
  int? get length;

  /// The cryptographic digest of this [Blob]’s [content], which uniquely
  /// identifies it.
  String? get digest;

  /// The metadata associated with this [Blob].
  Map<String, dynamic> get properties;

  /// Wether a plain Dart [Map] represents a [Blob].
  static bool isBlob(Map<String, dynamic> properties) {
    if (!properties.containsKey(_blobDigestProperty) ||
        properties[_blobDigestProperty] is! String ||
        !properties.containsKey(_typeProperty) ||
        properties[_typeProperty] != _blobType ||
        !properties.containsKey(_blobContentTypeProperty) ||
        properties[_blobContentTypeProperty] is! String ||
        !properties.containsKey(_blobLengthProperty) ||
        properties[_blobLengthProperty] is! int) {
      return false;
    }
    return true;
  }
}

class BlobImplSetter extends fl.SlotSetter {
  @override
  bool canSetValue(Object? value) => value is BlobImpl;

  @override
  void setSlotValue(Pointer<FLSlot> slot, covariant BlobImpl value) =>
      value._blob!.keepAlive((pointer) => _blobBindings.setBlob(slot, pointer));
}

class BlobImpl implements Blob, FleeceEncodable, CblConversions {
  BlobImpl({
    required DatabaseImpl? database,
    required Pointer<CBLBlob> blob,
    required bool retain,
    required String debugCreator,
  })  : assert(blob != nullptr),
        _database = database,
        _blob = CblRefCountedObject(
          blob,
          release: true,
          retain: retain,
          debugName: 'Blob(creator: $debugCreator)',
        ) {
    _contentType = _blob!.keepAlive(_blobBindings.contentType);
    _length = _blob!.keepAlive(_blobBindings.length);
    _digest = _blob!.keepAlive(_blobBindings.digest);
  }

  BlobImpl.fromData(String contentType, Uint8List data)
      : _blob = CblRefCountedObject(
          _blobBindings.createWithData(contentType, data),
          release: true,
          retain: false,
          debugName: 'Blob.fromData()',
        ),
        _contentType = contentType,
        _length = data.length {
    _digest = _blob!.keepAlive(_blobBindings.digest);
  }

  BlobImpl.fromStream(String contentType, Stream<Uint8List> stream)
      : _initialContentStream = stream,
        _contentType = contentType;

  BlobImpl.fromProperties(Map<String, dynamic> properties)
      : assert(properties[_typeProperty] == _blobType),
        _contentType = properties[_blobContentTypeProperty] as String?,
        _length = properties[_blobLengthProperty] as int,
        _digest = properties[_blobDigestProperty] as String;

  final _lock = Lock();
  DatabaseImpl? _database;
  CblRefCountedObject<CBLBlob>? _blob;
  Uint8List? _content;
  Stream<Uint8List>? _initialContentStream;
  String? _contentType;
  int? _length;
  String? _digest;

  @override
  Future<Uint8List> content() async =>
      _loadSavedContent()?.let(byteStreamToFuture) ?? _loadUnsavedContent();

  @override
  Stream<Uint8List> contentStream() =>
      _loadSavedContent() ?? _loadUnsavedContent().asStream();

  Stream<Uint8List>? _loadSavedContent() {
    if (_blob != null && _database != null) {
      return _BlobReadStreamController(this).stream;
    }
  }

  Future<Uint8List> _loadUnsavedContent() async {
    final content = await _loadContentFromInitialSteam() ?? _loadContentSync();

    if (content == null) {
      _throwNoDataError();
    }

    return content;
  }

  Uint8List? _loadContentSync() {
    var content = _content;

    if (content == null) {
      final blob = _blob;
      if (blob != null) {
        final slice = withCBLErrorExceptionTranslation(() {
          return blob
              .keepAlive(_blobBindings.content)
              .let(SliceResult.fromFLSliceResult)!;
        });
        content = slice.asBytes();
        if (content.length <= _maxCachedContentLength) {
          _content = content;
          _length = content.length;
        }
      }
    }

    return content;
  }

  Future<Uint8List?> _loadContentFromInitialSteam() =>
      // The lock ensures that the `_initialContentStream` is only consumed
      // once.
      _lock.synchronized(() async {
        final initialContentStream = _initialContentStream;
        if (initialContentStream != null) {
          try {
            final content = await byteStreamToFuture(initialContentStream);
            _content = content;
            _length = content.length;
            return content;
          } finally {
            _initialContentStream = null;
          }
        }
      });

  Never _throwNoDataError() {
    if (_digest != null) {
      logMessage(
        LogDomain.database,
        LogLevel.warning,
        'Cannot access content from a blob that contains only metadata. '
        'To access the content, save the document first.',
      );
    }

    throw StateError('Blob has no data available.');
  }

  @override
  String? get contentType => _contentType;

  @override
  int? get length => _length;

  @override
  String? get digest => _digest;

  @override
  Map<String, dynamic> get properties => <String, dynamic>{
        _blobContentTypeProperty: _contentType,
        _blobLengthProperty: _length,
        _blobDigestProperty: _digest,
      };

  Map<String, dynamic> get _blobProperties => <String, dynamic>{
        _typeProperty: _blobType,
        ...properties,
      };

  @override
  FutureOr<void> encodeTo(FleeceEncoder encoder) {
    if (encoder is DocumentFleeceEncoder) {
      encoder.writeBlob(this);

      final database = encoder.extraInfo.document.database;
      if (database != null) {
        _checkBlobIsFromSameDatabase(database);
        _database = database;

        if (_digest == null) {
          return _installInDatabase(database);
        }
      }
    } else {
      encoder.writeDartObject(_blobProperties);
    }
  }

  Future<void> _installInDatabase(DatabaseImpl database) async {
    final writeStream = _BlobWriteStream(database);
    await _lock.synchronized(() async {
      _checkBlobCanLoadData();
      final contentStream = _initialContentStream ?? Stream.value(_content!);
      try {
        await writeStream.addStream(contentStream);
      } finally {
        _initialContentStream = null;
      }
    });
    final blob = await writeStream.createBlob(contentType: _contentType);
    _blob = CblRefCountedObject(
      blob,
      release: true,
      retain: false,
      debugName: 'Blob(creator: BlobImpl._installStreamInDatabase())',
    );
    _length = _blob!.keepAlive(_blobBindings.length);
    _digest = _blob!.keepAlive(_blobBindings.digest);
  }

  void _checkBlobIsFromSameDatabase(DatabaseImpl database) {
    if (_database != null && _database != database) {
      throw StateError(
        'A document contains a blob that was saved to a different database. '
        'The save operation cannot complete.',
      );
    }
  }

  void _checkBlobCanLoadData() {
    if (_content == null && _initialContentStream == null) {
      throw StateError(
        'A document contains a blob which previously was unable to read the '
        'stream it was created from. Streams are only attempted to be read '
        'once. The save operation cannot complete.',
      );
    }
  }

  @override
  Object? toCblObject() => this;

  @override
  Object? toPlainObject() => this;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! BlobImpl || runtimeType != other.runtimeType) {
      return false;
    }

    if (_digest != null && other._digest != null) {
      return _digest == other._digest;
    }

    final content = _loadContentSync();
    final otherContent = other._loadContentSync();
    if (content != null && otherContent != null) {
      return const DeepCollectionEquality().equals(
        _loadContentSync(),
        other._loadContentSync(),
      );
    }

    return false;
  }

  @override
  int get hashCode {
    final digest = _digest;
    if (digest != null) {
      return digest.hashCode;
    }

    final content = _loadContentSync();
    if (content != null) {
      return const DeepCollectionEquality().hash(content);
    }

    return super.hashCode;
  }

  @override
  String toString() {
    final contentType = _contentType != null ? '$_contentType; ' : '';
    final length = _length != null
        ? '${((_length! + 512) / 1024).toStringAsFixed(1)} KB'
        : '? KB';
    return 'Blob($contentType$length)';
  }
}

class _BlobWriteStream
    extends NativeResource<SimpleWorkerObject<CBLBlobWriteStream>>
    with ClosableResourceMixin
    implements StreamConsumer<Uint8List> {
  _BlobWriteStream(DatabaseImpl database)
      : super(SimpleWorkerObject(
          withCBLErrorExceptionTranslation(() {
            return database.native.keepAlive(_blobWriteStreamBindings.create);
          }),
          database.native.worker,
        )) {
    database.registerChildResource(this);
  }

  @override
  Future<void> addStream(Stream<Uint8List> stream) => use(() => stream
      .asyncMap((chunk) =>
          native.execute((pointer) => WriteToBlobWriteStream(pointer, chunk)))
      .drain());

  Future<Pointer<CBLBlob>> createBlob({String? contentType}) => closeAndUse(
        () => native
            .execute((pointer) => CreateBlobWithWriteStream(
                  pointer,
                  contentType,
                ))
            .then((result) => result.pointer),
        doPerformClose: false,
      );

  @override
  Future<void> performClose() =>
      native.execute((pointer) => CloseBlobWriteStream(pointer));
}

class _BlobReadStreamController
    extends ClosableResourceStreamController<Uint8List> {
  _BlobReadStreamController(this._blob) : super(parent: _blob._database!);

  final BlobImpl _blob;

  Worker get _worker => _blob._database!.native.worker;

  Future<void>? _setupDone;
  late Pointer<CBLBlobReadStream> _streamPointer;
  var _isPaused = false;

  @override
  Future<void> onListen() => _start();

  @override
  void onPause() => _pause();

  @override
  void onResume() => _start();

  @override
  Future<void> onCancel() async {
    _pause();
    await _cleanUp();
  }

  Future<void> _setup() async {
    _streamPointer = await runKeepAlive(() => _worker
        .execute(OpenBlobReadStream(_blob._blob!.pointer, _readStreamChunkSize))
        .then((result) => result.pointer));
  }

  Future<void> _cleanUp() async {
    await _setupDone;

    await _worker.execute(CloseBlobReadStream(_streamPointer));
  }

  Future<void> _start() async {
    try {
      _isPaused = false;

      await (_setupDone ??= _setup());

      while (!_isPaused) {
        final buffer =
            await _worker.execute(ReadFromBlobReadStream(_streamPointer));

        // The read stream is done (EOF).
        if (buffer == null) {
          await controller.close();
          break;
        }

        controller.add(Uint8List.fromList(buffer.bytes));
      }
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
      await controller.close();
    }
  }

  void _pause() => _isPaused = true;
}
