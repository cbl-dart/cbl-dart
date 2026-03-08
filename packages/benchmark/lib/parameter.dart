import 'dart:io';

abstract class BenchmarkParameter<T> {
  BenchmarkParameter({required this.name});

  final String name;

  T get current => decode(Platform.environment[name] ?? '');

  String encode(T value);

  T decode(String value);

  MapEntry<String, String> envEntry(T value) => MapEntry(name, encode(value));
}

class StringParameter extends BenchmarkParameter<String> {
  StringParameter({required super.name});

  @override
  String decode(String value) => value;

  @override
  String encode(String value) => value;
}

class IntParameter extends BenchmarkParameter<int> {
  IntParameter({required super.name});

  @override
  int decode(String value) {
    if (value.isEmpty) {
      throw FormatException('Environment variable $name is not set or empty.');
    }
    return int.parse(value);
  }

  @override
  String encode(int value) => value.toString();
}

class EnumParameter<T extends Enum> extends BenchmarkParameter<T> {
  EnumParameter({required super.name, required this.values});

  final List<T> values;

  @override
  T decode(String value) => values.byName(value);

  @override
  String encode(T value) => value.name;
}

enum ExecutionMode { jit, aot }

enum ApiType { sync, async }

final executionModeParameter = EnumParameter(
  name: 'EXECUTION_MODE',
  values: ExecutionMode.values,
);

final apiTypeParameter = EnumParameter(
  name: 'API_TYPE',
  values: ApiType.values,
);

final operationCountParameter = IntParameter(name: 'OPERATION_COUNT');

final batchSizeParameter = IntParameter(name: 'BATCH_SIZE');

final fixtureParameter = StringParameter(name: 'FIXTURE');
