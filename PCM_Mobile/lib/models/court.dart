class Court {
  final int id;
  final String name;
  final String? description;
  final double pricePerHour;
  final bool isActive;

  Court({
    required this.id,
    required this.name,
    this.description,
    required this.pricePerHour,
    required this.isActive,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      isActive: json['isActive'],
    );
  }
}
