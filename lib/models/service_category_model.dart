
// ==========================================
// FILE: lib/models/service_category_model.dart
// ==========================================
class ServiceCategory {
  final int id;
  final String name;
  final String icon;
  final int handymenCount;
  final double avgRate;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.handymenCount,
    required this.avgRate,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['category_id'],
      name: json['category_name'],
      icon: json['icon'] ?? '🔧',
      handymenCount: json['handymen_count'] ?? 0,
      avgRate: json['avg_rate']?.toDouble() ?? 0.0,
    );
  }
}
