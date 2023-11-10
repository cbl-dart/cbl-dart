import 'dart:convert';

import '../../bindings.dart';
import 'packet_codec_factory.dart'
    if (dart.library.io) 'isolate_packet_codec.dart'
    if (dart.library.html) 'json_packet_codec.dart';
import 'serialization.dart';

class Packet {
  Packet(this.value, this.data);

  /// The serialized value of this packet.
  final Object? value;

  /// The binary data contained in the deserialized form of [value].
  final List<Data> data;
}

/// A codec for encoding and decoding [Packet]s for transport with a [target].
abstract class PacketCodec {
  SerializationTarget get target;

  Packet decodePacket(Object? input);

  Object? encodePacket(Packet packet);
}

/// A [Codec] which uses a [PacketCodec] and a [SerializationRegistry] to encode
/// and decode values.
class SerializationCodec extends Codec<Object?, Object?> {
  /// Creates a [SerializationCodec] with the given [registry] and
  /// [packetCodec].
  ///
  /// If no packet codec is provided the appropriate [PacketCodec] for the
  /// current platform is used (`IsolatePacketCodec` on native and
  /// `JsonPackteCodec` on the web).
  SerializationCodec(this.registry, {PacketCodec? packetCodec})
      : packetCodec = packetCodec ?? createPacketCodec();

  final SerializationRegistry registry;

  final PacketCodec packetCodec;

  @override
  late final decoder = _Decoder(registry, packetCodec);

  @override
  late final encoder = _Encoder(registry, packetCodec);
}

class _Decoder extends Converter<Object?, Object?> {
  _Decoder(this.registry, this.codec);

  final SerializationRegistry registry;
  final PacketCodec codec;

  @override
  Object? convert(Object? input) {
    final packet = codec.decodePacket(input);
    final context = SerializationContext(
      registry: registry,
      target: codec.target,
      data: packet.data,
    );
    return context.deserializePolymorphic(packet.value);
  }

  @override
  Sink<Object?> startChunkedConversion(Sink<Object?> sink) =>
      _ChunkConversionSinkTransformer(sink, convert);
}

class _Encoder extends Converter<Object?, Object?> {
  _Encoder(this.registry, this.codec);

  final SerializationRegistry registry;
  final PacketCodec codec;

  @override
  Object? convert(Object? input) {
    final context =
        SerializationContext(registry: registry, target: codec.target);
    final value = context.serializePolymorphic(input);
    final packet = Packet(value, context.data);
    return codec.encodePacket(packet);
  }

  @override
  Sink<Object?> startChunkedConversion(Sink<Object?> sink) =>
      _ChunkConversionSinkTransformer(sink, convert);
}

class _ChunkConversionSinkTransformer<S, T>
    implements ChunkedConversionSink<S> {
  _ChunkConversionSinkTransformer(this.target, this.transform);

  final Sink<T> target;
  final T Function(S) transform;

  @override
  void add(S chunk) => target.add(transform(chunk));

  @override
  void close() => target.close();
}
