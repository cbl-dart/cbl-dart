import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';

import '../database/database.dart';
import '../fleece/encoder.dart';
import '../fleece/fleece.dart';
import '../fleece/fleece.dart' as fl;
import '../log/logger.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'common.dart';
import 'document.dart';

late final _blobBindings = CBLBindings.instance.blobs.blob;

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
      value.native.call((pointer) => _blobBindings.setBlob(slot, pointer));
}

late final _bindings = CBLBindings.instance.blobs;

class BlobImpl
    with NativeResourceMixin<CBLBlob>
    implements Blob, FleeceEncodable, CblConversions {
  BlobImpl({
    required DatabaseImpl? database,
    required Pointer<CBLBlob> blob,
    bool adopt = true,
    required String debugCreator,
  })  : assert(blob != nullptr),
        _database = database,
        _blob = CblObject(
          blob,
          adopt: adopt,
          debugName: 'Blob(creator: $debugCreator)',
        ) {
    _contentType = native.call(_blobBindings.contentType);
    _length = native.call(_blobBindings.length);
    _digest = native.call(_blobBindings.digest);
  }

  BlobImpl.fromData(String contentType, Uint8List data)
      : _blob = CblObject(
          _blobBindings.createWithData(contentType, data),
          debugName: 'Blob.fromData()',
        ),
        _contentType = contentType,
        _length = data.length {
    _digest = native.call(_blobBindings.digest);
  }

  BlobImpl.fromProperties(Map<String, Object?> properties)
      : assert(properties[_typeProperty] == _blobType),
        _contentType = properties[_blobContentTypeProperty] as String?,
        _length = properties[_blobLengthProperty] as int,
        _digest = properties[_blobDigestProperty] as String;

  DatabaseImpl? _database;
  CblObject<CBLBlob>? _blob;
  @override
  CblObject<CBLBlob> get native => _blob!;
  Uint8List? _content;
  String? _contentType;
  int? _length;
  String? _digest;

  @override
  Future<Uint8List> content() async => byteStreamToFuture(contentStream());

  @override
  Stream<Uint8List> contentStream() =>
      _loadSavedContentAsync() ??
      Future(() {
        final content = _loadContentSync();
        if (content == null) {
          _throwNoDataError();
        }
        return content;
      }).asStream();

  Stream<Uint8List>? _loadSavedContentAsync() {
    if (_blob != null && _database != null) {
      return _BlobReadStreamController(this).stream;
    }
  }

  Uint8List? _loadContentSync() {
    var content = _content;

    if (content == null) {
      final blob = _blob;
      if (blob != null) {
        final slice = blob
            .call(_blobBindings.content)
            .let(SliceResult.fromFLSliceResult)!;
        content = slice.asBytes();
        if (content.length <= _maxCachedContentLength) {
          _content = content;
          _length = content.length;
        }
      }
    }

    return content;
  }

  Never _throwNoDataError() {
    if (_digest != null) {
      cblLogMessage(
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
      if (_digest != null && _blob == null) {
        // Blob was created from properties.
        encoder.writeDartObject(_blobProperties);
      } else {
        encoder.writeBlob(this);
      }

      final database = encoder.extraInfo.document.database;
      if (database != null) {
        _checkBlobIsFromSameDatabase(database);
        _database = database;

        if (_digest == null) {
          return _throwNoDataError();
        }
      }
    } else {
      encoder.writeDartObject(_blobProperties);
    }
  }

  void _checkBlobIsFromSameDatabase(DatabaseImpl database) {
    if (_database != null && _database != database) {
      throw StateError(
        'A document contains a blob that was saved to a different database. '
        'The save operation cannot complete.',
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

class _BlobReadStreamController
    extends ClosableResourceStreamController<Uint8List> {
  _BlobReadStreamController(this._blob) : super(parent: _blob._database!);

  final BlobImpl _blob;

  var _streamIsOpen = false;
  late Pointer<CBLBlobReadStream> _streamPointer;
  var _isPaused = false;

  @override
  void onListen() => _start();

  @override
  void onPause() => _pause();

  @override
  void onResume() => _start();

  @override
  void onCancel() {
    _pause();
    _cleanUp();
  }

  void _ensureStreamIsOpen() {
    if (_streamIsOpen) {
      return;
    }
    _streamIsOpen = true;
    _streamPointer = _blob.native.call((pointer) =>
        _bindings.readStream.openContentStream(pointer, _readStreamChunkSize));
  }

  void _cleanUp() {
    if (_streamIsOpen) {
      _bindings.readStream.close(_streamPointer);
    }
  }

  void _start() {
    try {
      _isPaused = false;

      _ensureStreamIsOpen();

      while (!_isPaused) {
        final buffer = _bindings.readStream.read(_streamPointer);

        // The read stream is done (EOF).
        if (buffer == null) {
          controller.close();
          break;
        }

        controller.add(Uint8List.fromList(buffer.bytes));
      }
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
      controller.close();
    }
  }

  void _pause() => _isPaused = true;
}
