import 'base_view_model.dart';

class ElementsViewModel<T> extends BaseViewModel {
  T? _selectedItem;
  T? get selectedItem => _selectedItem;
  set selectedItem(T? item) {
    _selectedItem = item;
    notifyListeners();
  }
}
