import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'types.dart' as types;

/// Generic widget to build list of elements for the master view
class ElementList<T> extends StatelessWidget {
  /// The list of items.
  final List<T> items;

  /// A widget to display as the master view's title.
  final Widget? title;

  /// Holods the currently selected item in the master view, if one is selected.
  final T? selectedItem;

  /// Specify if grouping is needed in the master view.
  final types.Data<T>? groupedBy;

  /// Specify if you want to customize the group header. Will be ignored if `groupedBy` is not specified.
  final types.GroupHeader? groupHeaderBuilder;

  /// Defines how an individual element in the master view is to be rendered.
  final types.MasterBuilder<T> masterItemBuilder;

  /// Handles tap events for the items.
  final ValueSetter<T> onTap;
  const ElementList({
    super.key,
    this.title,
    required this.selectedItem,
    required this.items,
    required this.masterItemBuilder,
    required this.onTap,
    required this.groupedBy,
    required this.groupHeaderBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedBy != null) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            flexibleSpace: title,
          ),
          ..._buildGroupedListView(context)
        ],
      );
    }
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          flexibleSpace: title,
        ),
        _buildNonGroupedListView(items)
      ],
    );
  }

  List<SliverStickyHeader> _buildGroupedListView(BuildContext context) {
    var grouped = groupBy(items, groupedBy!);
    return grouped.entries
        .map((e) => _buildGroupedElement(context, e.key, e.value))
        .toList();
  }

  SliverStickyHeader _buildGroupedElement(
      BuildContext context, dynamic key, List<T> value) {
    final headerBuilder = groupHeaderBuilder ?? _buildHeaderWidget;
    return SliverStickyHeader(
      header: headerBuilder(context, key, value.length),
      sliver: _buildNonGroupedListView(value),
    );
  }

  Widget _buildHeaderWidget(BuildContext context, dynamic key, int itemsCount) {
    return Material(
      color: Theme.of(context).colorScheme.secondary,
      child: ListTile(
        title: Text(key.toString()),
        trailing: Text(itemsCount.toString()),
      ),
    );
  }

  SliverList _buildNonGroupedListView(List<T> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, index) => _buildElement(ctx, items[index]),
        childCount: items.length,
      ),
    );
  }

  Widget _buildElement(BuildContext context, T item) {
    return GestureDetector(
      onTap: () => onTap(item),
      child: masterItemBuilder(
        context,
        item,
        item == selectedItem,
      ),
    );
  }
}
