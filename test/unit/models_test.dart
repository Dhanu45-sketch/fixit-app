// Save as: test/unit/models_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixit_app/models/booking_model.dart';
import 'package:fixit_app/models/user_model.dart';
import 'package:fixit_app/models/service_category_model.dart';
import 'package:fixit_app/models/job_request_model.dart';

void main() {
  group('Booking Model Tests', () {
    test('Booking.fromFirestore creates object correctly', () {
      // Arrange
      final timestamp = Timestamp.fromDate(DateTime(2026, 1, 15, 10, 0));
      final mockDoc = MockDocumentSnapshot({
        'customer_id': 'cust123',
        'handyman_id': 'hand123',
        'customer_name': 'John Doe',
        'service_name': 'Plumbing',
        'status': 'Pending',
        'scheduled_start_time': timestamp,
        'total_price': 1500.0,
        'notes': 'Fix leak',
        'address': '123 Main St',
        'is_emergency': false,
      }, 'booking123');

      // Act
      final booking = Booking.fromFirestore(mockDoc);

      // Assert
      expect(booking.id, 'booking123');
      expect(booking.customerId, 'cust123');
      expect(booking.handymanId, 'hand123');
      expect(booking.customerName, 'John Doe');
      expect(booking.serviceName, 'Plumbing');
      expect(booking.status, 'Pending');
      expect(booking.totalPrice, 1500.0);
      expect(booking.notes, 'Fix leak');
      expect(booking.address, '123 Main St');
      expect(booking.isEmergency, false);

      print('✓ Booking.fromFirestore test passed');
    });

    test('Booking.toMap converts to Map correctly', () {
      // Arrange
      final booking = Booking(
        id: 'booking123',
        customerId: 'cust123',
        handymanId: 'hand123',
        customerName: 'John Doe',
        serviceName: 'Plumbing',
        status: 'Confirmed',
        scheduledStartTime: DateTime(2026, 1, 15, 10, 0),
        totalPrice: 1500.0,
        notes: 'Fix leak',
        address: '123 Main St',
        isEmergency: false,
      );

      // Act
      final map = booking.toMap();

      // Assert
      expect(map['customer_id'], 'cust123');
      expect(map['handyman_id'], 'hand123');
      expect(map['customer_name'], 'John Doe');
      expect(map['service_name'], 'Plumbing');
      expect(map['status'], 'Confirmed');
      expect(map['total_price'], 1500.0);
      expect(map['notes'], 'Fix leak');
      expect(map['address'], '123 Main St');
      expect(map['is_emergency'], false);

      print('✓ Booking.toMap test passed');
    });

    test('Emergency booking has correct properties', () {
      // Arrange & Act
      final booking = Booking(
        id: 'booking456',
        customerId: 'cust456',
        handymanId: 'hand456',
        customerName: 'Jane Smith',
        serviceName: 'Emergency Plumbing',
        status: 'Pending',
        scheduledStartTime: DateTime.now(),
        totalPrice: 2250.0,
        notes: 'Burst pipe',
        address: '456 Oak Ave',
        isEmergency: true,
      );

      // Assert
      expect(booking.isEmergency, true);
      expect(booking.serviceName, contains('Emergency'));

      print('✓ Emergency booking test passed');
    });
  });

  group('UserModel Tests', () {
    test('UserModel.fromMap creates object correctly', () {
      // Arrange
      final data = {
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john@example.com',
        'phone': '0712345678',
        'is_handyman': false,
        'is_active': true,
        'created_at': Timestamp.now(),
      };

      // Act
      final user = UserModel.fromMap(data, 'user123');

      // Assert
      expect(user.uid, 'user123');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '0712345678');
      expect(user.isHandyman, false);
      expect(user.isActive, true);

      print('✓ UserModel.fromMap test passed');
    });

    test('UserModel.fullName returns correct full name', () {
      // Arrange
      final user = UserModel(
        uid: 'user123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '0712345678',
        isHandyman: false,
      );

      // Act & Assert
      expect(user.fullName, 'John Doe');

      print('✓ UserModel.fullName getter test passed');
    });

    test('UserModel.initials returns correct initials', () {
      // Arrange
      final user = UserModel(
        uid: 'user123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '0712345678',
        isHandyman: false,
      );

      // Act & Assert
      expect(user.initials, 'JD');

      print('✓ UserModel.initials getter test passed');
    });

    test('UserModel.toMap converts to Map correctly', () {
      // Arrange
      final user = UserModel(
        uid: 'user123',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '0787654321',
        isHandyman: true,
        isActive: true,
      );

      // Act
      final map = user.toMap();

      // Assert
      expect(map['first_name'], 'Jane');
      expect(map['last_name'], 'Smith');
      expect(map['email'], 'jane@example.com');
      expect(map['phone'], '0787654321');
      expect(map['is_handyman'], true);
      expect(map['is_active'], true);

      print('✓ UserModel.toMap test passed');
    });
  });

  group('ServiceCategory Model Tests', () {
    test('ServiceCategory.fromMap creates object correctly', () {
      // Arrange
      final data = {
        'name': 'Plumbing',
        'icon': '🔧',
        'handyman_count': 15,
        'avg_rate': 1500.0,
        'is_active': true,
      };

      // Act
      final category = ServiceCategory.fromMap(data, 'plumbing');

      // Assert
      expect(category.id, 'plumbing');
      expect(category.name, 'Plumbing');
      expect(category.icon, '🔧');
      expect(category.handymenCount, 15);
      expect(category.avgRate, 1500.0);
      expect(category.isActive, true);

      print('✓ ServiceCategory.fromMap test passed');
    });

    test('ServiceCategory.copyWith updates specified fields', () {
      // Arrange
      final original = ServiceCategory(
        id: 'plumbing',
        name: 'Plumbing',
        icon: '🔧',
        handymenCount: 10,
        avgRate: 1500.0,
      );

      // Act
      final updated = original.copyWith(
        handymenCount: 15,
        avgRate: 1800.0,
      );

      // Assert
      expect(updated.handymenCount, 15);
      expect(updated.avgRate, 1800.0);
      expect(updated.name, 'Plumbing'); // Unchanged
      expect(updated.icon, '🔧'); // Unchanged

      print('✓ ServiceCategory.copyWith test passed');
    });

    test('ServiceCategory handles missing fields with defaults', () {
      // Arrange
      final data = {
        'name': 'Electrical',
        // Missing icon, handyman_count, etc.
      };

      // Act
      final category = ServiceCategory.fromMap(data, 'electrical');

      // Assert
      expect(category.icon, '🛠️'); // Default
      expect(category.handymenCount, 0); // Default
      expect(category.avgRate, 0.0); // Default
      expect(category.isActive, true); // Default

      print('✓ ServiceCategory default values test passed');
    });
  });

  group('JobRequest Model Tests', () {
    test('JobRequest.fromMap creates object correctly', () {
      // Arrange
      final data = {
        'customer_user_id': 'cust123',
        'customer_name': 'John Doe',
        'description': 'Fix leaking tap',
        'job_type': 'Plumbing',
        'location_address': '123 Main St',
        'is_emergency': true,
        'created_time': Timestamp.now(),
        'status': 'Open',
        'offered_price': 1500.0,
      };

      // Act
      final jobRequest = JobRequest.fromMap(data, 'job123');

      // Assert
      expect(jobRequest.id, 'job123');
      expect(jobRequest.customerUserId, 'cust123');
      expect(jobRequest.customerName, 'John Doe');
      expect(jobRequest.description, 'Fix leaking tap');
      expect(jobRequest.jobType, 'Plumbing');
      expect(jobRequest.location, '123 Main St');
      expect(jobRequest.isEmergency, true);
      expect(jobRequest.status, 'Open');
      expect(jobRequest.offeredPrice, 1500.0);

      print('✓ JobRequest.fromMap test passed');
    });

    test('JobRequest handles boolean emergency as integer', () {
      // Arrange - Some databases store booleans as 0/1
      final data = {
        'customer_user_id': 'cust123',
        'customer_name': 'Jane Smith',
        'description': 'Emergency repair',
        'job_type': 'Electrical',
        'location_address': '456 Oak St',
        'is_emergency': 1, // Integer instead of boolean
        'created_time': Timestamp.now(),
        'status': 'Open',
        'offered_price': 2000.0,
      };

      // Act
      final jobRequest = JobRequest.fromMap(data, 'job456');

      // Assert
      expect(jobRequest.isEmergency, true);

      print('✓ JobRequest integer boolean test passed');
    });

    test('JobRequest.toMap converts to Map correctly', () {
      // Arrange
      final jobRequest = JobRequest(
        id: 'job123',
        customerUserId: 'cust123',
        customerName: 'John Doe',
        description: 'Fix leak',
        jobType: 'Plumbing',
        location: '123 Main St',
        isEmergency: false,
        createdTime: DateTime(2026, 1, 12),
        status: 'Open',
        offeredPrice: 1500.0,
      );

      // Act
      final map = jobRequest.toMap();

      // Assert
      expect(map['customer_user_id'], 'cust123');
      expect(map['customer_name'], 'John Doe');
      expect(map['description'], 'Fix leak');
      expect(map['job_type'], 'Plumbing');
      expect(map['location_address'], '123 Main St');
      expect(map['is_emergency'], false);
      expect(map['status'], 'Open');
      expect(map['offered_price'], 1500.0);

      print('✓ JobRequest.toMap test passed');
    });

    test('JobRequest handles missing optional fields', () {
      // Arrange - Minimal data
      final data = {
        'customer_user_id': 'cust123',
        'job_type': 'Plumbing',
        'created_time': Timestamp.now(),
      };

      // Act
      final jobRequest = JobRequest.fromMap(data, 'job123');

      // Assert
      expect(jobRequest.customerName, 'Anonymous'); // Default
      expect(jobRequest.description, 'No description provided'); // Default
      expect(jobRequest.location, 'No location'); // Default
      expect(jobRequest.status, 'Open'); // Default
      expect(jobRequest.offeredPrice, 0.0); // Default

      print('✓ JobRequest default values test passed');
    });
  });
}

// Mock DocumentSnapshot for testing
class MockDocumentSnapshot implements DocumentSnapshot {
  final Map<String, dynamic> _data;
  final String _id;

  MockDocumentSnapshot(this._data, this._id);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/*
TO RUN THESE TESTS:
===================

1. Run model tests:
   flutter test test/unit/models_test.dart

2. Run with verbose output:
   flutter test test/unit/models_test.dart --reporter expanded

3. All tests should pass with green checkmarks ✓
*/