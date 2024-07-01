
import 'package:flutter/material.dart';
import '../../../plugins/flutter_master_detail/flutter_master_detail.dart';
import 'master_detail/data/fantasy_list.dart';
import 'master_detail/types/fantasy.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterDetailsList<Fantasy>(
      items: fantasyList,
      groupedBy: (data) => data.race,
      masterItemBuilder: _buildListTile,
      detailsTitleBuilder: (context, data) => FlexibleSpaceBar(
        title: Text(data.name),
        centerTitle: false,
      ),
      detailsItemBuilder: (context, data) => Center(
        child: Text(data.name),
      ),
      sortBy: (data) => data.name,
      title: const FlexibleSpaceBar(
        title: Text("Contacts"),
      ),
      masterViewFraction: 0.5,
    );
  }

  Widget _buildListTile(
    BuildContext context,
    Fantasy data,
    bool isSelected,
  ) {
    return ListTile(
      title: Text(data.name),
      subtitle: Text(data.race),
      trailing: Icon(data.gender == Gender.male
          ? Icons.male_rounded
          : Icons.female_rounded),
      selected: isSelected,
    );
  }
}
