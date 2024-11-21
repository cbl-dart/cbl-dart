final class ToolException implements Exception {
  ToolException(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;
}
