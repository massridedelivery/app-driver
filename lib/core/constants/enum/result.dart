sealed class Result {
  const Result();
}

extension ResultExtension on Result {
  void when<T>({
    T Function(String? message)? success,
    T Function(String? message)? error,
  }) {
    switch (this) {
      case Success(:final message):
        success?.call(message);
      case Error(:final message):
        error?.call(message);
    }
  }
}

class Success extends Result {
  final String? message;
  const Success({this.message});
}

class Error extends Result {
  final String? message;
  const Error({this.message});
}
