import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import '../repository/store_repository.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreRepository _repo;
  StoreBloc._(this._repo) : super(StoreInitial()) {
    on<LoadItemsEvent>(_onLoad);
    on<CreateItemEvent>(_onCreate);
    on<UpdateItemEvent>(_onUpdate);
    on<DeleteItemEvent>(_onDelete);
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
  }

  static Future<StoreBloc> create() async {
    final repo = await StoreRepository.create();
    return StoreBloc._(repo);
  }

  Future<void> _onLoad(LoadItemsEvent e, Emitter emit) async {
    emit(StoreLoading());
    try {
      final items = await _repo.fetchItems(forceRemote: e.force);
      final categories = await _repo.fetchCategories();
      emit(StoreItemsLoaded(items: items, categories: categories));
    } catch (ex) {
      emit(StoreError('Failed to load items'));
    }
  }

  Future<void> _onCreate(CreateItemEvent e, Emitter emit) async {
    emit(StoreActionInProgress());
    try {
      if (e is CreateItemEventWithProgress) {
        await _repo.createItem(
          name: e.name,
          price: e.price,
          veg: e.veg,
          stock: e.stock,
          category: e.category,
          imageFile: e.localImagePath != null ? File(e.localImagePath!) : null,
          onUploadProgress: (sent, total) {
            if (e.onProgress != null) e.onProgress!(sent, total);
          },
        );
        e.onComplete?.call();
      } else {
        await _repo.createItem(
          name: e.name,
          price: e.price,
          veg: e.veg,
          stock: e.stock,
          category: e.category,
          imageFile: e.localImagePath != null ? File(e.localImagePath!) : null,
        );
      }
      add(LoadItemsEvent(force: true));
      emit(StoreActionSuccess());
    } catch (ex) {
      if (e is CreateItemEventWithProgress) e.onError?.call();
      emit(StoreError('Failed to create item'));
    }
  }

  Future<void> _onUpdate(UpdateItemEvent e, Emitter emit) async {
    emit(StoreActionInProgress());
    try {
      if (e is UpdateItemEventWithProgress) {
        await _repo.updateItem(
          id: e.id,
          name: e.name,
          price: e.price,
          veg: e.veg,
          stock: e.stock,
          category: e.category,
          imageFile: e.localImagePath != null ? File(e.localImagePath!) : null,
          onUploadProgress: (sent, total) {
            if (e.onProgress != null) e.onProgress!(sent, total);
          },
        );
        e.onComplete?.call();
      } else {
        await _repo.updateItem(
          id: e.id,
          name: e.name,
          price: e.price,
          veg: e.veg,
          stock: e.stock,
          category: e.category,
          imageFile: e.localImagePath != null ? File(e.localImagePath!) : null,
        );
      }
      add(LoadItemsEvent(force: true));
      emit(StoreActionSuccess());
    } catch (ex) {
      if (e is UpdateItemEventWithProgress) e.onError?.call();
      emit(StoreError('Failed to update item'));
    }
  }

  Future<void> _onDelete(DeleteItemEvent e, Emitter emit) async {
    emit(StoreActionInProgress());
    try {
      await _repo.deleteItem(e.id);
      add(LoadItemsEvent(force: true));
      emit(StoreActionSuccess());
    } catch (ex) {
      emit(StoreError('Failed to delete item'));
    }
  }

  Future<void> _onLoadCategories(LoadCategoriesEvent e, Emitter emit) async {
    try {
      final categories = await _repo.fetchCategories();
      final items = state is StoreItemsLoaded
          ? (state as StoreItemsLoaded).items
          : <Map<String, dynamic>>[];
      emit(StoreItemsLoaded(items: items, categories: categories));
    } catch (ex) {
      emit(StoreError('Failed to load categories'));
    }
  }

  Future<void> _onCreateCategory(CreateCategoryEvent e, Emitter emit) async {
    try {
      await _repo.createCategory(e.name);
      add(LoadCategoriesEvent());
    } catch (ex) {
      emit(StoreError('Failed to create category'));
    }
  }
}
