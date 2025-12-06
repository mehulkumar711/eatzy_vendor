abstract class StoreState {}

class StoreInitial extends StoreState {}

class StoreLoading extends StoreState {}

class StoreItemsLoaded extends StoreState {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> categories;
  StoreItemsLoaded({required this.items, required this.categories});
}

class StoreError extends StoreState {
  final String message;
  StoreError(this.message);
}

class StoreActionInProgress extends StoreState {}

class StoreActionSuccess extends StoreState {}
