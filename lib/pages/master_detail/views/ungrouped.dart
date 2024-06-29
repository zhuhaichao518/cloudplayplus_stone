import 'package:flutter/material.dart';
import '../../../plugins/flutter_master_detail/flutter_master_detail.dart';

import '../data/contacts_list.dart';
import '../types/contact.dart';

class Ungrouped extends StatelessWidget {
  const Ungrouped({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterDetailsList<Contact>(
      items: contactsList,
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
    Contact data,
    bool isSelected,
  ) {
    return ListTile(
      title: Text(data.name),
      subtitle: Text(data.email),
      selected: isSelected,
    );
  }
}
