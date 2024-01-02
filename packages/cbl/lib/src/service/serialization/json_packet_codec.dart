import 'dart:convert';
import 'dart:typed_data';

import '../../bindings.dart';
import 'serialization.dart';
import 'serialization_codec.dart';

class JsonPacketCodec extends PacketCodec {
  final _jsonDecoder = const Utf8Decoder().fuse(const JsonDecoder());
  final _jsonUtf8Encoder = JsonUtf8Encoder();

  @override
  final SerializationTarget target = SerializationTarget.json;

  @override
  Packet decodePacket(Object? input) {
    final packet = input! as Uint8List;
    final bytes = packet.buffer.asByteData(0, packet.lengthInBytes);
    final parts = <Data>[];
    var offset = 0;
    while (offset < packet.lengthInBytes) {
      final size = bytes.getUint32(offset);
      offset += 4;
      parts.add(Data.fromTypedList(packet.buffer.asUint8List(offset, size)));
      offset += size;
    }

    return Packet(_jsonDecoder.convert(parts.removeAt(0).toTypedList()), parts);
  }

  @override
  Object? encodePacket(Packet packet) {
    final parts = [
      Data.fromTypedList(_jsonUtf8Encoder.convert(packet.value) as Uint8List),
      ...packet.data,
    ];

    final packetBuilder = BytesBuilder();
    for (final part in parts) {
      // Write length of part.
      final length = ByteData(4)..setUint32(0, part.size);
      packetBuilder.add(length.buffer.asUint8List());

      // Write part.
      // ignore: cascade_invocations
      packetBuilder.add(part.toTypedList());
    }

    return packetBuilder.toBytes();
  }
}

PacketCodec createPacketCodec() => JsonPacketCodec();
