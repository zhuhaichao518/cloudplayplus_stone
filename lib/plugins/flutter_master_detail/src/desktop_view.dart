import 'dart:math';

import 'package:flutter/material.dart';

import 'detail_view.dart';
import 'element_list.dart';
import 'elements_view_model.dart';
import 'types.dart' as types;
import 'types/details_title_config.dart';

/// A widget that defines the master detail view for the desktop size screens
class DesktopView<T> extends StatelessWidget {
  final ElementsViewModel<T> viewModel;

  /// A widget to display as the master view's title.
  final FlexibleSpaceBar? title;

  /// The list of items.
  final List<T> items;

  /// A widget to display in the details view on larger screens when no element is selected in the master view.
  final Widget? nothingSelectedWidget;

  /// Defines how an individual element in the master view is to be rendered.
  final types.MasterBuilder<T> masterItemBuilder;

  /// Defines how the title section of the details view are rendered.
  final types.DetailsTitleBuilder<T> detailsTitleBuilder;

  /// Defines how the main section of the details view are rendered.
  final types.DetailsBuilder<T> detailsItemBuilder;

  /// Specify if grouping is needed in the master view.
  final types.Data<T>? groupedBy;

  /// Specify if you want to customize the group header. Will be ignored if `groupedBy` is not specified.
  final types.GroupHeader? groupHeaderBuilder;

  /// The maximum percentage of view to be occupied by the master view on larger screens.
  final double masterViewFraction;

  /// Max width of the master view. Only used in larger screens.
  final double masterViewMaxWidth;

  /// Transition animation duration.
  final Duration transitionAnimationDuration;

  /// Additional options to configure title section of the details view.
  final DetailsTitleConfig detailsTitleConfig;
  const DesktopView({
    super.key,
    this.title,
    this.nothingSelectedWidget,
    required this.viewModel,
    required this.items,
    required this.masterItemBuilder,
    required this.detailsTitleBuilder,
    required this.detailsItemBuilder,
    required this.masterViewFraction,
    required this.masterViewMaxWidth,
    required this.transitionAnimationDuration,
    required this.detailsTitleConfig,
    this.groupedBy,
    this.groupHeaderBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildMasterPanel(constraints),
            _buildDetailsPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(BuildContext context) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: transitionAnimationDuration,
        child: DetailView(
          detailsItemBuilder: detailsItemBuilder,
          detailsTitleBuilder: detailsTitleBuilder,
          viewModel: viewModel,
          nothingSelectedWidget: nothingSelectedWidget,
          detailsTitleConfig: detailsTitleConfig,
        ),
        transitionBuilder: (child, animation) =>
            const FadeUpwardsPageTransitionsBuilder()
                .buildTransitions(null, context, animation, null, child),
      ),
    );
  }

  Widget _buildMasterPanel(BoxConstraints constraints) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: min(
          constraints.maxWidth * masterViewFraction,
          masterViewMaxWidth,
        ),
      ),
      child: ElementList(
        items: items,
        title: title,
        groupedBy: groupedBy,
        groupHeaderBuilder: groupHeaderBuilder,
        selectedItem: viewModel.selectedItem,
        masterItemBuilder: masterItemBuilder,
        onTap: (item) => viewModel.selectedItem = item,
      ),
    );
  }
}
