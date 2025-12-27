class ServiceCategory {
  final String id;
  final String name;
  final String icon;
  final int handymenCount;
  final double avgRate; // Added to fix the "avgRate" error in ServiceDetailScreen
  final bool isActive;  // Added to match Firestore filters

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.handymenCount = 0,
    this.avgRate = 0.0,
    this.isActive = true,
  });

  factory ServiceCategory.fromMap(Map<String, dynamic> data, String documentId) {
    return ServiceCategory(
      id: documentId,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '🛠️',
      // We map handyman_count and avg_rate from your Firestore/SQL names
      handymenCount: data['handyman_count'] ?? 0,
      avgRate: (data['avg_rate'] ?? 0.0).toDouble(),
      isActive: data['is_active'] ?? true,
    );
  }

  // Updated CopyWith to handle the new fields
  ServiceCategory copyWith({
    int? handymenCount,
    double? avgRate,
    bool? isActive,
  }) {
    return ServiceCategory(
      id: id,
      name: name,
      icon: icon,
      handymenCount: handymenCount ?? this.handymenCount,
      avgRate: avgRate ?? this.avgRate,
      isActive: isActive ?? this.isActive,
    );
  }
}