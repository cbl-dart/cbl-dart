import '../decoder.dart';
import '../dict_key.dart';

class MContext {
  const MContext({
    this.data,
    DictKeys? dictKeys,
    SharedKeysTable? sharedKeysTable,
    SharedStringsTable? sharedStringsTable,
  })  : dictKeys = dictKeys ?? const UnoptimizingDictKeys(),
        sharedKeysTable = sharedKeysTable ?? const NoopSharedKeysTable(),
        sharedStringsTable =
            sharedStringsTable ?? const NoopSharedStringsTable();

  final Object? data;
  final DictKeys dictKeys;
  final SharedKeysTable sharedKeysTable;
  final SharedStringsTable sharedStringsTable;
}
