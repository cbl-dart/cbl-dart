extension ValueExt<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
