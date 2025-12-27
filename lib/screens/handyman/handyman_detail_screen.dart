import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_button.dart';
import '../../utils/colors.dart';
import '../../widgets/booking_bottom_sheet.dart';

class HandymanDetailScreen extends StatefulWidget {
  final String handymanId;

  const HandymanDetailScreen({
    Key? key,
    required this.handymanId,
  }) : super(key: key);

  @override
  State<HandymanDetailScreen> createState() => _HandymanDetailScreenState();
}

class _HandymanDetailScreenState extends State<HandymanDetailScreen> {
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

            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                slivers: [
                  _buildHeader(fullName, hData),
                  _buildStatsRow(hData),
                  _buildAboutSection(hData, uData ?? {}),
                  _buildReviewSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              bottomNavigationBar: _buildBottomBar(context, hData, fullName),
            );
          },
        );
      },
    );
  }

  // ... (Header, StatsRow, AboutSection, and ReviewSection remain the same as your provided code)

  Widget _buildHeader(String name, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'H',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildStatCard((data['rating_avg'] ?? 0.0).toStringAsFixed(1), 'Rating', Icons.star, AppColors.accent),
            const SizedBox(width: 12),
            _buildStatCard('${data['jobs_completed'] ?? 0}', 'Jobs', Icons.work, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard('${data['experience'] ?? 0}', 'Years', Icons.trending_up, AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> hData, Map<String, dynamic> uData) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Professional Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (hData['bio'] != null && hData['bio'].toString().isNotEmpty) ...[
              Text(hData['bio'], style: const TextStyle(color: AppColors.textLight)),
              const SizedBox(height: 16),
            ],
            _buildInfoRow(Icons.location_on, uData['phone'] ?? 'Contact via app'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.attach_money, 'Rs ${(hData['hourly_rate'] ?? 0).toString()}/hr'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.verified, 'Verified Service Provider'),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('No reviews yet', style: TextStyle(color: AppColors.textLight)),
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
        Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
      ],
    );
  }

  // FIXED BOTTOM BAR TO MATCH CUSTOM BUTTON
  Widget _buildBottomBar(BuildContext context, Map<String, dynamic> hData, String fullName) {
    final double rate = (hData['hourly_rate'] is int)
        ? (hData['hourly_rate'] as int).toDouble()
        : (hData['hourly_rate'] ?? 0.0).toDouble();

    final String category = hData['category_name'] ?? 'Service';
    final bool isAvailable = hData['work_status'] == "Available";

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
        child: CustomButton(
          text: isAvailable ? 'Book Now' : 'Not Available',
          // If not available, we pass a dummy function that does nothing or null.
          // Since your CustomButton uses onPressed == null to disable, we do this:
          onPressed: isAvailable
              ? () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (sheetContext) => BookingBottomSheet(
                handymanId: widget.handymanId,
                handymanName: fullName,
                hourlyRate: rate,
                serviceName: category,
              ),
            );
          }
              : () {}, // Or pass null if you want it to look visually disabled (greyed out)
          // Matching the styling of your CustomButton
          backgroundColor: isAvailable ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}