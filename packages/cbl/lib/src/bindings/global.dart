import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'slice.dart';

final globalArena = Arena(cachedSliceResultAllocator);

T withGlobalArena<T>(T Function() f) {
  try {
    return f();
  } finally {
    globalArena.releaseAll(reuse: true);
  }
}

final globalFLErrorCode = sliceResultAllocator<UnsignedInt>();

final nullFLSlice = sliceResultAllocator<cblite_lib.FLSlice>()
  ..ref.buf = nullptr
  ..ref.size = 0;
final globalFLSlice = sliceResultAllocator<cblite_lib.FLSlice>();

final nullFLSliceResult = nullFLSlice.cast<cblite_lib.FLSliceResult>();
final globalFLSliceResult = sliceResultAllocator<cblite_lib.FLSliceResult>();

final nullFLString = nullFLSlice.cast<cblite_lib.FLString>();
final globalFLString = sliceResultAllocator<cblite_lib.FLString>();

final globalLoadedDictKey =
    sliceResultAllocator<cblitedart_lib.CBLDart_LoadedDictKey>();
final globalLoadedFLValue =
    sliceResultAllocator<cblitedart_lib.CBLDart_LoadedFLValue>();

final globalCBLError = sliceResultAllocator<cblite_lib.CBLError>();
final globalErrorPosition = sliceResultAllocator<Int>();
