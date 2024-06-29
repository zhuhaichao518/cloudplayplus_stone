import 'package:flutter/material.dart';

class BaseViewModel extends ChangeNotifier {
  final String? _title;
  bool _busy;
  bool _isDisposed = false;

  BaseViewModel({
    bool busy = false,
    String? title,
  })  : _busy = busy,
        _title = title;

  bool get busy => _busy;
  bool get isDisposed => _isDisposed;
  String get title => _title ?? runtimeType.toString();

  set busy(bool busy) {
    _busy = busy;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
