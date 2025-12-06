import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/store_bloc.dart';
import '../bloc/store_event.dart';
import '../bloc/store_state.dart';
import '../widgets/item_card.dart';
import '../widgets/category_chip.dart';
import 'item_edit_page.dart';
// import '../../../core/localization.dart'; // Using basic strings for now if l10n fails or just use it if reliable

class ItemsPage extends StatefulWidget {
  const ItemsPage({Key? key}) : super(key: key);

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late StoreBloc _bloc;
  String selectedCategory = 'All';
  String search = '';
  // ignore: unused_field
  bool _blocInitialized = false;

  @override
  void initState() {
    super.initState();
    _initBloc();
  }

  Future<void> _initBloc() async {
    _bloc = await StoreBloc.create();
    _bloc.add(LoadItemsEvent());
    if (mounted)
      setState(() {
        _blocInitialized = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    // Basic L10n fallback or access
    // final l10n = context.l10n;

    if (!_blocInitialized)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Store Items"),
          actions: [
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  final res = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ItemEditPage()));
                  if (res == true) _bloc.add(LoadItemsEvent(force: true));
                })
          ],
        ),
        body: BlocBuilder<StoreBloc, StoreState>(builder: (context, state) {
          if (state is StoreLoading)
            return Center(child: CircularProgressIndicator());
          if (state is StoreError) return Center(child: Text(state.message));
          if (state is StoreItemsLoaded) {
            final items = state.items.where((it) {
              final cat = it['category'] ?? 'General';
              final name = (it['name'] ?? '').toString().toLowerCase();
              if (selectedCategory != 'All' && selectedCategory != cat)
                return false;
              if (search.isNotEmpty && !name.contains(search.toLowerCase()))
                return false;
              return true;
            }).toList();

            final cats = ['All'] +
                state.categories.map((c) => c['name'] as String).toList();

            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search items...'),
                  onChanged: (v) => setState(() => search = v),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                    children: cats
                        .map((c) => CategoryChip(
                            label: c,
                            selected: selectedCategory == c,
                            onTap: () => setState(() => selectedCategory = c)))
                        .toList()),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('No items'))
                    : RefreshIndicator(
                        onRefresh: () async =>
                            _bloc.add(LoadItemsEvent(force: true)),
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, idx) => ItemCard(
                            item: items[idx],
                            onEdit: () async {
                              final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ItemEditPage(initial: items[idx])));
                              if (res == true)
                                _bloc.add(LoadItemsEvent(force: true));
                            },
                            onDelete: () {
                              _bloc.add(DeleteItemEvent(items[idx]['id']));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text('Deleted'),
                                      action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () {
                                            // TODO: implement undo by re-creating locally or calling backend
                                          })));
                            },
                          ),
                        ),
                      ),
              )
            ]);
          }
          return Container();
        }),
      ),
    );
  }
}
