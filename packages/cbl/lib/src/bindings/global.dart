import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'fleece.dart';
import 'slice.dart';

final globalArena = Arena(cachedSliceResultAllocator);

T withGlobalArena<T>(T Function() f) {
  try {
    return f();
  } finally {
    globalArena.releaseAll(reuse: true);
  }
}

final globalFLErrorCode = sliceResultAllocator<Uint32>();

final nullFLSlice = sliceResultAllocator<FLSlice>()
  ..ref.buf = nullptr
  ..ref.size = 0;
final globalFLSlice = sliceResultAllocator<FLSlice>();

final nullFLSliceResult = nullFLSlice.cast<FLSliceResult>();
final globalFLSliceResult = sliceResultAllocator<FLSliceResult>();

final nullFLString = nullFLSlice.cast<FLString>();
final globalFLString = sliceResultAllocator<FLString>();

final globalLoadedDictKey = sliceResultAllocator<CBLDart_LoadedDictKey>();
final globalLoadedFLValue = sliceResultAllocator<CBLDart_LoadedFLValue>();

final globalCBLError = sliceResultAllocator<CBLError>();
final globalErrorPosition = sliceResultAllocator<Int>();
