import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'cblitedart.dart' as cblitedart;
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

final globalFLErrorCode = sliceResultAllocator<Int32>();

final nullFLSlice = sliceResultAllocator<FLSlice>()
  ..ref.buf = nullptr
  ..ref.size = 0;
final globalFLSlice = sliceResultAllocator<FLSlice>();

final nullFLSliceResult = nullFLSlice.cast<FLSliceResult>();
final globalFLSliceResult = sliceResultAllocator<FLSliceResult>();

final nullFLString = nullFLSlice.cast<FLString>();
final globalFLString = sliceResultAllocator<FLString>();

final globalLoadedDictKey =
    sliceResultAllocator<cblitedart.CBLDart_LoadedDictKey>();
final globalLoadedFLValue =
    sliceResultAllocator<cblitedart.CBLDart_LoadedFLValue>();

final globalCBLError = sliceResultAllocator<CBLError>();
final globalErrorPosition = sliceResultAllocator<Int>();
