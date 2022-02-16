import '../decoder.dart';
import '../dict_key.dart';

class MContext {
  MContext({
    DictKeys? dictKeys,
    SharedKeysTable? sharedKeysTable,
    SharedStringsTable? sharedStringsTable,
  })  : dictKeys = dictKeys ?? const UnoptimizingDictKeys(),
        sharedKeysTable = sharedKeysTable ?? const NoopSharedKeysTable(),
        sharedStringsTable =
            sharedStringsTable ?? const NoopSharedStringsTable();

  final DictKeys dictKeys;
  final SharedKeysTable sharedKeysTable;
  final SharedStringsTable sharedStringsTable;
}

class NoopMContext implements MContext {
  const NoopMContext();

  @override
  DictKeys get dictKeys => const UnoptimizingDictKeys();

  @override
  SharedKeysTable get sharedKeysTable => const NoopSharedKeysTable();

  @override
  SharedStringsTable get sharedStringsTable => const NoopSharedStringsTable();
}
