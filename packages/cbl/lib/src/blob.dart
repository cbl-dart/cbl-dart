import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'bindings/bindings.dart';
import 'database.dart';
import 'document.dart';
import 'ffi_utils.dart';
import 'fleece.dart';
import 'utils.dart';
import 'worker/handlers.dart';
import 'worker/worker.dart';

// region Internal API

BlobManager createBlobManager({
  required Pointer<CBLDatabase> db,
  required Worker worker,
}) =>
    BlobManager._(db, worker);

// endregion

late final _blobBindings = CBLBindings.instance.blobs.blob;

/// A binary data value associated with a [Document].
///
/// The content of the Blob is not stored in the Document, but externally in the
/// [Database]. It is loaded only on demand, and can be streamed. Blobs can be
/// arbitrarily large, although Sync Gateway will only accept Blobs under 20MB.
///
/// The document contains only a Blob reference: a dictionary with the special
/// marker property `"@type":"blob"`, and another property `digest` whose value
/// is a hex SHA-1 digest of the Blob's data. This digest is used as the key to
/// retrieve the Blob data. The dictionary usually also has the property
/// `length`, containing the Blob's length in bytes, and it may have the
/// property `content_type`, containing a MIME type.
///
/// A Blob object acts as a proxy for such a dictionary in a [Document]. Once
/// you've loaded a Document and located the [Dict] holding the Blob reference,
/// call [ValueBlobExtension]`.blob` on it to create a Blob object you can call.
/// The object has accessors for the Blob's metadata. To access the content of
/// the Blob use [BlobManager.blobContent] or
/// [BlobManager.readStream].
///
/// To create a new Blob from in-memory data, call [BlobManager.createBlob],
/// then add the Blob to a dictionary or array property of the Document.
///
/// To create a new Blob from a stream, call [BlobManager.openWriteStream]
/// to create a [BlobWriteStream], then make one or more calls to
/// [BlobWriteStream.addStream] to write data to the Blob, then finally call
/// [BlobWriteStream.createBlob] to create the blob.
///
/// See:
/// - [BlobWriteStream] for writing a Blob in chunks.
/// - [BlobManager] for the entry point to reading and writing Blob.
class Blob {
  Blob._(this._pointer, {bool retain = false}) {
    CBLBindings.instance.base.bindCBLRefCountedToDartObject(
      this,
      _pointer.cast(),
      retain.toInt,
    );
  }

  final Pointer<CBLBlob> _pointer;

  /// The length in bytes of this Blob's content (from its `length` property).
  int get length => _blobBindings.length(_pointer);

  /// The cryptographic digest of this Blob's content (from its `digest`
  /// property).
  String get digest => _blobBindings.digest(_pointer).asString;

  /// This Blob's MIME type, if its metadata has a `content_type` property.
  String? get contentType =>
      _blobBindings.contentType(_pointer).asNullable?.asString;

  /// This Blob's metadata. This includes the `digest`, `length` and
  /// `content_type` properties, as well as any custom ones that may have been
  /// added.
  MutableDict get properties =>
      MutableDict.fromPointer(_blobBindings.properties(_pointer).cast());
}

late final blobSlotSetter = _BlobSlotSetter();

class _BlobSlotSetter implements SlotSetter {
  @override
  bool canSetValue(Object? value) => value is Blob;

  @override
  void setSlotValue(Pointer<FLSlot> slot, Object? value) =>
      _blobBindings.setBlob(slot, (value as Blob)._pointer);
}

/// Extension to get a [Blob] from a [Dict].
extension DictBlobExtension on Dict {
  /// Returns true if this Dict in a [Document] is a blob reference.
  ///
  /// If so, you can use [asBlob] to access it.
  bool get isBlob => _blobBindings.isBlob(ref.cast()).toBool;

  /// Instantiates a [Blob] object corresponding to a Blob dictionary in a
  /// [Document].
  ///
  /// Returns `null` if this Dict is not a Blob.
  Blob? get asBlob => _blobBindings
      .get(ref.cast())
      .asNullable
      ?.let((it) => Blob._(it, retain: true));
}

/// Extension to get a [Blob] from a [Value].
extension ValueBlobExtension on Value {
  /// Returns true if this Value in a [Document] is a blob reference.
  ///
  /// If so, you can use [asBlob] to access it.
  bool get isBlob => asDict?.isBlob ?? false;

  /// Instantiates a [Blob] object corresponding to a Blob dictionary in a
  /// [Document].
  ///
  /// Returns `null` if this Value is not a Blob.
  Blob? get asBlob => asDict?.asBlob;
}

/// A stream for writing a new [Blob] to the [Database].
///
/// You should call [addStream] one or more times to write the data, then
/// [createBlob] to create the Blob. [addStream] consumes a [Stream] of chunks
/// of data and completes the returned [Future] when all the data from the
/// Stream has been written. You must not call [addStream] again before the
/// Future from the last call has completed.
///
/// If for some reason you need to abort, call [close].
class BlobWriteStream extends StreamConsumer<Uint8List> {
  BlobWriteStream._(this._pointer, this._worker);

  final Pointer<CBLBlobWriteStream> _pointer;

  final Worker _worker;

  /// Writes the chunks in [stream] to this stream.
  ///
  /// You must not call this method again until the returned [Future] completes.
  ///
  /// The first time [stream] emits an error, the subscription to it is canceled
  /// and the returned Future rejects with the error.
  ///
  /// If there is an error writing a chunk the subscription to [stream] is
  /// canceled and the returned Future rejects with the error.
  ///
  /// Even if the returned Future rejects, you have to call [close] if you are
  /// not going to finish the stream with a call to [createBlob].
  @override
  Future<void> addStream(Stream<Uint8List> stream) => stream
      .asyncMap((chunk) => runArena(() {
            final chunkPointer = scoped(malloc<Uint8>(chunk.length));
            chunkPointer.asTypedList(chunk.length).setAll(0, chunk);
            return _worker.makeRequest<void>(WriteToBlobWriteStream(
              _pointer.address,
              chunkPointer.address,
              chunk.length,
            ));
          }))
      .drain();

  /// Closes this stream, if you need to give up without creating a [Blob].
  @override
  Future<void> close() =>
      _worker.makeRequest<void>(CloseBlobWriteStream(_pointer.address));

  /// Creates a new [Blob] after its content has been written to this stream.
  ///
  /// You should then add the Blob to a [MutableDocument] as a property.
  ///
  /// [contentType] is the MIME type of the data written to this stream.
  Future<Blob> createBlob({String? contentType}) async {
    final address = await _worker.makeRequest<int>(CreateBlobWithWriteStream(
      _pointer.address,
      contentType,
    ));

    return Blob._(address.toPointer.cast());
  }
}

/// Manage reading and writing of [Blob]s.
///
/// See:
/// - [Database.blobManager] to get the [BlobManager] instance associated with
///   a Database.
class BlobManager {
  BlobManager._(this._pointer, this._worker);

  final Pointer<CBLDatabase> _pointer;

  final Worker _worker;

  /// Opens a [BlobWriteStream] for writing a new [Blob].
  ///
  /// You have to either use the returned stream to [BlobWriteStream.createBlob]
  /// or [BlobWriteStream.close] it, to free the resources used by it.
  ///
  /// See:
  /// - [BlobWriteStream] for how to add data to the stream and finally create
  ///   the new Blob.
  Future<BlobWriteStream> openWriteStream() async {
    final address =
        await _worker.makeRequest<int>(OpenBlobWriteStream(_pointer.address));

    return BlobWriteStream._(address.toPointer.cast(), _worker);
  }

  /// Creates a new blob given its [content] as a single chunk of data.
  ///
  /// [contentType] is the MIME type of the data in [content].
  Future<Blob> createBlob(
    Uint8List content, {
    String? contentType,
  }) async {
    final writeStream = await openWriteStream();
    await writeStream.addStream(Stream.value(content));
    return writeStream.createBlob(contentType: contentType);
  }

  /// Returns a stream for reading a [Blob]'s content in chunks.
  ///
  /// The maximum size of the emitted chunks can be controlled through
  /// [chunkSize].
  ///
  /// The returned Stream only starts reading after a subscription has been
  /// created and can only be listened to once.
  Stream<Uint8List> readStream(Blob blob, {int chunkSize = 4096}) {
    late StreamController<Uint8List> controller;
    Pointer<Uint8>? buffer;
    Pointer<CBLBlobReadStream>? streamPointer;
    var isPaused = false;

    late Future setup = (() async {
      buffer = malloc(chunkSize);

      streamPointer = (await _worker
              .makeRequest<int>(OpenBlobReadStream(blob._pointer.address)))
          .toPointer
          .cast();
    })();

    Future cleanUp() async {
      await setup.catchError((Object e) {});

      malloc.free(buffer!);
      await _worker
          .makeRequest<void>(CloseBlobReadStream(streamPointer!.address));
    }

    void start() async {
      try {
        isPaused = false;

        await setup;

        while (!isPaused) {
          final bytesRead =
              await _worker.makeRequest<int>(ReadFromBlobReadStream(
            streamPointer!.address,
            buffer!.address,
            chunkSize,
          ));

          // The read stream is done (EOF).
          if (bytesRead == 0) {
            await controller.close();
            break;
          }

          controller.add(Uint8List.fromList(buffer!.asTypedList(bytesRead)));
        }
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        await controller.close();
      }
    }

    void pause() {
      isPaused = true;
    }

    controller = StreamController(
      onListen: start,
      onPause: pause,
      onResume: start,
      onCancel: () async {
        pause();
        await cleanUp();
      },
    );

    return controller.stream;
  }

  /// Reads the [Blob]'s contents into memory and returns them.
  Future<Uint8List> blobContent(Blob blob) =>
      readStream(blob).toList().then(jointUint8Lists);
}
