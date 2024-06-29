import 'package:flutter/material.dart';

import 'elements_view_model.dart';
import 'types.dart' as types;
import 'types/details_title_config.dart';

/// Generic detail view widget used by both large (tablet and desktop), and mobile screens
class DetailView<T> extends StatelessWidget {
  final ElementsViewModel<T> viewModel;

  /// A widget to display in the details view on larger screens when no element is selected in the master view.
  final Widget? nothingSelectedWidget;

  /// Defines how the title section of the details view are rendered.
  final types.DetailsTitleBuilder<T> detailsTitleBuilder;

  /// Defines how the main section of the details view are rendered.
  final types.DetailsBuilder<T> detailsItemBuilder;

  /// Additional options to configure title section of the details view.
  final DetailsTitleConfig detailsTitleConfig;
  final Widget? leading;
  const DetailView({
    super.key,
    this.leading,
    this.nothingSelectedWidget,
    required this.viewModel,
    required this.detailsTitleBuilder,
    required this.detailsItemBuilder,
    required this.detailsTitleConfig,
  });

  @override
  Widget build(BuildContext context) {
    return viewModel.selectedItem == null
        ? _buildNothingSelectedView()
        : _buildScrollView(context);
  }

  CustomScrollView _buildScrollView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: leading,
          flexibleSpace: detailsTitleBuilder(
            context,
            viewModel.selectedItem as T,
          ),
          titleSpacing: detailsTitleConfig.titleSpacing,
          collapsedHeight: detailsTitleConfig.collapsedHeight,
          expandedHeight: detailsTitleConfig.expandedHeight,
          floating: detailsTitleConfig.floating,
          pinned: detailsTitleConfig.pinned,
          snap: detailsTitleConfig.snap,
          stretch: detailsTitleConfig.stretch,
        ),
        SliverList(
            delegate: SliverChildBuilderDelegate(
          _buildDetailElement,
          childCount: 1,
        ))
      ],
    );
  }

  Widget _buildDetailElement(BuildContext context, int index) {
    return detailsItemBuilder(
      context,
      viewModel.selectedItem as T,
    );
  }

  Widget _buildNothingSelectedView() {
    return nothingSelectedWidget ??
        const Text("Select something from the list");
  }
}
