import 'dart:async';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:meta/meta.dart';

import '../database/blob_store.dart';
import '../database/database.dart';
import '../fleece/encoder.dart';
import '../fleece/fleece.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'common.dart';
import 'document.dart';

const cblObjectTypeProperty = '@type';
const cblObjectTypeBlob = 'blob';

const blobDigestProperty = 'digest';
const blobDataProperty = 'data';
const blobLengthProperty = 'length';
const blobContentTypeProperty = 'content_type';

/// A Blob contains arbitrary binary data, tagged with a MIME type.
///
/// Blobs can be arbitrarily large, and their data is loaded only on demand
/// (when the [content] or [contentStream] properties are accessed), not when
/// the [Document] is loaded. The document’s raw JSON form only contains the
/// Blob’s metadata (type, [length] and a [digest] of the data) in a small
/// object. The data itself is stored externally to the document, keyed by the
/// digest.
@immutable
abstract class Blob {
  /// Creates a [Blob] with the given in-memory data.
  factory Blob.fromData(String contentType, Uint8List data) =>
      BlobImpl.fromData(contentType, data);

  /// Creates a [Blob] from a [stream] of chunks of data.
  static Future<Blob> fromStream(
    String contentType,
    Stream<Uint8List> stream,
    Database database,
  ) =>
      BlobImpl.fromStream(contentType, stream, database);

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
  Map<String, Object?> get properties;

  /// Returns this blob's JSON representation.
  String toJson();

  /// Wether a plain Dart [Map] represents a [Blob].
  static bool isBlob(Map<String, Object?> properties) {
    if (!properties.containsKey(blobDigestProperty) ||
        properties[blobDigestProperty] is! String ||
        !properties.containsKey(cblObjectTypeProperty) ||
        properties[cblObjectTypeProperty] != cblObjectTypeBlob ||
        !properties.containsKey(blobContentTypeProperty) ||
        properties[blobContentTypeProperty] is! String ||
        !properties.containsKey(blobLengthProperty) ||
        properties[blobLengthProperty] is! int) {
      return false;
    }
    return true;
  }
}

// The semantics of a Blob are that it is immutable but the implementation is
// not.
// ignore: must_be_immutable
class BlobImpl implements Blob, FleeceEncodable, CblConversions {
  BlobImpl.fromData(String contentType, Uint8List data)
      : _contentType = contentType,
        _length = data.length,
        _content = data;

  BlobImpl.fromProperties(
    Map<String, Object?> properties, {
    Database? database,
  })  : assert(properties[cblObjectTypeProperty] == cblObjectTypeBlob),
        _database = database,
        _contentType = properties[blobContentTypeProperty] as String?,
        // ignore: cast_nullable_to_non_nullable
        _length = properties[blobLengthProperty] as int,
        _digest = properties[blobDigestProperty] as String?,
        // ignore: unnecessary_parenthesis
        _content = (properties[blobDataProperty] as Uint8List?) {
    if (_digest == null && _content == null) {
      throw StateError(
        'Blob loaded from database has neither the `digest` nor the `data` '
        'property.',
      );
    }
  }

  static Future<Blob> fromStream(
    String contentType,
    Stream<Uint8List> stream,
    Database database,
  ) async {
    final blobStore = (database as BlobStoreHolder).blobStore;
    final properties = await blobStore.saveBlobFromStream(
      contentType,
      stream.map((list) => list.toData()),
    );
    return BlobImpl.fromProperties(properties, database: database);
  }

  /// Max size of data that will be cached in memory with the [Blob].
  static const _maxCachedContentLength = 8 * 1024;

  Database? _database;
  BlobStore? get _blobStore => (_database as BlobStoreHolder?)?.blobStore;

  Uint8List? _content;

  final String? _contentType;
  final int _length;
  String? _digest;

  @override
  String? get contentType => _contentType;

  @override
  int? get length => _length;

  @override
  String? get digest => _digest;

  @override
  Future<Uint8List> content() => byteStreamToFuture(contentStream());

  @override
  Stream<Uint8List> contentStream() {
    final content = _content;
    if (content != null) {
      return Stream.value(content);
    }

    if (_digest != null && _blobStore != null) {
      final stream = _blobStore!
          .readBlob(_blobProperties())
          ?.map((data) => data.toTypedList());
      if (stream == null) {
        _throwNotFoundError();
      }

      if (_shouldCacheContent) {
        final byteBuilder = BytesBuilder(copy: false);
        return stream.transform(StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            if (_content == null) {
              byteBuilder.add(data);
            }
            sink.add(UnmodifiableUint8ListView(data));
          },
          handleDone: (sink) {
            _content ??= byteBuilder.toBytes();
            sink.close();
          },
        ));
      }

      return stream;
    }

    _throwNotSavedError("Cannot load blob's content.");
  }

  @override
  Map<String, Object?> get properties => {
        if (_contentType != null) blobContentTypeProperty: _contentType,
        blobLengthProperty: _length,
        if (_digest != null) blobDigestProperty: _digest,
      };

  Map<String, Object?> _blobProperties({bool mayIncludeData = false}) => {
        cblObjectTypeProperty: cblObjectTypeBlob,
        ...properties,
        if (mayIncludeData && _digest == null) blobDataProperty: _content,
      };

  @override
  String toJson() {
    final encoder = FleeceEncoder(format: FLEncoderFormat.json);
    final done = encodeTo(encoder);
    assert(done is! Future);
    return encoder.finish().toDartString();
  }

  @override
  FutureOr<void> encodeTo(FleeceEncoder encoder) {
    final extraInfo = encoder.extraInfo;
    final context = (extraInfo is FleeceEncoderContext) ? extraInfo : null;

    void writeProperties(Map<String, Object?> properties) {
      _digest = properties[blobDigestProperty] as String?;

      final blobProperties = _blobProperties(
        mayIncludeData: context?.encodeQueryParameter ?? false,
      );

      if (blobProperties[blobDigestProperty] == null &&
          blobProperties[blobDataProperty] == null) {
        _throwNotSavedError('Cannot serialize unsaved blob.');
      }

      encoder.writeDartObject(blobProperties);
    }

    if (context != null && context.saveExternalData) {
      final database = context.database;
      if (database != null) {
        _checkBlobIsFromSameDatabase(database);
        _database = database;

        if (_digest == null) {
          assert(_content != null);

          final blobStore = _blobStore!;
          if (blobStore is SyncBlobStore) {
            return blobStore
                .saveBlobFromDataSync(_contentType!, _content!.toData())
                .let(writeProperties);
          } else {
            return blobStore
                .saveBlobFromData(_contentType!, _content!.toData())
                .then(writeProperties);
          }
        }
      }
    }

    writeProperties(_blobProperties());
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

    if (_digest == null || other._digest == null) {
      _throwNotSavedError('Cannot compare unsaved blobs.');
    }

    return _digest == other._digest;
  }

  @override
  int get hashCode {
    if (_digest == null) {
      _throwNotSavedError("Cannot compute the blob's hash code.");
    }

    return _digest.hashCode;
  }

  @override
  String toString() {
    final contentType = _contentType != null ? '$_contentType; ' : '';
    final length = '${((_length + 512) / 1024).toStringAsFixed(1)} KB';
    return 'Blob($contentType$length)';
  }

  bool get _shouldCacheContent => _length < _maxCachedContentLength;

  Never _throwNotSavedError(String message) {
    throw StateError(
      '$message Save the document, containing the blob, first.',
    );
  }

  Never _throwNotFoundError() {
    throw StateError('Could not find blob in $_database: $_blobProperties');
  }

  void _checkBlobIsFromSameDatabase(Object database) {
    if (_database != null && _database != database) {
      throw StateError(
        'A document contains a blob that was saved to a different database. '
        'The save operation cannot complete.',
      );
    }
  }
}
