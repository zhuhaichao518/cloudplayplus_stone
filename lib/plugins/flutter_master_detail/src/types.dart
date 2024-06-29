import 'package:flutter/material.dart';

typedef MasterBuilder<T> = Widget Function(
    BuildContext context, T data, bool isSelected);
typedef DetailsBuilder<T> = Widget Function(BuildContext context, T data);
typedef DetailsTitleBuilder<T> = FlexibleSpaceBar Function(
    BuildContext context, T data);
typedef Data<T> = dynamic Function(T data);
typedef GroupHeader = Widget Function(
  BuildContext context,
  dynamic key,
  int itemsCount,
);
