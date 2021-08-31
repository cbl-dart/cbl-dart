import 'dart:ffi';

import 'base.dart';
import 'fleece.dart';
import 'slice.dart';

late final globalFLErrorCode = sliceResult<Uint32>();

late final nullFLSlice = sliceResult<FLSlice>()
  ..ref.buf = nullptr
  ..ref.size = 0;
late final globalFLSlice = sliceResult<FLSlice>();

late final nullFLSliceResult = nullFLSlice.cast<FLSliceResult>();
late final globalFLSliceResult = globalFLSlice.cast<FLSliceResult>();

late final nullFLString = nullFLSlice.cast<FLString>();
late final globalFLString = globalFLSlice.cast<FLString>();

late final globalLoadedFLValue = sliceResult<CBLDart_LoadedFLValue>();

late final globalCBLError = sliceResult<CBLError>();
late final globalErrorPosition = sliceResult<Int32>();
