import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
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

  Future<void> _openChat() async {
    setState(() => _isLoading = true);

    try {
      String chatId;
      String hName = "";
      
      // Resolve names first
      if (!_isHandyman) {
        hName = await _getHandymanName();
      }
      
      final String otherName = _isHandyman 
          ? widget.booking.customerName 
          : hName;

      if (_chatId != null) {
        chatId = _chatId!;
      } else {
        // Create new chat
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _getHandymanName() async {
    final handymanProfile = await _firestoreService.getUserProfile(widget.booking.handymanId);
    return '${handymanProfile?['first_name'] ?? ''} ${handymanProfile?['last_name'] ?? ''}'.trim();
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
    try {
      await _firestoreService.cancelBooking(
        bookingId: widget.booking.id,
        cancelledBy: _currentUserId!,
        cancelledByType: _isHandyman ? 'handyman' : 'customer',
        reason: reason,
        notes: notes,
      );

      if (mounted) {
        Navigator.pop(context); // Close detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      rethrow; // Let CancelBookingSheet handle the error
    }
  }

  @override
  Widget build(BuildContext context) {
    final canChat = widget.booking.status == 'Confirmed' || 
                    widget.booking.status == 'In Progress' ||
                    widget.booking.status == 'Pending'; // Allow chat for pending too
    
    final canCancel = widget.booking.status != 'Completed' && 
                      widget.booking.status != 'Cancelled' &&
                      widget.booking.status != 'In Progress';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      _isHandyman 
                          ? (widget.booking.customerName.isNotEmpty ? widget.booking.customerName[0] : 'C')
                          : (widget.booking.serviceName.isNotEmpty ? widget.booking.serviceName[0] : 'S'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isHandyman 
                        ? widget.booking.customerName 
                        : widget.booking.serviceName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isHandyman)
                    Text(
                      widget.booking.serviceName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildStatusBadge(widget.booking.status),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Booking Info
            _buildInfoSection(),
            
            const SizedBox(height: 20),

            // Payment Info
            _buildPaymentSection(),
            
            const SizedBox(height: 20),

            // Action Buttons
            if (canChat || canCancel)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (canChat) ...[
                      CustomButton(
                        text: '💬 Contact ${_isHandyman ? "Customer" : "Handyman"}',
                        onPressed: _openChat,
                        isLoading: _isLoading,
                        backgroundColor: AppColors.primary,
                      ),
                      if (canCancel) const SizedBox(height: 12),
                    ],
                    if (canCancel)
                      OutlinedButton(
                        onPressed: _showCancelDialog,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cancel_outlined, color: AppColors.error),
                            const SizedBox(width: 8),
                            const Text(
                              'Cancel Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
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
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        color = AppColors.success;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'in progress':
        color = AppColors.primary;
        break;
      case 'completed':
        color = AppColors.success;
        break;
      case 'cancelled':
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.booking.isEmergency)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.emergency, color: Colors.red, size: 16),
            ),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            'Booking Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_outlined, 'Location', widget.booking.address),
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            '${widget.booking.scheduledStartTime.day}/${widget.booking.scheduledStartTime.month}/${widget.booking.scheduledStartTime.year}',
          ),
          _buildInfoRow(
            Icons.access_time,
            'Time',
            '${widget.booking.scheduledStartTime.hour}:${widget.booking.scheduledStartTime.minute.toString().padLeft(2, '0')}',
          ),
          if (widget.booking.notes.isNotEmpty)
            _buildInfoRow(Icons.note, 'Notes', widget.booking.notes),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount'),
              Text(
                'Rs ${widget.booking.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
