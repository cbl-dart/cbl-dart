import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'c_type.dart';
import 'fleece.dart';
import 'slice.dart';

late final globalArena = Arena(singleSliceResultAllocator);

T withGlobalArena<T>(T Function() f) {
  try {
    return f();
  } finally {
    globalArena.releaseAll(reuse: true);
  }
}

late final globalFLErrorCode = sliceResultAllocator<Uint32>();

late final nullFLSlice = sliceResultAllocator<FLSlice>()
  ..ref.buf = nullptr
  ..ref.size = 0;
late final globalFLSlice = sliceResultAllocator<FLSlice>();

late final nullFLSliceResult = nullFLSlice.cast<FLSliceResult>();
late final globalFLSliceResult = sliceResultAllocator<FLSliceResult>();

late final nullFLString = nullFLSlice.cast<FLString>();
late final globalFLString = sliceResultAllocator<FLString>();

late final globalLoadedFLValue = sliceResultAllocator<CBLDart_LoadedFLValue>();

late final globalCBLError = sliceResultAllocator<CBLError>();
late final globalErrorPosition = sliceResultAllocator<Int>();
