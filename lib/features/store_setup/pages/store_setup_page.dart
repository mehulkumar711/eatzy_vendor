import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_client.dart';
import '../../vendor_dashboard/pages/orders_page.dart';

class StoreSetupPage extends StatefulWidget {
  const StoreSetupPage({super.key});

  @override
  State<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends State<StoreSetupPage> {
  final _formKey = GlobalKey<FormState>();
  String? storeName, ownerName, upiId, description;
  File? logoFile;
  bool isSubmitting = false;

  Future<void> _pickLogo() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => logoFile = File(img.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => isSubmitting = true);

    final payload = {
      "storeName": storeName,
      "ownerName": ownerName,
      "upiId": upiId,
      "description": description,
      "location": {"lat": 0.0, "lng": 0.0, "address": ""},
    };

    try {
      final resp = await ApiClient.instance.post('/vendors', data: payload);
      debugPrint('Store created: ${resp.data['id']}');
      // store vendorId etc in Hive if needed
      if (mounted) {
        setState(() => isSubmitting = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrdersPage()),
        );
      }
    } catch (e) {
      debugPrint('Error creating store: $e');
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Store Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: logoFile == null
                      ? AssetImage(
                          'assets/images/preset_catalog/shop_placeholder.png',
                        ) as ImageProvider
                      : FileImage(logoFile!),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Store name'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                onSaved: (v) => storeName = v,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Owner name'),
                onSaved: (v) => ownerName = v,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'UPI ID (optional)'),
                onSaved: (v) => upiId = v,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Short description'),
                onSaved: (v) => description = v,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? CircularProgressIndicator()
                    : Text('Create Store'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
