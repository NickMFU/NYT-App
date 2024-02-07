// item.dart

class Item {
  final String itemId;
  final String barcode;
  final String description;

  Item({
    required this.itemId,
    required this.barcode,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'barcode': barcode,
      'description': description,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      itemId: map['itemId'],
      barcode: map['barcode'],
      description: map['description'],
    );
  }
}
