import 'package:flutter/widgets.dart';

class MasterElement {
  final Widget title;
  final Widget subtitle;
  final Widget selectedIndicator;
  final Widget notSelectedIndicator;

  MasterElement({
    required this.title,
    required this.subtitle,
    required this.selectedIndicator,
    required this.notSelectedIndicator,
  });
}
