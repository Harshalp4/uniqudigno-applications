/// Account models — wallet, family members, addresses, subscriptions, support.
library;

class Wallet {
  final double balance;
  final double lifetimeEarned;
  const Wallet({required this.balance, required this.lifetimeEarned});

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        balance: ((j['balance'] ?? 0) as num).toDouble(),
        lifetimeEarned: ((j['lifetimeEarned'] ?? 0) as num).toDouble(),
      );
}

class WalletTxn {
  final String type; // Credit | Debit
  final String reason;
  final double amount;
  final String? note;
  final String createdAt;

  const WalletTxn({
    required this.type,
    required this.reason,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  bool get isCredit => type == 'Credit';

  factory WalletTxn.fromJson(Map<String, dynamic> j) => WalletTxn(
        type: (j['type'] ?? 'Credit').toString(),
        reason: (j['reason'] ?? '').toString(),
        amount: ((j['amount'] ?? 0) as num).toDouble(),
        note: j['note']?.toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );
}

class MembershipTier {
  final String name;
  final double cashbackMultiplier;
  final double discountPercent;
  final String? badgeColor;

  const MembershipTier({
    required this.name,
    required this.cashbackMultiplier,
    required this.discountPercent,
    this.badgeColor,
  });

  factory MembershipTier.fromJson(Map<String, dynamic> j) => MembershipTier(
        name: (j['name'] ?? '').toString(),
        cashbackMultiplier: ((j['cashbackMultiplier'] ?? 1) as num).toDouble(),
        discountPercent: ((j['discountPercent'] ?? 0) as num).toDouble(),
        badgeColor: j['badgeColor']?.toString(),
      );
}

class FamilyMember {
  final String id;
  final String name;
  final String relationship;
  final String? gender;
  final String bloodGroup;
  final DateTime? dateOfBirth;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.gender,
    this.bloodGroup = 'Unknown',
    this.dateOfBirth,
  });

  /// Age in whole years — needed to interpret lab reference ranges.
  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) a--;
    return a < 0 ? null : a;
  }

  /// "Spouse · Female · 34 yrs · O+" — the medically-relevant summary line.
  String get summary => [
        relationship,
        if (gender != null && gender!.isNotEmpty) gender,
        if (age != null) '$age yrs',
        if (bloodGroup.isNotEmpty && bloodGroup != 'Unknown') bloodGroup,
      ].join(' · ');

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        relationship: (j['relationship'] ?? '').toString(),
        gender: j['gender']?.toString(),
        bloodGroup: (j['bloodGroup'] ?? 'Unknown').toString(),
        dateOfBirth: DateTime.tryParse(
            (j['dateOfBirth'] ?? j['date_of_birth'] ?? '').toString()),
      );
}

class Address {
  final String id;
  final String type;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.type,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  String get fullLine =>
      [line1, line2, city, state, pincode].where((e) => e != null && e.toString().isNotEmpty).join(', ');

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: (j['id'] ?? '').toString(),
        type: (j['type'] ?? 'Home').toString(),
        line1: (j['line1'] ?? '').toString(),
        line2: j['line2']?.toString(),
        city: (j['city'] ?? '').toString(),
        state: (j['state'] ?? '').toString(),
        pincode: (j['pincode'] ?? '').toString(),
        isDefault: (j['isDefault'] ?? false) as bool,
      );
}

class Subscription {
  final String id;
  final String frequency;
  final String status;
  final String? nextBookingDate;
  final double pricePerCycle;

  const Subscription({
    required this.id,
    required this.frequency,
    required this.status,
    this.nextBookingDate,
    required this.pricePerCycle,
  });

  bool get isActive => status == 'Active';
  bool get isPaused => status == 'Paused';

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: (j['id'] ?? '').toString(),
        frequency: (j['frequency'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        nextBookingDate: j['nextBookingDate']?.toString(),
        pricePerCycle: ((j['pricePerCycle'] ?? 0) as num).toDouble(),
      );
}
