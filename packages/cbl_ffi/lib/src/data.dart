import 'dart:typed_data';

import 'slice.dart';

abstract class Data {
  Data._();

  factory Data.fromTypedList(Uint8List list) => _TypedListData(list);

  factory Data.fromSliceResult(SliceResult slice) => _SliceResultData(slice);

  Uint8List toTypedList();

  SliceResult toSliceResult();
}

class _TypedListData extends Data {
  _TypedListData(this.list) : super._();

  final Uint8List list;

  SliceResult? slice;

  @override
  Uint8List toTypedList() => list;

  @override
  SliceResult toSliceResult() => slice ??= SliceResult.fromTypedList(list);
}

class _SliceResultData extends Data {
  _SliceResultData(this.slice) : super._();

  final SliceResult slice;

  @override
  Uint8List toTypedList() => slice.asTypedList();

  @override
  SliceResult toSliceResult() => slice;
}

extension DataSliceResultExt on SliceResult {
  Data toData() => Data.fromSliceResult(this);
}

extension DataTypedListExt on Uint8List {
  Data toData() => Data.fromTypedList(this);
}
