import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import '../src/types/details_title_config.dart';
import './mobile/mobile_detail_view.dart';
import './mobile/mobile_master_view.dart';

import 'elements_view_model.dart';
import 'types.dart' as types;

/// A widget that defines the master detail view for mobile screens
class MobileView<T> extends StatelessWidget {
  final ElementsViewModel<T> viewModel;

  /// A widget to display as the master view's title.
  final FlexibleSpaceBar? title;

  /// A widget to display in the details view on larger screens when no element is selected in the master view.
  final Widget? nothingSelectedWidget;

  /// The list of items.
  final List<T> items;

  /// Defines how an individual element in the master view is to be rendered.
  final types.MasterBuilder<T> masterItemBuilder;

  /// Defines how the main section of the details view are rendered.
  final types.DetailsBuilder<T> detailsItemBuilder;

  /// Defines how the title section of the details view are rendered.
  final types.DetailsTitleBuilder<T> detailsTitleBuilder;

  /// Specify if grouping is needed in the master view.
  final types.Data<T>? groupedBy;

  /// Specify if you want to customize the group header. Will be ignored if `groupedBy` is not specified.
  final types.GroupHeader? groupHeaderBuilder;

  /// Transition animation duration.
  final Duration transitionAnimationDuration;
  static const pageTransitionBuilder = ZoomPageTransitionsBuilder();
  final DetailsTitleConfig detailsTitleConfig;
  const MobileView({
    super.key,
    this.title,
    this.nothingSelectedWidget,
    required this.viewModel,
    required this.items,
    required this.masterItemBuilder,
    required this.detailsTitleBuilder,
    required this.detailsItemBuilder,
    this.groupedBy,
    this.groupHeaderBuilder,
    required this.transitionAnimationDuration,
    required this.detailsTitleConfig,
  });

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: transitionAnimationDuration,
      reverse: viewModel.selectedItem == null,
      transitionBuilder: _transitionBuilder,
      child: _showDetailView() ? _buildDetailsView() : _buildMasterView(),
    );
  }

  MobileMasterView<T> _buildMasterView() {
    return MobileMasterView<T>(
      viewModel: viewModel,
      items: items,
      masterItemBuilder: masterItemBuilder,
      groupedBy: groupedBy,
      groupHeaderBuilder: groupHeaderBuilder,
      title: title,
    );
  }

  MobileDetailView<T> _buildDetailsView() {
    return MobileDetailView<T>(
      viewModel: viewModel,
      detailsTitleBuilder: detailsTitleBuilder,
      detailsItemBuilder: detailsItemBuilder,
      detailsTitleConfig: detailsTitleConfig,
    );
  }

  bool _showDetailView() => viewModel.selectedItem != null;

  Widget _transitionBuilder(
    Widget child,
    Animation<double> primaryAnimation,
    Animation<double> secondaryAnimation,
  ) {
    return /*pageTransitionBuilder.buildTransitions(
      null,
      null,
      primaryAnimation,
      secondaryAnimation,
      child,
    );*/ Container();
  }
}
