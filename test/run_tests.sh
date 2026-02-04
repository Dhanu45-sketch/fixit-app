#!/bin/bash

# FixIt App Test Runner Script - UPDATED
# Handyman tests run LAST (optional if approval not ready)

echo "================================"
echo "FixIt App - Automated Testing"
echo "UPDATED: Handyman tests optional"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_section() {
    echo -e "${BLUE}▶ $1${NC}"
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
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1
echo ""

# ============================================
# PHASE 1: CUSTOMER TESTS (Run First - No Approval Needed)
# ============================================

print_section "PHASE 1: CUSTOMER TESTS (No Approval Required)"
echo "================================"

print_info "Running Unit Tests (Customer models)..."
# Using models_test.dart as current existing file
flutter test test/unit/models_test.dart \
    --name "Booking|UserModel Tests - Customer|ServiceCategory|JobRequest|Review" \
    --reporter expanded
CUSTOMER_UNIT_RESULT=$?

if [ $CUSTOMER_UNIT_RESULT -eq 0 ]; then
    print_success "Customer unit tests passed"
else
    print_error "Customer unit tests failed"
fi
echo ""

print_info "Running Firestore Tests (Customer operations)..."
# Using firestore_service_test.dart as current existing file
flutter test test/unit/firestore_service_test.dart \
    --name "Customer|Booking|Review|Notification|Service Category" \
    --reporter expanded
CUSTOMER_FIRESTORE_RESULT=$?

if [ $CUSTOMER_FIRESTORE_RESULT -eq 0 ]; then
    print_success "Customer Firestore tests passed"
else
    print_error "Customer Firestore tests failed"
fi
echo ""

print_info "Running Widget Tests (Customer widgets)..."
flutter test test/widget/ --reporter expanded
WIDGET_TEST_RESULT=$?

if [ $WIDGET_TEST_RESULT -eq 0 ]; then
    print_success "Widget tests passed"
else
    print_error "Widget tests failed"
fi
echo ""

# ============================================
# PHASE 2: HANDYMAN TESTS (Run Last - Needs Approval)
# ============================================

echo ""
print_section "PHASE 2: HANDYMAN TESTS (Requires Approval)"
echo "================================"

# Ask if user wants to run handyman tests
read -p "$(echo -e ${YELLOW}Do you have an approved handyman account ready? [y/N]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Running Handyman Unit Tests..."
    flutter test test/unit/models_test.dart \
        --name "Handyman" \
        --reporter expanded
    HANDYMAN_UNIT_RESULT=$?

    if [ $HANDYMAN_UNIT_RESULT -eq 0 ]; then
        print_success "Handyman unit tests passed"
    else
        print_error "Handyman unit tests failed"
    fi
    echo ""

    print_info "Running Handyman Firestore Tests..."
    flutter test test/unit/firestore_service_test.dart \
        --name "Handyman|Document Verification" \
        --reporter expanded
    HANDYMAN_FIRESTORE_RESULT=$?

    if [ $HANDYMAN_FIRESTORE_RESULT -eq 0 ]; then
        print_success "Handyman Firestore tests passed"
    else
        print_error "Handyman Firestore tests failed"
    fi
    echo ""
else
    print_info "Skipping handyman tests (run later after approval)"
    HANDYMAN_UNIT_RESULT=0  # Don't count as failure
    HANDYMAN_FIRESTORE_RESULT=0
fi

# ============================================
# INTEGRATION TESTS (Optional - Needs Device)
# ============================================

echo ""
print_section "PHASE 3: INTEGRATION TESTS (Optional)"
echo "================================"

# Check if device is connected
print_info "Checking for connected devices..."
DEVICES=$(flutter devices 2>/dev/null | grep -c "connected")

if [ "$DEVICES" -gt 0 ]; then
    print_success "Device found"
    
    read -p "$(echo -e ${YELLOW}Run integration tests? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Building app for integration tests..."
        flutter build apk --debug > /dev/null 2>&1

        print_info "Running integration tests..."
        flutter test integration_test/
        INTEGRATION_TEST_RESULT=$?

        if [ $INTEGRATION_TEST_RESULT -eq 0 ]; then
            print_success "Integration tests passed"
        else
            print_error "Integration tests failed"
        fi
    else
        print_info "Skipping integration tests"
        INTEGRATION_TEST_RESULT=0
    fi
else
    print_info "No devices connected - skipping integration tests"
    print_info "Connect a device or start an emulator to run integration tests"
    INTEGRATION_TEST_RESULT=0
fi
echo ""

# ============================================
# GENERATE COVERAGE REPORT
# ============================================

if [ $CUSTOMER_UNIT_RESULT -eq 0 ]; then
    echo ""
    print_section "GENERATING COVERAGE REPORT"
    echo "================================"
    
    print_info "Running tests with coverage..."
    flutter test --coverage > /dev/null 2>&1

    # Check if lcov is installed
    if command -v lcov &> /dev/null; then
        print_info "Generating HTML coverage report..."
        lcov --summary coverage/lcov.info 2>/dev/null | tail -n 3
        genhtml coverage/lcov.info -o coverage/html > /dev/null 2>&1
        print_success "Coverage report generated at coverage/html/index.html"
    else
        print_info "Install lcov to generate HTML coverage reports:"
        print_info "  Mac: brew install lcov"
        print_info "  Linux: apt-get install lcov"
    fi
fi
echo ""

# ============================================
# SUMMARY
# ============================================

echo ""
echo "================================"
echo "Test Summary"
echo "================================"

# Customer Tests
echo ""
echo "📱 CUSTOMER TESTS (No Approval Required):"
if [ $CUSTOMER_UNIT_RESULT -eq 0 ]; then
    print_success "Customer Unit Tests: PASSED"
else
    print_error "Customer Unit Tests: FAILED"
fi

if [ $CUSTOMER_FIRESTORE_RESULT -eq 0 ]; then
    print_success "Customer Firestore Tests: PASSED"
else
    print_error "Customer Firestore Tests: FAILED"
fi

if [ $WIDGET_TEST_RESULT -eq 0 ]; then
    print_success "Widget Tests: PASSED"
else
    print_error "Widget Tests: FAILED"
fi

# Handyman Tests
echo ""
echo "🔧 HANDYMAN TESTS (Requires Approval):"
if [ -z "$HANDYMAN_UNIT_RESULT" ] || [ $HANDYMAN_UNIT_RESULT -eq 0 ]; then
    if [ -z "$REPLY" ] || [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Handyman Tests: SKIPPED (run after approval)"
    else
        print_success "Handyman Unit Tests: PASSED"
        if [ $HANDYMAN_FIRESTORE_RESULT -eq 0 ]; then
            print_success "Handyman Firestore Tests: PASSED"
        else
            print_error "Handyman Firestore Tests: FAILED"
        fi
    fi
else
    print_error "Handyman Tests: FAILED"
fi

# Integration Tests
echo ""
echo "🔌 INTEGRATION TESTS (Optional):"
if [ $DEVICES -gt 0 ]; then
    if [ $INTEGRATION_TEST_RESULT -eq 0 ]; then
        print_success "Integration Tests: PASSED"
    else
        print_error "Integration Tests: FAILED"
    fi
else
    print_info "Integration Tests: SKIPPED (no device)"
fi

echo ""
echo "================================"
echo ""

# Calculate pass rate
TOTAL_TESTS=0
PASSED_TESTS=0

# Count customer tests (always run)
TOTAL_TESTS=$((TOTAL_TESTS + 3))
[ $CUSTOMER_UNIT_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))
[ $CUSTOMER_FIRESTORE_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))
[ $WIDGET_TEST_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))

# Count handyman tests (if run)
if [[ $REPLY =~ ^[Yy]$ ]]; then
    TOTAL_TESTS=$((TOTAL_TESTS + 2))
    [ $HANDYMAN_UNIT_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))
    [ $HANDYMAN_FIRESTORE_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# Count integration tests (if run)
if [ $DEVICES -gt 0 ] && [[ $REPLY =~ ^[Yy]$ ]]; then
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    [ $INTEGRATION_TEST_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# Show statistics
echo "📊 STATISTICS:"
echo "  Tests Run: $TOTAL_TESTS"
echo "  Passed: $PASSED_TESTS"
echo "  Failed: $((TOTAL_TESTS - PASSED_TESTS))"

if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "  Pass Rate: $PASS_RATE%"
fi

echo ""
echo "================================"
echo ""

# Exit with error if any critical tests failed
if [ $CUSTOMER_UNIT_RESULT -ne 0 ] || [ $CUSTOMER_FIRESTORE_RESULT -ne 0 ] || [ $WIDGET_TEST_RESULT -ne 0 ]; then
    print_error "Critical customer tests failed!"
    echo ""
    echo "💡 Recommended Actions:"
    echo "  1. Fix failing customer tests first"
    echo "  2. Run handyman tests after approval"
    echo "  3. Check coverage report for missed areas"
    exit 1
elif [[ $REPLY =~ ^[Yy]$ ]] && ([ $HANDYMAN_UNIT_RESULT -ne 0 ] || [ $HANDYMAN_FIRESTORE_RESULT -ne 0 ]); then
    print_error "Handyman tests failed!"
    echo ""
    echo "💡 Note: Customer tests passed - app functional for customers"
    echo "         Fix handyman tests before full deployment"
    exit 1
else
    print_success "All tests passed! ✨"
    echo ""
    echo "✅ Next Steps:"
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  1. ✓ Customer features tested and working"
        echo "  2. ⏳ Run handyman tests after backend approval"
        echo "  3. 📱 Run integration tests on real device"
    else
        echo "  1. ✓ All tests passing"
        echo "  2. 📱 Deploy to staging for manual testing"
        echo "  3. 🚀 Ready for production after QA approval"
    fi
    exit 0
fi
