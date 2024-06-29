import 'package:flutter/material.dart';
import 'desktop_view.dart';
import 'elements_view_model.dart';
import 'mobile_view.dart';
import 'tablet_view.dart';
import 'types/details_title_config.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import 'types.dart' as types;

/// A widget that builds an adaptive master detail view.
class MasterDetailsList<T> extends StatelessWidget {
  /// A widget to display as the master view's title.
  final FlexibleSpaceBar? title;

  /// The list of items.
  final List<T> items;

  /// Defines how an individual element in the master view is to be rendered.
  final types.MasterBuilder<T> masterItemBuilder;

  /// A widget to display in the details view on larger screens when no element is selected in the master view.
  final Widget? nothingSelectedWidget;

  /// Defines how the title section of the details view are rendered.
  final types.DetailsTitleBuilder<T> detailsTitleBuilder;

  /// Defines how the main section of the details view are rendered.
  final types.DetailsBuilder<T> detailsItemBuilder;

  /// Determines how to sort the items in the master view.
  /// Items will be presented in the order given if not provided.
  final types.Data<T>? sortBy;

  /// Specify if grouping is needed in the master view.
  final types.Data<T>? groupedBy;

  /// Specify if you want to customize the group header. Will be ignored if `groupedBy` is not specified.
  final types.GroupHeader? groupHeaderBuilder;

  /// The maximum percentage of view to be occupied by the master view on larger screens.
  final double masterViewFraction;

  /// Transition animation duration.
  final Duration transitionAnimationDuration;

  /// Additional optionss to configure title section of the details view.
  final DetailsTitleConfig detailsTitleConfig;
  final ElementsViewModel<T> viewModel = ElementsViewModel<T>();

  /// Max width of the master view. Only used in larger screens.
  final double _masterViewMaxWidth = 300;
  MasterDetailsList({
    super.key,
    this.title,
    this.nothingSelectedWidget,
    required this.items,
    required this.masterItemBuilder,
    required this.detailsTitleBuilder,
    required this.detailsItemBuilder,
    this.sortBy,
    this.groupedBy,
    this.groupHeaderBuilder,
    this.masterViewFraction = 0.333333,
    this.transitionAnimationDuration = const Duration(milliseconds: 500),
    this.detailsTitleConfig = const DetailsTitleConfig(),
  }) {
    _sort([
      groupedBy,
      sortBy,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ElementsViewModel<T>>.reactive(
      viewModelBuilder: () => viewModel,
      onViewModelReady: (viewModel) {
        // Do something once your viewModel is initialized
      },
      builder: (context, viewModel, child) {
        return ScreenTypeLayout.builder(
          mobile: (ctx) => _buildMobileView(viewModel),
          desktop: (ctx) => _buildDesktopView(viewModel),
          tablet: (ctx) => _buildTabletView(viewModel),
        );
      },
    );
  }

  DesktopView<T> _buildDesktopView(ElementsViewModel<T> viewModel) {
    return DesktopView<T>(
      items: items,
      nothingSelectedWidget: nothingSelectedWidget,
      viewModel: viewModel,
      masterItemBuilder: masterItemBuilder,
      detailsTitleBuilder: detailsTitleBuilder,
      detailsItemBuilder: detailsItemBuilder,
      groupedBy: groupedBy,
      groupHeaderBuilder: groupHeaderBuilder,
      title: title,
      masterViewFraction: masterViewFraction,
      masterViewMaxWidth: _masterViewMaxWidth,
      transitionAnimationDuration: transitionAnimationDuration,
      detailsTitleConfig: detailsTitleConfig,
    );
  }

  TabletView<T> _buildTabletView(ElementsViewModel<T> viewModel) {
    return TabletView<T>(
      items: items,
      nothingSelectedWidget: nothingSelectedWidget,
      viewModel: viewModel,
      masterItemBuilder: masterItemBuilder,
      detailsTitleBuilder: detailsTitleBuilder,
      detailsItemBuilder: detailsItemBuilder,
      groupedBy: groupedBy,
      groupHeaderBuilder: groupHeaderBuilder,
      title: title,
      masterViewFraction: masterViewFraction,
      masterViewMaxWidth: _masterViewMaxWidth,
      transitionAnimationDuration: transitionAnimationDuration,
      detailsTitleConfig: detailsTitleConfig,
    );
  }

  MobileView<T> _buildMobileView(ElementsViewModel<T> viewModel) {
    return MobileView<T>(
      items: items,
      nothingSelectedWidget: nothingSelectedWidget,
      viewModel: viewModel,
      masterItemBuilder: masterItemBuilder,
      detailsTitleBuilder: detailsTitleBuilder,
      detailsItemBuilder: detailsItemBuilder,
      groupedBy: groupedBy,
      groupHeaderBuilder: groupHeaderBuilder,
      transitionAnimationDuration: transitionAnimationDuration,
      title: title,
      detailsTitleConfig: detailsTitleConfig,
    );
  }

  void _sort(List<types.Data<T>?> sorters) {
    for (var i = 0; i < sorters.length; i++) {
      final sorter = sorters.elementAt(i);
      final prevSorter =
          i == 0 ? sorters.elementAt(i) : sorters.elementAt(i - 1);
      if (sorter != null) {
        items.sort((a, b) {
          if (prevSorter != null) {
            final aVal = prevSorter(a);
            final bVal = prevSorter(b);
            final res = aVal.compareTo(bVal);
            if (res != 0) {
              return res;
            }
          }

          return sorter(a).compareTo(sorter(b));
        });
      }
    }
  }
}
