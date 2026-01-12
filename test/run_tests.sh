#!/bin/bash

# FixIt App Test Runner Script
# This script runs all tests in the proper order

echo "================================"
echo "FixIt App - Automated Testing"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_success "Flutter found"
echo ""

# Clean previous build artifacts
print_info "Cleaning previous build artifacts..."
flutter clean
flutter pub get
echo ""

# Run Unit Tests
print_info "Running Unit Tests..."
echo "================================"
flutter test test/unit/ --coverage
UNIT_TEST_RESULT=$?

if [ $UNIT_TEST_RESULT -eq 0 ]; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
fi
echo ""

# Run Widget Tests
print_info "Running Widget Tests..."
echo "================================"
flutter test test/widget/
WIDGET_TEST_RESULT=$?

if [ $WIDGET_TEST_RESULT -eq 0 ]; then
    print_success "Widget tests passed"
else
    print_error "Widget tests failed"
fi
echo ""

# Check if device is connected for integration tests
print_info "Checking for connected devices..."
DEVICES=$(flutter devices | grep -c "connected")

if [ "$DEVICES" -gt 0 ]; then
    print_success "Device found - running integration tests"
    echo "================================"

    # Build the app first
    print_info "Building app for integration tests..."
    flutter build apk --debug

    # Run Integration Tests
    flutter test integration_test/
    INTEGRATION_TEST_RESULT=$?

    if [ $INTEGRATION_TEST_RESULT -eq 0 ]; then
        print_success "Integration tests passed"
    else
        print_error "Integration tests failed"
    fi
else
    print_error "No devices connected - skipping integration tests"
    print_info "Connect a device or start an emulator to run integration tests"
    INTEGRATION_TEST_RESULT=0  # Don't fail overall if device not available
fi
echo ""

# Generate Coverage Report
if [ $UNIT_TEST_RESULT -eq 0 ]; then
    print_info "Generating coverage report..."

    # Check if lcov is installed (needed for coverage reports)
    if command -v lcov &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        print_success "Coverage report generated at coverage/html/index.html"
    else
        print_info "Install lcov to generate HTML coverage reports: brew install lcov (Mac) or apt-get install lcov (Linux)"
    fi
fi
echo ""

# Summary
echo "================================"
echo "Test Summary"
echo "================================"

if [ $UNIT_TEST_RESULT -eq 0 ]; then
    print_success "Unit Tests: PASSED"
else
    print_error "Unit Tests: FAILED"
fi

if [ $WIDGET_TEST_RESULT -eq 0 ]; then
    print_success "Widget Tests: PASSED"
else
    print_error "Widget Tests: FAILED"
fi

if [ $DEVICES -gt 0 ]; then
    if [ $INTEGRATION_TEST_RESULT -eq 0 ]; then
        print_success "Integration Tests: PASSED"
    else
        print_error "Integration Tests: FAILED"
    fi
else
    print_info "Integration Tests: SKIPPED (no device)"
fi

echo "================================"
echo ""

# Exit with error if any tests failed
if [ $UNIT_TEST_RESULT -ne 0 ] || [ $WIDGET_TEST_RESULT -ne 0 ] || [ $INTEGRATION_TEST_RESULT -ne 0 ]; then
    print_error "Some tests failed!"
    exit 1
else
    print_success "All tests passed!"
    exit 0
fi