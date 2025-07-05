#!/bin/bash
#
# Test runner for all mussh tests
# Run this script from the tests directory or the project root
#

# Determine if we're in the tests directory or the project root
if [ -f "mussh" ]; then
    # We're in the project root
    TEST_DIR="tests"
    MUSSH_PATH="./mussh"
elif [ -f "../mussh" ]; then
    # We're in the tests directory
    TEST_DIR="."
    MUSSH_PATH="../mussh"
else
    echo "Error: Cannot find mussh script. Please run from project root or tests directory."
    exit 1
fi

echo "=== Mussh Test Suite Runner ==="
echo "Test directory: $TEST_DIR"
echo "Mussh path: $MUSSH_PATH"
echo ""

# Check if mussh exists and is executable
if [ ! -x "$MUSSH_PATH" ]; then
    echo "Error: mussh not found or not executable at $MUSSH_PATH"
    exit 1
fi

# Function to run a test script
run_test_script() {
    local script="$1"
    local description="$2"
    
    echo "=== Running $description ==="
    if [ -x "$TEST_DIR/$script" ]; then
        cd "$TEST_DIR" && ./"$script"
        local exit_code=$?
        cd - >/dev/null
        if [ $exit_code -eq 0 ]; then
            echo "✅ $description: PASSED"
        else
            echo "❌ $description: FAILED (exit code: $exit_code)"
            return $exit_code
        fi
    else
        echo "⚠️  $description: SKIPPED (script not found or not executable)"
        return 1
    fi
    echo ""
}

# Track overall results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Run all test scripts
echo "Starting test execution..."
echo ""

# 1. Function-specific tests
((TOTAL_TESTS++))
if run_test_script "function_tests.sh" "Function Optimization Tests"; then
    ((PASSED_TESTS++))
else
    ((FAILED_TESTS++))
fi

# 2. Quick performance tests
((TOTAL_TESTS++))
if run_test_script "quick_performance_test.sh" "Quick Performance Tests"; then
    ((PASSED_TESTS++))
else
    ((FAILED_TESTS++))
fi

# 3. Comprehensive test suite (may take longer)
echo "=== Running Comprehensive Test Suite ==="
echo "(This may take a few minutes...)"
((TOTAL_TESTS++))
if timeout 300 "$TEST_DIR/test_mussh.sh" >/dev/null 2>&1; then
    echo "✅ Comprehensive Test Suite: PASSED"
    ((PASSED_TESTS++))
else
    echo "❌ Comprehensive Test Suite: FAILED or TIMED OUT"
    ((FAILED_TESTS++))
fi
echo ""

# 4. Performance benchmark (optional, may take longer)
echo "=== Running Performance Benchmark ==="
echo "(This may take several minutes...)"
((TOTAL_TESTS++))
if timeout 600 "$TEST_DIR/performance_test.sh" >/dev/null 2>&1; then
    echo "✅ Performance Benchmark: COMPLETED"
    ((PASSED_TESTS++))
else
    echo "❌ Performance Benchmark: FAILED or TIMED OUT"
    ((FAILED_TESTS++))
fi
echo ""

# Print final summary
echo "=== Final Test Summary ==="
echo "Total test suites: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed! Mussh optimizations are working correctly."
    exit 0
else
    echo ""
    echo "❌ Some tests failed. Please check the output above for details."
    exit 1
fi