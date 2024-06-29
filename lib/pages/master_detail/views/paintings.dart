import '../../../plugins/flutter_master_detail/flutter_master_detail.dart';

import '../data/paintings.dart';
import '../types/painting.dart';
import 'package:flutter/material.dart';

class Paintings extends StatelessWidget {
  const Paintings({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterDetailsList<Painting>(
      items: paintings,
      masterItemBuilder: _buildListTile,
      detailsTitleBuilder: (context, data) => FlexibleSpaceBar(
        title: Text(data.title),
        background: Image.asset(
          data.url,
          fit: BoxFit.cover,
        ),
        centerTitle: false,
      ),
      detailsItemBuilder: (context, data) => Center(
        child: Text(data.description),
      ),
      sortBy: (data) => data.artist,
      title: const FlexibleSpaceBar(
        title: Text("Paintings"),
      ),
      masterViewFraction: 0.5,
      detailsTitleConfig: const DetailsTitleConfig(
        expandedHeight: 250,
        floating: true,
        pinned: true,
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    Painting data,
    bool isSelected,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: ExactAssetImage(data.url),
      ),
      title: Text(data.title),
      subtitle: Text(data.artist),
      selected: isSelected,
    );
  }
}
