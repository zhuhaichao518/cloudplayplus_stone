import 'package:flutter/material.dart';
import '../../src/detail_page.dart';

import '../elements_view_model.dart';
import '../types.dart' as types;
import '../types/details_title_config.dart';

/// A widget that wraps the genric details view for the mobile screen
class MobileDetailView<T> extends StatelessWidget {
  final ElementsViewModel<T> viewModel;

  /// Defines how the main section of the details view are rendered.
  final types.DetailsBuilder<T> detailsItemBuilder;

  /// Defines how the title section of the details view are rendered.
  final types.DetailsTitleBuilder<T> detailsTitleBuilder;

  /// Additional options to configure title section of the details view.
  final DetailsTitleConfig detailsTitleConfig;
  const MobileDetailView({
    super.key,
    required this.viewModel,
    required this.detailsTitleBuilder,
    required this.detailsItemBuilder,
    required this.detailsTitleConfig,
  });

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      viewModel: viewModel,
      detailsTitleBuilder: detailsTitleBuilder,
      detailsItemBuilder: detailsItemBuilder,
      leading: IconButton(
        onPressed: () {
          viewModel.selectedItem = null;
        },
        icon: const Icon(Icons.arrow_back),
      ),
      detailsTitleConfig: detailsTitleConfig,
    );
  }
}
