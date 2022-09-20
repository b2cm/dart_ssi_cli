import 'dart:io';

extension plus on Directory {

  /// adds a Python-like `/` operator to concatenate paths
  Directory operator /(String path) => Directory('${this.path}/$path');

  /// a convenience method to `/` also works for adding multiple part segments
  Directory append(String path) => this / path;
}