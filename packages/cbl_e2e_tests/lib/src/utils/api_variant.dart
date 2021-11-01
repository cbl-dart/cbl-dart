import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/support/utils.dart';
import 'package:meta/meta.dart';

import '../test_binding.dart';
import 'test_variant.dart';

enum Api { sync, async }

final api = EnumVariant(Api.values);

enum Isolate {
  main,
  worker,
}

final isolate = EnumVariant(
  Isolate.values,
  isCompatible: (value, other, otherValue) {
    if (other is TestVariant<Api>) {
      if (otherValue == Api.sync) {
        return value == Isolate.main;
      }

      return true;
    }
    return true;
  },
);

@isTest
void apiTest(
  String description,
  FutureOr<void> Function() body, {
  List<TestVariant>? variants,
}) {
  variantTest(
    description,
    body,
    variants: [
      api,
      isolate,
      if (variants != null) ...variants,
    ],
  );
}

Future<void> Function() runWithApiValues(
  FutureOr<void> Function() fn, {
  List<TestVariant>? variants,
}) =>
    () => runVariantCombinations(fn, variants: [api, isolate]);

FutureOr<T> apiFutureOr<T>(T value) {
  switch (api.value) {
    case Api.sync:
      return value;
    case Api.async:
      return Future.value(value);
  }
}

T Function() apiProvider<T>(T Function(Api api) create) {
  late final syncValue = create(Api.sync);
  late final asyncValue = create(Api.async);
  return () {
    switch (api.value) {
      case Api.sync:
        return syncValue;
      case Api.async:
        return asyncValue;
    }
  };
}

FutureOr<T> runWithApi<T>({
  required FutureOr<T> Function() sync,
  required FutureOr<T> Function() async,
}) {
  switch (api.value) {
    case Api.sync:
      return sync();
    case Api.async:
      return async();
  }
}

FutureOr<T> runWithIsolate<T>({
  required FutureOr<T> Function() main,
  required FutureOr<T> Function() worker,
}) {
  switch (isolate.value) {
    case Isolate.main:
      return main();
    case Isolate.worker:
      return worker();
  }
}

FutureOr<T> createApiResource<T extends ClosableResource>({
  required T Function() sync,
  required Future<T> Function() async,
  bool tearDown = true,
}) =>
    runWithApi(sync: sync, async: async).then((value) {
      if (tearDown) {
        addTearDown(value.close);
      }
      return value;
    });
