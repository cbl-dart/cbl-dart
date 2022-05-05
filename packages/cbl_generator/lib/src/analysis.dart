import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

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
        node.redirectedConstructor?.type.name.name == targetConstructor;
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
    hasMixin = node.mixinTypes.any((mixin) => mixin.name.name == mixinName);
  }
}

bool isExactlyOneOfTypes(DartType type, Iterable<TypeChecker> typeCheckers) =>
    typeCheckers.any((typeChecker) => typeChecker.isExactlyType(type));

extension ParameterElementExt on ParameterElement {
  String? get documentationCommentValue =>
      (session!.getParsedLibraryByElement(library!) as ParsedLibraryResult)
          .getElementDeclaration(this)!
          .node
          .beginToken
          .precedingComments
          ?.value();
}
