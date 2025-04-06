// ignore_for_file: do_not_use_environment

abstract class BenchmarkParameter<T> {
  BenchmarkParameter({
    required this.name,
    required this.dartDefineValue,
  });

  final String name;

  final String dartDefineValue;

  T get current => decode(dartDefineValue);

  String encode(T value);

  T decode(String value);

  DartDefine dartDefine(T value) => DartDefine(name, encode(value));
}

class DartDefine {
  DartDefine(this.name, this.value);

  static List<String> commandLineOptions(Iterable<DartDefine> dartDefines) =>
      dartDefines
          .map((define) => '--define=${define.name}=${define.value}')
          .toList();

  final String name;
  final String value;
}

class StringParameter extends BenchmarkParameter<String> {
  StringParameter({
    required super.name,
    required super.dartDefineValue,
  });

  @override
  String decode(String value) => value;

  @override
  String encode(String value) => value;
}

class IntParameter extends BenchmarkParameter<int> {
  IntParameter({
    required super.name,
    required super.dartDefineValue,
  });

  @override
  int decode(String value) => int.parse(value);

  @override
  String encode(int value) => value.toString();
}

class EnumParameter<T extends Enum> extends BenchmarkParameter<T> {
  EnumParameter({
    required super.name,
    required super.dartDefineValue,
    required this.values,
  });

  final List<T> values;

  @override
  T decode(String value) => values.byName(value);

  @override
  String encode(T value) => value.name;
}

enum ExecutionMode {
  jit,
  aot,
}

enum ApiType {
  sync,
  async,
}

final executionModeParameter = EnumParameter(
  name: 'EXECUTION_MODE',
  dartDefineValue: const String.fromEnvironment('EXECUTION_MODE'),
  values: ExecutionMode.values,
);

final apiTypeParameter = EnumParameter(
  name: 'API_TYPE',
  dartDefineValue: const String.fromEnvironment('API_TYPE'),
  values: ApiType.values,
);

final operationCountParameter = IntParameter(
  name: 'OPERATION_COUNT',
  dartDefineValue: const String.fromEnvironment('OPERATION_COUNT'),
);

final batchSizeParameter = IntParameter(
  name: 'BATCH_SIZE',
  dartDefineValue: const String.fromEnvironment('BATCH_SIZE'),
);

final fixtureParameter = StringParameter(
  name: 'FIXTURE',
  dartDefineValue: const String.fromEnvironment('FIXTURE'),
);
