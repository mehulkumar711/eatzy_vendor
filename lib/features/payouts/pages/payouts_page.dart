import 'package:flutter/material.dart';
import '../../../services/api_client.dart';

class PayoutsPage extends StatefulWidget {
  const PayoutsPage({Key? key}) : super(key: key);

  @override
  State<PayoutsPage> createState() => _PayoutsPageState();
}

class _PayoutsPageState extends State<PayoutsPage> {
  bool loading = true;
  Map<String, dynamic> summary = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => loading = true);
    try {
      final resp = await ApiClient.instance.get('/vendors/me/payouts/summary');
      setState(() {
        summary = resp.data ?? {};
      });
    } catch (e) {
      // handle offline/cached data
    } finally {
      setState(() => loading = false);
    }
  }

  double computePayout(double total, double commissionPercent) {
    return total - (total * commissionPercent / 100);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());
    final total = (summary['total'] ?? 0).toDouble();
    final commission = (summary['commissionPercent'] ?? 20).toDouble();
    final payout = computePayout(total, commission);
    return Scaffold(
      appBar: AppBar(title: Text('Payouts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Total Earnings'),
                trailing: Text('₹${total.toStringAsFixed(2)}'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Commission'),
                trailing: Text('${commission.toStringAsFixed(2)}%'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Estimated Payout'),
                trailing: Text('₹${payout.toStringAsFixed(2)}'),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // request payout API
              },
              child: Text('Request Payout'),
            ),
          ],
        ),
      ),
    );
  }
}
