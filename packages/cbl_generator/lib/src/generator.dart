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
  _TypedDictionaryGeneratorBase(this.type);

  final TypedDataType type;

  @override
  Future<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final model = await TypedDataAnalyzer(buildStep.resolver)
        .buildTypedDataClassModel(element, type: type);
    return TypeDataCodeBuilder(clazz: model).build();
  }
}

class TypedDictionaryGenerator
    extends _TypedDictionaryGeneratorBase<TypedDictionary> {
  TypedDictionaryGenerator() : super(TypedDataType.dictionary);
}

class TypedDocumentGenerator
    extends _TypedDictionaryGeneratorBase<TypedDocument> {
  TypedDocumentGenerator() : super(TypedDataType.document);
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
