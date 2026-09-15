class Friend {
  final int? id; // SQLite autoincrement
  final String ownerPersonnelNo; // which user owns this record
  String name;
  String personnelNo;
  String? trade;
  String? bloodGroup;
  String phone;
  String? district;
  String? upazila;
  String? presentAddress;
  String? photoPath;
  bool isFavorite;

  Friend({
    this.id,
    required this.ownerPersonnelNo,
    required this.name,
    required this.personnelNo,
    this.trade,
    this.bloodGroup,
    required this.phone,
    this.district,
    this.upazila,
    this.presentAddress,
    this.photoPath,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'owner_personnel_no': ownerPersonnelNo,
        'name': name,
        'personnel_no': personnelNo,
        'trade': trade,
        'blood_gp': bloodGroup,
        'phone': phone,
        'district': district,
        'upazila': upazila,
        'present_address': presentAddress,
        'photo_path': photoPath,
        'is_favorite': isFavorite ? 1 : 0,
      };

  factory Friend.fromMap(Map<String, dynamic> m) => Friend(
        id: m['id'] as int?,
        ownerPersonnelNo: m['owner_personnel_no'] as String,
        name: m['name'] as String,
        personnelNo: m['personnel_no'] as String,
        trade: m['trade'] as String?,
        bloodGroup: m['blood_gp'] as String?,
        phone: m['phone'] as String,
        district: m['district'] as String?,
        upazila: m['upazila'] as String?,
        presentAddress: m['present_address'] as String?,
        photoPath: m['photo_path'] as String?,
        isFavorite: (m['is_favorite'] as int? ?? 0) == 1,
      );

  Friend copyWith({
    int? id,
    String? name,
    String? personnelNo,
    String? trade,
    String? bloodGroup,
    String? phone,
    String? district,
    String? upazila,
    String? presentAddress,
    String? photoPath,
    bool? isFavorite,
  }) =>
      Friend(
        id: id ?? this.id,
        ownerPersonnelNo: ownerPersonnelNo,
        name: name ?? this.name,
        personnelNo: personnelNo ?? this.personnelNo,
        trade: trade ?? this.trade,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        phone: phone ?? this.phone,
        district: district ?? this.district,
        upazila: upazila ?? this.upazila,
        presentAddress: presentAddress ?? this.presentAddress,
        photoPath: photoPath ?? this.photoPath,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
