abstract class StoreEvent {}

class LoadItemsEvent extends StoreEvent {
  final bool force;
  LoadItemsEvent({this.force = false});
}

// new event signatures for progress
typedef UploadProgressCallback = void Function(int sent, int total);
typedef UploadComplete = void Function();
typedef UploadError = void Function();

class CreateItemEvent extends StoreEvent {
  final String name;
  final double price;
  final bool veg;
  final int stock;
  final String category;
  final String? localImagePath;
  CreateItemEvent(
      {required this.name,
      required this.price,
      required this.veg,
      required this.stock,
      required this.category,
      this.localImagePath});
}

class CreateItemEventWithProgress extends CreateItemEvent {
  final UploadProgressCallback? onProgress;
  final UploadComplete? onComplete;
  final UploadError? onError;
  CreateItemEventWithProgress(
      {required String name,
      required double price,
      required bool veg,
      required int stock,
      required String category,
      String? localImagePath,
      this.onProgress,
      this.onComplete,
      this.onError})
      : super(
            name: name,
            price: price,
            veg: veg,
            stock: stock,
            category: category,
            localImagePath: localImagePath);
}

class UpdateItemEvent extends StoreEvent {
  final String id;
  final String name;
  final double price;
  final bool veg;
  final int stock;
  final String category;
  final String? localImagePath;
  UpdateItemEvent(
      {required this.id,
      required this.name,
      required this.price,
      required this.veg,
      required this.stock,
      required this.category,
      this.localImagePath});
}

class UpdateItemEventWithProgress extends UpdateItemEvent {
  final UploadProgressCallback? onProgress;
  final UploadComplete? onComplete;
  final UploadError? onError;
  UpdateItemEventWithProgress(
      {required String id,
      required String name,
      required double price,
      required bool veg,
      required int stock,
      required String category,
      String? localImagePath,
      this.onProgress,
      this.onComplete,
      this.onError})
      : super(
            id: id,
            name: name,
            price: price,
            veg: veg,
            stock: stock,
            category: category,
            localImagePath: localImagePath);
}

class DeleteItemEvent extends StoreEvent {
  final String id;
  DeleteItemEvent(this.id);
}

class LoadCategoriesEvent extends StoreEvent {}

class CreateCategoryEvent extends StoreEvent {
  final String name;
  CreateCategoryEvent(this.name);
}
