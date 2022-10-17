class Enumerator<T> {
  int index;
  T? value;
  Enumerator(this.index, this.value);
}

/// used as a python enumerate function
Iterable<Enumerator<T?>> enumerate<T>(Iterable<T?> iterable) sync* {
  var i = 0;
  for (var element in iterable) {
    yield Enumerator(i++, element);
  }
}
