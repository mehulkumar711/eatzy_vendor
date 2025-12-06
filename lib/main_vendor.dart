import 'package:flutter/material.dart';
import 'bootstrap_vendor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapVendor();
}
