import 'package:cbl_ffi/cbl_ffi.dart';

import 'serialization.dart';
import 'serialization_codec.dart';

class IsolatePacketCodec extends PacketCodec {
  @override
  final SerializationTarget target = SerializationTarget.isolatePort;

  @override
  Packet decodePacket(Object? input) {
    final packet = input! as List<Object?>;
    return Packet(
      packet[0],
      packet.length == 1
          ? const []
          : packet
              .skip(1)
              .map((data) => _fromTransferableData(data!))
              .toList(growable: false),
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
