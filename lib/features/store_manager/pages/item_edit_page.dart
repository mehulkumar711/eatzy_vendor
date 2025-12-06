import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/store_bloc.dart';
import '../bloc/store_event.dart';
// import '../../../core/localization.dart';

class ItemEditPage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const ItemEditPage({Key? key, this.initial}) : super(key: key);

  @override
  State<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends State<ItemEditPage> {
  final _form = GlobalKey<FormState>();
  String? name;
  double? price;
  bool veg = true;
  int stock = 10;
  String category = 'General';
  File? imageFile;
  bool isSaving = false;
  double uploadProgress = 0.0;
  late StoreBloc _bloc;
  bool _blocInitialized = false;

  @override
  void initState() {
    super.initState();
    _initBloc();
    if (widget.initial != null) {
      name = widget.initial!['name'];
      price = (widget.initial!['price'] ?? 0).toDouble();
      veg = widget.initial!['veg'] ?? true;
      stock = widget.initial!['stock'] ?? 10;
      category = widget.initial!['category'] ?? 'General';
    }
  }

  Future<void> _initBloc() async {
    _bloc = await StoreBloc.create();
    if (mounted) setState(() => _blocInitialized = true);
  }

  Future<void> _pickImage() async {
    final p = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (p != null) setState(() => imageFile = File(p.path));
  }

  @override
  Widget build(BuildContext context) {
    if (!_blocInitialized)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    return BlocProvider.value(
      value: _bloc,
      child: Builder(builder: (ctx) {
        final bloc = _bloc;
        return Scaffold(
          appBar: AppBar(
              title: Text(widget.initial == null ? 'Add Item' : 'Edit Item')),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                child: Column(children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: imageFile != null
                          ? FileImage(imageFile!)
                          : (widget.initial != null &&
                                      widget.initial!['imageUrl'] != null
                                  ? NetworkImage(widget.initial!['imageUrl'])
                                  : AssetImage(
                                      'assets/images/preset_catalog/shop_placeholder.png'))
                              as ImageProvider,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                      initialValue: name,
                      decoration: InputDecoration(labelText: 'Store Name'),
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Required' : null,
                      onSaved: (v) => name = v),
                  TextFormField(
                      initialValue: price?.toString(),
                      decoration: InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                      onSaved: (v) => price = double.tryParse(v ?? '0')),
                  Row(children: [
                    Text('Veg'),
                    Switch(
                        value: veg, onChanged: (v) => setState(() => veg = v))
                  ]),
                  TextFormField(
                      initialValue: stock.toString(),
                      decoration: InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => stock = int.tryParse(v ?? '0') ?? 0),
                  TextFormField(
                      initialValue: category,
                      decoration: InputDecoration(labelText: 'Category'),
                      onSaved: (v) =>
                          category = (v == null || v.isEmpty) ? 'General' : v),
                  if (uploadProgress > 0 && uploadProgress < 1.0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(value: uploadProgress),
                    ),
                  SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!_form.currentState!.validate()) return;
                              _form.currentState!.save();
                              setState(() => isSaving = true);

                              final completer = Completer<void>();

                              if (widget.initial == null) {
                                bloc.add(CreateItemEventWithProgress(
                                  name: name!,
                                  price: price!,
                                  veg: veg,
                                  stock: stock,
                                  category: category,
                                  localImagePath: imageFile?.path,
                                  onProgress: (sent, total) {
                                    setState(() {
                                      uploadProgress =
                                          total > 0 ? sent / total : 0;
                                    });
                                  },
                                  onComplete: () {
                                    completer.complete();
                                  },
                                  onError: () {
                                    completer.completeError('error');
                                  },
                                ));
                              } else {
                                bloc.add(UpdateItemEventWithProgress(
                                  id: widget.initial!['id'],
                                  name: name!,
                                  price: price!,
                                  veg: veg,
                                  stock: stock,
                                  category: category,
                                  localImagePath: imageFile?.path,
                                  onProgress: (sent, total) {
                                    setState(() {
                                      uploadProgress =
                                          total > 0 ? sent / total : 0;
                                    });
                                  },
                                  onComplete: () {
                                    completer.complete();
                                  },
                                  onError: () {
                                    completer.completeError('error');
                                  },
                                ));
                              }

                              try {
                                await completer.future;
                                // success
                              } catch (_) {
                                // handled by bloc state listener usually, but here we just stop spinner
                              }

                              setState(() => isSaving = false);
                              if (context.mounted) Navigator.pop(context, true);
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Save'))
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }
}
