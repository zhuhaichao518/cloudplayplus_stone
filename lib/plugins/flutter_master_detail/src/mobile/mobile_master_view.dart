import 'package:flutter/material.dart';
import '../../src/element_list.dart';

import '../elements_view_model.dart';
import '../types.dart' as types;

class MobileMasterView<T> extends StatelessWidget {
  final ElementsViewModel<T> viewModel;

  /// A widget to display as the master view's title.
  final Widget? title;

  /// The list of items.
  final List<T> items;

  /// Defines how an individual element in the master view is to be rendered.
  final types.MasterBuilder<T> masterItemBuilder;

  /// Specify if grouping is needed in the master view.
  final types.Data<T>? groupedBy;

  /// Specify if you want to customize the group header. Will be ignored if `groupedBy` is not specified.
  final types.GroupHeader? groupHeaderBuilder;
  const MobileMasterView({
    super.key,
    this.title,
    required this.viewModel,
    required this.items,
    required this.masterItemBuilder,
    this.groupedBy,
    this.groupHeaderBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey<T?>(viewModel.selectedItem),
      body: ElementList(
        items: items,
        groupedBy: groupedBy,
        groupHeaderBuilder: groupHeaderBuilder,
        selectedItem: viewModel.selectedItem,
        title: title,
        masterItemBuilder: masterItemBuilder,
        onTap: (value) => viewModel.selectedItem = value,
      ),
    );
  }
}
