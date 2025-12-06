import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const ItemCard({Key? key, required this.item, this.onEdit, this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final image = item['imageUrl'] as String?;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
            backgroundImage: image != null
                ? NetworkImage(image)
                : AssetImage(
                        'assets/images/preset_catalog/shop_placeholder.png')
                    as ImageProvider),
        title: Text(item['name'] ?? ''),
        subtitle: Text(
            '₹${(item['price'] ?? 0).toString()} • ${item['category'] ?? 'General'}'),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(child: Text('Edit'), value: 'edit'),
            PopupMenuItem(child: Text('Delete'), value: 'delete'),
          ],
          onSelected: (v) {
            if (v == 'edit') onEdit?.call();
            if (v == 'delete') onDelete?.call();
          },
        ),
      ),
    );
  }
}
