import 'package:flutter/material.dart';
import '../src/detail_view.dart';

import 'elements_view_model.dart';
import 'types.dart' as types;
import 'types/details_title_config.dart';

/// A widget that wraps the genric details view for the mobile screen
class DetailPage<T> extends StatelessWidget {
  final ElementsViewModel<T> viewModel;

  /// A widget to display in the details view on larger screens when no element is selected in the master view.
  final Widget? nothingSelectedWidget;

  /// Defines how the main section of the details view are rendered.
  final types.DetailsBuilder<T> detailsItemBuilder;

  /// Defines how the title section of the details view are rendered.
  final types.DetailsTitleBuilder<T> detailsTitleBuilder;
  final Widget? leading;

  /// Additional options to configure title section of the details view.
  final DetailsTitleConfig detailsTitleConfig;
  const DetailPage({
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
    return Scaffold(
      body: DetailView(
        viewModel: viewModel,
        leading: leading,
        nothingSelectedWidget: nothingSelectedWidget,
        detailsTitleBuilder: detailsTitleBuilder,
        detailsItemBuilder: detailsItemBuilder,
        detailsTitleConfig: detailsTitleConfig,
      ),
    );
  }
}
