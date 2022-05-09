import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:cbl/cbl.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer.dart';
import 'model.dart';
import 'typed_data_code_builder.dart';
import 'typed_database_code_builder.dart';

class _TypedDictionaryGeneratorBase<T> extends GeneratorForAnnotation<T> {
  _TypedDictionaryGeneratorBase(this.kind);

  final TypedDataObjectKind kind;

  @override
  Future<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final model = await TypedDataAnalyzer(buildStep.resolver)
        .buildTypedDataClassModel(element, kind: kind);
    return TypeDataCodeBuilder(object: model).build();
  }
}

class TypedDictionaryGenerator
    extends _TypedDictionaryGeneratorBase<TypedDictionary> {
  TypedDictionaryGenerator() : super(TypedDataObjectKind.dictionary);
}

class TypedDocumentGenerator
    extends _TypedDictionaryGeneratorBase<TypedDocument> {
  TypedDocumentGenerator() : super(TypedDataObjectKind.document);
}

class TypedDatabaseGenerator extends Generator {
  TypeChecker get typeChecker => const TypeChecker.fromRuntime(TypedDatabase);

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final outputs = <String>{};
    final imports = <Uri>{
      Uri.parse('package:cbl/cbl.dart'),
      Uri.parse('package:cbl/src/typed_data_internal.dart'),
    };

    for (final annotatedElement in library.annotatedWith(typeChecker)) {
      final output = await generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
        imports,
      );
      outputs.add(output);
    }

    if (outputs.isNotEmpty) {
      final importStatements = imports
          .map((import) => "import '${library.pathToUrl(import)}';")
          .join('\n');

      return [
        importStatements,
        ...outputs,
      ].join('\n\n');
    }

    return null;
  }

  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
    Set<Uri> imports,
  ) async {
    final model = await TypedDataAnalyzer(buildStep.resolver)
        .buildTypedDatabaseModel(element);

    imports
      ..add(model.libraryUri)
      ..addAll(model.types.map((type) => type.libraryUri));

    return TypeDataBaseCodeBuilder(model).build();
  }
}
