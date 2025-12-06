import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const CategoryChip(
      {Key? key, required this.label, this.selected = false, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(right: 8),
        child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap?.call()));
  }
}
