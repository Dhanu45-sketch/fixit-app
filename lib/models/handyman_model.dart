// lib/models/service_category_model.dart
class ServiceCategory {
  final String id;
  final String name;
  final String icon;
  final int handymenCount;
  final bool isActive;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.handymenCount = 0,
    this.isActive = true,
  });

  factory ServiceCategory.fromMap(Map<String, dynamic> data, String documentId) {
    return ServiceCategory(
      id: documentId,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '🛠️',
      handymenCount: data['handyman_count'] ?? 0,
      isActive: data['is_active'] ?? true,
    );
  }
}