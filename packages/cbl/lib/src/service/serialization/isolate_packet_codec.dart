import 'serialization.dart';
import 'serialization_codec.dart';

class IsolatePacketCodec extends PacketCodec {
  @override
  final SerializationTarget target = SerializationTarget.isolatePort;

  @override
  Packet decodePacket(Object? input) => Packet(input, []);

  @override
  Object? encodePacket(Packet packet) {
    assert(
      packet.data.isEmpty,
      'IsolatePacketCodec does not support data outside of message',
    );
    return packet.value;
  }
}

PacketCodec createPacketCodec() => IsolatePacketCodec();
