import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'slice.dart';

final globalArena = Arena(cachedSliceResultAllocator);

Pointer<T> zeroedGlobalArena<T extends NativeType>(int byteCount) {
  final result = globalArena.allocate<T>(byteCount);
  result.cast<Uint8>().asTypedList(byteCount).fillRange(0, byteCount, 0);
  return result;
}

T withGlobalArena<T>(T Function() f) {
  try {
    return f();
  } finally {
    globalArena.releaseAll(reuse: true);
  }
}

final globalFLErrorCode = sliceResultAllocator<UnsignedInt>();

final nullFLSlice = sliceResultAllocator<cblite.FLSlice>()
  ..ref.buf = nullptr
  ..ref.size = 0;
final globalFLSlice = sliceResultAllocator<cblite.FLSlice>();

final nullFLSliceResult = nullFLSlice.cast<cblite.FLSliceResult>();
final globalFLSliceResult = sliceResultAllocator<cblite.FLSliceResult>();

final nullFLString = nullFLSlice.cast<cblite.FLString>();
final globalFLString = sliceResultAllocator<cblite.FLString>();

final globalLoadedDictKey =
    sliceResultAllocator<cblitedart.CBLDart_LoadedDictKey>();
final globalLoadedFLValue =
    sliceResultAllocator<cblitedart.CBLDart_LoadedFLValue>();

final globalCBLError = sliceResultAllocator<cblite.CBLError>();
final globalErrorPosition = sliceResultAllocator<Int>();
