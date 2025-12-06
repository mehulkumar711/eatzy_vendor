import 'package:flutter/material.dart';
import '../bloc/vendor_order_bloc.dart';
import '../../../../utils/models.dart';

class IncomingOrderModal extends StatelessWidget {
  final OrderModel order;
  final void Function() onAccept;
  final void Function() onReject;
  final void Function() onReady;
  final void Function() onRepeat;
  final void Function() onManualListen;

  const IncomingOrderModal({
    Key? key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onReady,
    required this.onRepeat,
    required this.onManualListen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = order.items
        .map((i) => '${i.quantity} x ${i.name}')
        .join('\n');

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 18),
            Text(
              'New Order • #${order.id}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              order.isParcel ? 'Parcel' : 'Dine-in',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(items),
            ),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
              ),
              onPressed: onManualListen,
              child: Text('Manual Listen'),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                    child: Text('Reject'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReady,
                    child: Text('Ready'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRepeat,
              icon: Icon(Icons.replay),
              label: Text('Repeat'),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
