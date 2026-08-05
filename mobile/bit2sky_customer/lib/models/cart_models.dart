/// Cart models from /cart (envelope -> CartSummary).
library;

class CartItem {
  final String id;
  final String? testId;
  final String? packageId;
  final String? familyMemberId; // null = the account holder ("Me")
  final String itemName;
  final num mrp;
  final num price;

  const CartItem({
    required this.id,
    this.testId,
    this.packageId,
    this.familyMemberId,
    required this.itemName,
    required this.mrp,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: (j['id'] ?? '').toString(),
        testId: j['testId']?.toString(),
        packageId: j['packageId']?.toString(),
        familyMemberId: j['familyMemberId']?.toString(),
        itemName: (j['itemName'] ?? '').toString(),
        mrp: (j['mrp'] ?? 0) as num,
        price: (j['price'] ?? 0) as num,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'testId': testId,
        'packageId': packageId,
        'familyMemberId': familyMemberId,
        'itemName': itemName,
        'mrp': mrp,
        'price': price,
      };
}

class CartSummary {
  final String cartId;
  final List<CartItem> items;
  final num itemsTotal;
  final num discount;
  final num walletApplied;
  final num payable;
  final String? couponCode;
  final num couponDiscount;
  final num groupDiscount;

  const CartSummary({
    required this.cartId,
    required this.items,
    required this.itemsTotal,
    required this.discount,
    required this.walletApplied,
    required this.payable,
    this.couponCode,
    this.couponDiscount = 0,
    this.groupDiscount = 0,
  });

  bool get isEmpty => items.isEmpty;
  Set<String> get testIds =>
      items.where((i) => i.testId != null).map((i) => i.testId!).toSet();
  Set<String> get packageIds =>
      items.where((i) => i.packageId != null).map((i) => i.packageId!).toSet();

  factory CartSummary.fromJson(Map<String, dynamic> j) => CartSummary(
        cartId: (j['cartId'] ?? '').toString(),
        items: ((j['items'] ?? []) as List)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        itemsTotal: (j['itemsTotal'] ?? 0) as num,
        discount: (j['discount'] ?? 0) as num,
        walletApplied: (j['walletApplied'] ?? 0) as num,
        payable: (j['payable'] ?? 0) as num,
        couponCode: j['couponCode']?.toString(),
        couponDiscount: (j['couponDiscount'] ?? 0) as num,
        groupDiscount: (j['groupDiscount'] ?? 0) as num,
      );
}

/// One available coupon offer — GET /coupons.
class CouponOffer {
  final String code;
  final String? description;
  final num? minOrderValue;

  const CouponOffer({required this.code, this.description, this.minOrderValue});

  factory CouponOffer.fromJson(Map<String, dynamic> j) => CouponOffer(
        code: (j['code'] ?? '').toString(),
        description: j['description']?.toString(),
        minOrderValue: j['minOrderValue'] as num?,
      );
}
