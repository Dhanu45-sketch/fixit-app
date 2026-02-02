import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/navigation_service.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../chat/chat_screen.dart';
import '../../widgets/cancel_booking_sheet.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _firestoreService = FirestoreService();
  final _chatService = ChatService();
  final _authService = AuthService();
  final _navigationService = NavigationService();
  
  bool _isLoading = false;
  String? _chatId;
  String? _currentUserId;
  bool _isHandyman = false;

  @override
  void initState() {
    super.initState();
    _loadChatAndUserData();
  }

  Future<void> _loadChatAndUserData() async {
    _currentUserId = _authService.currentUserId;
    
    // Check if user is handyman
    final userProfile = await _authService.getCurrentUserProfile();
    if (userProfile != null && mounted) {
      setState(() {
        _isHandyman = userProfile['is_handyman'] ?? false;
      });
    }

    // Check if chat exists for this booking
    final existingChatId = await _chatService.getChatIdByBookingId(widget.booking.id);
    
    if (mounted) {
      setState(() {
        _chatId = existingChatId;
      });
    }
  }

  // --- Handyman Workflow Actions ---

  Future<void> _acceptBooking() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.acceptBooking(widget.booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startNavigation() async {
    // We navigate directly using the address stored in the booking
    final address = widget.booking.address;
    
    if (address.isEmpty || address == 'No Address') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No service address available for this booking')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Use the simpler address-based navigation
      final success = await _navigationService.navigateToAddress(address);

      if (success) {
        await _firestoreService.startNavigation(
          bookingId: widget.booking.id,
          handymanId: _currentUserId!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗺️ Navigation started!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps. Please install Google Maps.')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsArrived() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.markAsArrived(
        bookingId: widget.booking.id,
        handymanId: _currentUserId!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Marked as arrived!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeWork() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.updateBookingStatus(widget.booking.id, 'Completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completed! Excellent work.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Generic Actions ---

  Future<void> _openChat() async {
    setState(() => _isLoading = true);
    try {
      String chatId;
      String hName = "";
      if (!_isHandyman) hName = await _getHandymanName();
      final String otherName = _isHandyman ? widget.booking.customerName : hName;

      if (_chatId != null) {
        chatId = _chatId!;
      } else {
        chatId = await _chatService.createOrGetChat(
          bookingId: widget.booking.id,
          customerId: widget.booking.customerId,
          handymanId: widget.booking.handymanId,
          customerName: widget.booking.customerName,
          handymanName: hName.isEmpty ? await _getHandymanName() : hName,
        );
        setState(() => _chatId = chatId);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherParticipantName: otherName,
              bookingId: widget.booking.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getHandymanName() async {
    final handymanProfile = await _firestoreService.getUserProfile(widget.booking.handymanId);
    return '${handymanProfile?['first_name'] ?? ''} ${handymanProfile?['last_name'] ?? ''}'.trim();
  }

  Future<void> _callCustomer() async {
    final customerProfile = await _firestoreService.getUserProfile(widget.booking.customerId);
    final phone = customerProfile?['phone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone not available')));
      return;
    }
    await _navigationService.callCustomer(phone);
  }

  void _showCancelDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CancelBookingSheet(
        booking: widget.booking,
        onConfirmCancel: _handleCancellation,
      ),
    );
  }

  Future<void> _handleCancellation(String reason, String? notes) async {
    await _firestoreService.cancelBooking(
      bookingId: widget.booking.id,
      cancelledBy: _currentUserId!,
      cancelledByType: _isHandyman ? 'handyman' : 'customer',
      reason: reason,
      notes: notes,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking.status;
    final canChat = status == 'Confirmed' || status == 'On The Way' || status == 'In Progress' || status == 'Pending';
    final canCancel = status == 'Pending' || status == 'Confirmed' || status == 'On The Way';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      _isHandyman ? (widget.booking.customerName.isNotEmpty ? widget.booking.customerName[0] : 'C') : (widget.booking.serviceName.isNotEmpty ? widget.booking.serviceName[0] : 'S'),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_isHandyman ? widget.booking.customerName : widget.booking.serviceName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildStatusBadge(status),
                ],
              ),
            ),
            
            // NEW: Active Status Banner
            _buildActiveStatusBanner(),
            
            // NEW: Progress Tracker (Customer only)
            _buildProgressTracker(),

            // Booking Info
            _buildInfoSection(),
            const SizedBox(height: 20),
            
            // Payment Info
            _buildPaymentSection(),
            const SizedBox(height: 20),

            // ACTION BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // --- Handyman Specific Workflow ---
                  if (_isHandyman) ...[
                    if (status == 'Pending')
                      CustomButton(text: 'Accept Job', onPressed: _acceptBooking, isLoading: _isLoading),
                    
                    if (status == 'Confirmed')
                      CustomButton(text: '🗺️ Start Navigation', onPressed: _startNavigation, isLoading: _isLoading),
                    
                    if (status == 'On The Way')
                      CustomButton(text: '✅ Mark as Arrived', onPressed: _markAsArrived, isLoading: _isLoading, backgroundColor: AppColors.success),
                    
                    if (status == 'In Progress')
                      CustomButton(text: '🏁 Complete Work', onPressed: _completeWork, isLoading: _isLoading, backgroundColor: AppColors.success),
                    
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _callCustomer,
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Customer'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // --- Shared Actions ---
                  if (canChat) ...[
                    CustomButton(
                      text: '💬 Contact ${_isHandyman ? "Customer" : "Handyman"}',
                      onPressed: _openChat,
                      isLoading: _isLoading && status == 'Pending',
                      backgroundColor: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (canCancel)
                    OutlinedButton(
                      onPressed: _showCancelDialog,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel Booking', style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData? icon;
    switch (status.toLowerCase()) {
      case 'confirmed': color = AppColors.success; break;
      case 'on the way': color = Colors.orange; icon = Icons.directions_car; break;
      case 'in progress': color = AppColors.primary; icon = Icons.build; break;
      case 'completed': color = AppColors.success; icon = Icons.check_circle; break;
      case 'cancelled': case 'rejected': color = AppColors.error; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  /// Build a visual progress tracker showing booking stages
  /// Shows customers where handyman is in the journey
  Widget _buildProgressTracker() {
    // Don't show for handyman - they see action buttons instead
    if (_isHandyman) return const SizedBox.shrink();

    final status = widget.booking.status.toLowerCase();
    
    // Determine which step we're on
    int currentStep = 0;
    if (status == 'pending') currentStep = 0;
    else if (status == 'confirmed' || status == 'accepted') currentStep = 1;
    else if (status == 'on the way') currentStep = 2;
    else if (status == 'in progress') currentStep = 3;
    else if (status == 'completed') currentStep = 4;

    // Don't show tracker if cancelled or completed
    if (status == 'cancelled' || status == 'rejected') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),

          // Progress Steps
          _buildProgressStep(
            icon: Icons.pending_outlined,
            title: 'Request Sent',
            subtitle: 'Waiting for confirmation',
            isActive: currentStep >= 0,
            isCompleted: currentStep > 0,
          ),
          _buildProgressLine(isCompleted: currentStep > 0),
          
          _buildProgressStep(
            icon: Icons.check_circle_outline,
            title: 'Confirmed',
            subtitle: 'Handyman accepted',
            isActive: currentStep >= 1,
            isCompleted: currentStep > 1,
          ),
          _buildProgressLine(isCompleted: currentStep > 1),
          
          _buildProgressStep(
            icon: Icons.directions_car,
            title: 'On The Way',
            subtitle: currentStep == 2 
                ? 'Handyman is coming!' 
                : 'Handyman will start soon',
            isActive: currentStep >= 2,
            isCompleted: currentStep > 2,
            isPulsing: currentStep == 2,
          ),
          _buildProgressLine(isCompleted: currentStep > 2),
          
          _buildProgressStep(
            icon: Icons.build,
            title: 'In Progress',
            subtitle: currentStep == 3 
                ? 'Work has started' 
                : 'Waiting for work to begin',
            isActive: currentStep >= 3,
            isCompleted: currentStep > 3,
            isPulsing: currentStep == 3,
          ),
          _buildProgressLine(isCompleted: currentStep > 3),
          
          _buildProgressStep(
            icon: Icons.check_circle,
            title: 'Completed',
            subtitle: currentStep == 4 
                ? 'Job finished successfully' 
                : 'Waiting for completion',
            isActive: currentStep >= 4,
            isCompleted: currentStep >= 4,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    bool isPulsing = false,
  }) {
    Color color;
    if (isCompleted) {
      color = AppColors.success;
    } else if (isActive) {
      color = AppColors.primary;
    } else {
      color = Colors.grey.shade300;
    }

    return Row(
      children: [
        // Animated Icon Circle
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isPulsing ? 3 : 2,
            ),
            boxShadow: isPulsing
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Step Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? AppColors.textDark : Colors.grey,
                    ),
                  ),
                  if (isPulsing) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? AppColors.textLight : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 19, top: 4, bottom: 4),
      width: 2,
      height: 30,
      color: isCompleted ? AppColors.success : Colors.grey.shade300,
    );
  }

  /// Show a prominent banner at the top when handyman is on the way or working
  /// Gives customers immediate visual feedback
  Widget _buildActiveStatusBanner() {
    // Only show for customers
    if (_isHandyman) return const SizedBox.shrink();

    final status = widget.booking.status.toLowerCase();
    
    // Only show for active states
    if (status != 'on the way' && status != 'in progress') {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    if (status == 'on the way') {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      icon = Icons.directions_car;
      title = '🚗 Handyman is on the way!';
      subtitle = 'They will arrive at your location soon';
    } else {
      // in progress
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
      icon = Icons.build;
      title = '🔧 Work in progress';
      subtitle = 'Your handyman has started the service';
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'on the way' ? Colors.orange : Colors.blue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (status == 'on the way' ? Colors.orange : Colors.blue)
                .withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing Icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 1000),
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: Icon(
                  icon,
                  color: textColor,
                  size: 32,
                ),
              );
            },
            onEnd: () {
              // Restart animation
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(width: 16),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on_outlined, 'Location', widget.booking.address),
          _buildInfoRow(Icons.calendar_today, 'Date', '${widget.booking.scheduledStartTime.day}/${widget.booking.scheduledStartTime.month}'),
          _buildInfoRow(Icons.access_time, 'Time', '${widget.booking.scheduledStartTime.hour}:${widget.booking.scheduledStartTime.minute.toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Rs ${widget.booking.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ])
      ]),
    );
  }
}
