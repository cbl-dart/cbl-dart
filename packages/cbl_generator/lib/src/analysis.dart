import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

bool classHasRedirectingUnnamedConstructor(
  AstNode clazz,
  String targetConstructor,
) {
  final visitor =
      _ClassHasRedirectingUnnamedConstructorVisitor(targetConstructor);
  clazz.accept(visitor);
  return visitor.hasRedirectingConstructor;
}

class _ClassHasRedirectingUnnamedConstructorVisitor
    extends RecursiveAstVisitor<void> {
  _ClassHasRedirectingUnnamedConstructorVisitor(this.targetConstructor);

  final String targetConstructor;

  bool hasRedirectingConstructor = false;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (hasRedirectingConstructor) {
      return;
    }
    hasRedirectingConstructor = node.factoryKeyword != null &&
        // ignore: deprecated_member_use
        node.redirectedConstructor?.type.name2.lexeme == targetConstructor;
  }
}

bool classHasMixin(AstNode clazz, String mixinName) {
  final visitor = _ClassHasMixinVisitor(mixinName);
  clazz.accept(visitor);
  return visitor.hasMixin;
}

class _ClassHasMixinVisitor extends RecursiveAstVisitor<void> {
  _ClassHasMixinVisitor(this.mixinName);

  final String mixinName;

  bool hasMixin = false;

  @override
  void visitWithClause(WithClause node) {
    // ignore: deprecated_member_use
    hasMixin = node.mixinTypes.any((mixin) => mixin.name2.lexeme == mixinName);
  }
}

bool isExactlyOneOfTypes(DartType type, Iterable<TypeChecker> typeCheckers) =>
    typeCheckers.any((typeChecker) => typeChecker.isExactlyType(type));

extension ParameterElementExt on ParameterElement {
  Future<String?> documentationCommentValue(Resolver resolver) async =>
      (await resolver.astNodeFor(this))!.beginToken.precedingComments?.value();
}

extension ConstantReaderExt on ConstantReader {
  String get code {
    if (isNull) {
      return 'null';
    } else if (isBool) {
      return boolValue.toString();
    } else if (isString) {
      return escapeDartString(stringValue);
    } else if (isInt) {
      return intValue.toString();
    } else if (isDouble) {
      return doubleValue.toString();
    } else if (isSymbol) {
      return symbolValue.toString();
    } else if (isType) {
      return typeValue.getDisplayString(withNullability: true);
    } else if (isList) {
      final elements = listValue.map((it) => '${it.code},').join();
      return 'const [$elements]';
    } else if (isSet) {
      final elements = setValue.map((it) => '${it.code},').join();
      return 'const {$elements}';
    } else if (isMap) {
      final entries = mapValue.entries
          .map((it) => '${it.key!.code}: ${it.value!.code},')
          .join();
      return 'const {$entries}';
    } else {
      final revivable = revive();
      if (revivable.source.fragment.isEmpty) {
        return revivable.accessor;
      }
      final code = StringBuffer(' const ${revivable.source.fragment}');
      if (revivable.accessor.isNotEmpty) {
        code
          ..write('.')
          ..write(revivable.accessor);
      }
      code.write('(');
      for (final parameter in revivable.positionalArguments) {
        code.write('${parameter.code}, ');
      }
      for (final parameter in revivable.namedArguments.entries) {
        code.write('${parameter.key}: ${parameter.value.code}, ');
      }
      code.write(')');
      return code.toString();
    }
  }
}

extension DartObjectExt on DartObject {
  String get code => ConstantReader(this).code;
}
