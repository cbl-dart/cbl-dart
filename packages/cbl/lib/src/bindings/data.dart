import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'slice.dart';

abstract class Data {
  Data._();

  factory Data.fromTypedList(Uint8List list) => _TypedListData(list);

  factory Data.fromSliceResult(SliceResult slice) => _SliceResultData(slice);

  int get size;

  Uint8List toTypedList();

  SliceResult toSliceResult();

  String toDartString({Encoding encoding = utf8}) =>
      encoding.decode(toTypedList());

  TransferableData _createTransferableData();
}

abstract class TransferableData {
  factory TransferableData(Data data) => data._createTransferableData();

  TransferableData._();

  Data materialize();
}

class _TypedListData extends Data {
  _TypedListData(this.list) : super._();

  final Uint8List list;

  SliceResult? slice;

  @override
  int get size => list.lengthInBytes;

  @override
  Uint8List toTypedList() => list;

  @override
  SliceResult toSliceResult() => slice ??= SliceResult.fromTypedList(list);

  @override
  TransferableData _createTransferableData() =>
      _TransferableTypedListData(list);
}

class _TransferableTypedListData extends TransferableData {
  _TransferableTypedListData(Uint8List list)
      : data = TransferableTypedData.fromList([list]),
        super._();

  final TransferableTypedData data;

  @override
  Data materialize() => _TypedListData(data.materialize().asUint8List());
}

class _SliceResultData extends Data {
  _SliceResultData(this.slice) : super._();

  final SliceResult slice;

  @override
  int get size => slice.size;

  @override
  Uint8List toTypedList() => slice.toTypedList();

  @override
  SliceResult toSliceResult() => slice;

  @override
  TransferableData _createTransferableData() =>
      _TransferableSliceResultData(slice);
}

class _TransferableSliceResultData extends TransferableData {
  _TransferableSliceResultData(SliceResult slice)
      : data = TransferableSliceResult(slice),
        super._();

  final TransferableSliceResult data;

  @override
  Data materialize() => _SliceResultData(data.materialize());
}

extension DataSliceResultExt on SliceResult {
  Data toData() => Data.fromSliceResult(this);
}

extension DataTypedListExt on Uint8List {
  Data toData() => Data.fromTypedList(this);
}
