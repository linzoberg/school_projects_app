class SchoolModel {
  final String id;
  final String name;
  final String city;
  final String region;
  final String contactPerson;

  SchoolModel({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.contactPerson,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map, String id) {
    return SchoolModel(
      id: id,
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      region: map['region'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'region': region,
      'contactPerson': contactPerson,
    };
  }

  // Удобно для отображения в выпадающем списке
  @override
  String toString() => name;
}