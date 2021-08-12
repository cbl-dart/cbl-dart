import 'package:cbl_ffi/cbl_ffi.dart';

import 'serialization.dart';
import 'serialization_codec.dart';

class IsolatePacketCodec extends PacketCodec {
  @override
  final SerializationTarget target = SerializationTarget.isolatePort;

  @override
  Packet decodePacket(Object? input) {
    final packet = (input! as List).cast<Object>();
    return Packet(
      packet.removeAt(0),
      packet.map(_fromTransferableData).toList(),
    );
  }

  @override
  Object? encodePacket(Packet packet) => [
        packet.value,
        ...packet.data.map(_toTransferableData),
      ];
}

Data _fromTransferableData(Object data) =>
    (data as TransferableData).materialize();

Object _toTransferableData(Data data) => TransferableData(data);

PacketCodec createPacketCodec() => IsolatePacketCodec();
