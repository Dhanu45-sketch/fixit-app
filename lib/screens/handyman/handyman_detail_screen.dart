import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_button.dart';
import '../../utils/colors.dart';
import '../../widgets/booking_bottom_sheet.dart';
import '../../widgets/reviews_section.dart';
import '../../services/firestore_service.dart';

class HandymanDetailScreen extends StatefulWidget {
  final String handymanId;
  final bool isEmergency;
  final bool autoOpenBooking; // ✅ Added

  const HandymanDetailScreen({
    Key? key,
    required this.handymanId,
    this.isEmergency = false,
    this.autoOpenBooking = false, // ✅ Added
  }) : super(key: key);

  @override
  State<HandymanDetailScreen> createState() => _HandymanDetailScreenState();
}

class _HandymanDetailScreenState extends State<HandymanDetailScreen> {
  bool _hasAutoOpened = false; // To prevent multiple opens if stream updates

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('handymanProfiles')
          .doc(widget.handymanId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Profile not found")));
        }

        final hData = snapshot.data!.data() as Map<String, dynamic>;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.handymanId).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final uData = userSnap.data?.data() as Map<String, dynamic>?;
            final String firstName = uData?['first_name'] ?? 'Handyman';
            final String lastName = uData?['last_name'] ?? '';
            final String fullName = "$firstName $lastName";

            final double baseRate = (hData['hourly_rate'] is int)
                ? (hData['hourly_rate'] as int).toDouble()
                : (hData['hourly_rate'] ?? 0.0).toDouble();

            final double displayRate = widget.isEmergency
                ? FirestoreService.calculateEmergencyPrice(baseRate)
                : baseRate;

            final String category = hData['category_name'] ?? 'Service';
            final bool isAvailable = hData['work_status'] == "Available";
            final bool acceptsEmergencies = hData['accepts_emergencies'] ?? true;
            final bool canBook = widget.isEmergency
                ? (isAvailable && acceptsEmergencies)
                : isAvailable;

            // ✅ Auto-open booking sheet if requested and data is ready
            if (widget.autoOpenBooking && !_hasAutoOpened && canBook) {
              _hasAutoOpened = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _openBookingSheet(context, fullName, displayRate, category);
              });
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                slivers: [
                  _buildHeader(fullName, hData),
                  _buildStatsRow(hData),
                  _buildAboutSection(hData, uData ?? {}),

                  // Reviews Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ReviewsSection(
                        handymanId: widget.handymanId,
                        averageRating: (hData['rating_avg'] ?? 0.0).toDouble(),
                        totalReviews: hData['rating_count'] ?? 0,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              bottomNavigationBar: _buildBottomBar(context, hData, fullName, displayRate, category, canBook),
            );
          },
        );
      },
    );
  }

  void _openBookingSheet(BuildContext context, String fullName, double displayRate, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BookingBottomSheet(
        handymanId: widget.handymanId,
        handymanName: fullName,
        hourlyRate: displayRate,
        serviceName: category,
        isEmergency: widget.isEmergency,
      ),
    );
  }

  Widget _buildHeader(String name, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.isEmergency 
                  ? [Colors.red.shade700, Colors.red.shade900]
                  : [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'H',
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
                      ),
                    ),
                  ),
                  if (widget.isEmergency)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.shade700, width: 2),
                        ),
                        child: Icon(
                          Icons.emergency,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                data['category_name'] ?? 'Specialist',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              if (widget.isEmergency) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emergency, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Emergency Available',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    final double baseRate = (data['hourly_rate'] ?? 0.0).toDouble();
    final double displayRate = widget.isEmergency 
        ? FirestoreService.calculateEmergencyPrice(baseRate)
        : baseRate;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildStatCard((data['rating_avg'] ?? 0.0).toStringAsFixed(1), 'Rating', Icons.star, AppColors.accent),
            const SizedBox(width: 12),
            _buildStatCard('${data['jobs_completed'] ?? 0}', 'Jobs', Icons.work, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard(
              widget.isEmergency 
                  ? '₨${displayRate.toStringAsFixed(0)}'
                  : '${data['experience'] ?? 0}', 
              widget.isEmergency ? '/hr' : 'Years', 
              widget.isEmergency ? Icons.bolt : Icons.trending_up, 
              widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> hData, Map<String, dynamic> uData) {
    final double baseRate = (hData['hourly_rate'] ?? 0.0).toDouble();
    final double displayRate = widget.isEmergency 
        ? FirestoreService.calculateEmergencyPrice(baseRate)
        : baseRate;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: widget.isEmergency 
              ? Border.all(color: Colors.red.shade300, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Professional Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (widget.isEmergency) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (hData['bio'] != null && hData['bio'].toString().isNotEmpty) ...[
              Text(hData['bio'], style: const TextStyle(color: AppColors.textLight)),
              const SizedBox(height: 16),
            ],
            _buildInfoRow(Icons.location_on, uData['phone'] ?? 'Contact via app'),
            const SizedBox(height: 12),
            if (widget.isEmergency) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Emergency Pricing',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Rate:', style: TextStyle(fontSize: 13)),
                        Text('₨${baseRate.toStringAsFixed(0)}/hr', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Emergency Surcharge (15%):',
                          style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '+ ₨${(displayRate - baseRate).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Emergency Rate:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '₨${displayRate.toStringAsFixed(0)}/hr',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else
              _buildInfoRow(Icons.attach_money, '₨${baseRate.toStringAsFixed(0)}/hr'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.verified, 'Verified Service Provider'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textDark))),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Map<String, dynamic> hData, String fullName, double displayRate, String category, bool canBook) {
    final bool acceptsEmergencies = hData['accepts_emergencies'] ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5)
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isEmergency && !acceptsEmergencies)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'This pro does not accept emergency requests',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            CustomButton(
              text: canBook ? 'Book Now' : 'Not Available',
              onPressed: canBook
                  ? () => _openBookingSheet(context, fullName, displayRate, category)
                  : () {},
              backgroundColor: canBook 
                  ? (widget.isEmergency ? Colors.red.shade700 : AppColors.primary)
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
