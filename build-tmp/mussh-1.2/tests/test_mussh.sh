#!/bin/bash
#
# Comprehensive test suite for mussh optimizations
# Tests functionality, performance, and edge cases
#

set -e  # Exit on any error
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSSH="$SCRIPT_DIR/../mussh"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    ((TEST_COUNT++))
    echo -n "Test $TEST_COUNT: $test_name... "
    
    # Run the test and capture exit code
    set +e
    eval "$test_command" >/dev/null 2>&1
    local actual_exit_code=$?
    set -e
    
    if [ "$actual_exit_code" = "$expected_exit_code" ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}FAIL${NC} (exit code: $actual_exit_code, expected: $expected_exit_code)"
        ((FAIL_COUNT++))
        return 1
    fi
}

run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    ((TEST_COUNT++))
    echo -n "Test $TEST_COUNT: $test_name... "
    
    # Run the test and capture output
    local output
    set +e
    output=$(eval "$test_command" 2>&1)
    local exit_code=$?
    set -e
    
    if [ "$exit_code" = "0" ] && echo "$output" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}PASS${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Expected pattern: $expected_pattern"
        echo "  Actual output: $output"
        echo "  Exit code: $exit_code"
        ((FAIL_COUNT++))
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    
    # Create test files
    cat > /tmp/test_hosts.txt << 'EOF'
# Test host file
localhost
127.0.0.1
# Comment line
invalid.host.example.com

EOF

    cat > /tmp/test_script.sh << 'EOF'
echo "Test script executed"
hostname
date
EOF

    # Make sure mussh is executable
    chmod +x "$MUSSH"
}

# Cleanup test environment
cleanup_test_env() {
    echo "Cleaning up test environment..."
    rm -f /tmp/test_hosts.txt /tmp/test_script.sh
    rm -rf /tmp/mussh.* 2>/dev/null || true
}

# Test basic functionality
test_basic_functionality() {
    echo -e "\n${YELLOW}=== Testing Basic Functionality ===${NC}"
    
    run_test "Help option" "$MUSSH --help" 0
    run_test "Version option" "$MUSSH -V" 0
    run_test "Syntax check" "bash -n $MUSSH" 0
    
    # Test invalid arguments
    run_test "Invalid option" "$MUSSH --invalid-option" 1
    run_test "No hosts provided" "$MUSSH -c 'echo test'" 1
}

# Test host list processing
test_host_processing() {
    echo -e "\n${YELLOW}=== Testing Host List Processing ===${NC}"
    
    # Test with debug mode to see host processing
    run_test_with_output "Single host processing" "$MUSSH -h localhost -c 'echo test' -d1" "HOSTLIST"
    run_test_with_output "Multiple hosts" "$MUSSH -h localhost 127.0.0.1 -c 'echo test' -d1" "HOSTLIST"
    run_test_with_output "Host file processing" "$MUSSH -H /tmp/test_hosts.txt -c 'echo test' -d1" "localhost"
    
    # Test host deduplication
    run_test_with_output "Host deduplication" "$MUSSH -h localhost localhost 127.0.0.1 -c 'echo test' -d1 -u" "HOSTLIST"
}

# Test file operations
test_file_operations() {
    echo -e "\n${YELLOW}=== Testing File Operations ===${NC}"
    
    run_test "Host file reading" "$MUSSH -H /tmp/test_hosts.txt -c 'echo test' -d1" 0
    run_test "Script file reading" "$MUSSH -h localhost -C /tmp/test_script.sh -d1" 0
    
    # Test non-existent files
    run_test "Non-existent host file" "$MUSSH -H /tmp/nonexistent.txt -c 'echo test'" 1
    run_test "Non-existent script file" "$MUSSH -h localhost -C /tmp/nonexistent.sh" 1
}

# Test concurrent execution
test_concurrent_execution() {
    echo -e "\n${YELLOW}=== Testing Concurrent Execution ===${NC}"
    
    # Test different concurrency levels
    run_test "Sequential execution" "$MUSSH -h localhost 127.0.0.1 -c 'echo test' -m1 -d1" 0
    run_test "Concurrent execution" "$MUSSH -h localhost 127.0.0.1 -c 'echo test' -m2 -d1" 0
    run_test "Unlimited concurrency" "$MUSSH -h localhost 127.0.0.1 -c 'echo test' -m0 -d1" 0
}

# Test SSH options and advanced features
test_ssh_options() {
    echo -e "\n${YELLOW}=== Testing SSH Options ===${NC}"
    
    run_test "SSH timeout option" "$MUSSH -h localhost -c 'echo test' -t5 -d1" 0
    run_test "SSH verbose option" "$MUSSH -h localhost -c 'echo test' -v1 -d1" 0
    run_test "Quiet mode" "$MUSSH -h localhost -c 'echo test' -q" 0
    run_test "Blocking mode" "$MUSSH -h localhost -c 'echo test' -b -d1" 0
    run_test "Custom shell" "$MUSSH -h localhost -c 'echo test' -s bash -d1" 0
}

# Test error handling and edge cases
test_error_handling() {
    echo -e "\n${YELLOW}=== Testing Error Handling ===${NC}"
    
    # Test with invalid numeric arguments
    run_test "Invalid debug level" "$MUSSH -h localhost -c 'echo test' -d invalid" 1
    run_test "Invalid concurrency" "$MUSSH -h localhost -c 'echo test' -m invalid" 1
    run_test "Invalid timeout" "$MUSSH -h localhost -c 'echo test' -t invalid" 1
    run_test "Invalid verbose level" "$MUSSH -h localhost -c 'echo test' -v 5" 1
    
    # Test empty inputs
    run_test "Empty command" "$MUSSH -h localhost -c ''" 0
    run_test "Empty host list" "echo '' | $MUSSH -H - -c 'echo test'" 1
}

# Test performance of optimized functions
test_performance() {
    echo -e "\n${YELLOW}=== Testing Performance ===${NC}"
    
    # Create a larger host list for performance testing
    local large_hostfile="/tmp/large_hosts.txt"
    echo "Creating large host file for performance testing..."
    for i in {1..100}; do
        echo "host$i.example.com" >> "$large_hostfile"
    done
    
    echo "Running performance test with 100 hosts..."
    local start_time=$(date +%s.%N)
    run_test "Large host list processing" "$MUSSH -H $large_hostfile -c 'echo test' -d1" 0
    local end_time=$(date +%s.%N)
    
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
    echo "Performance test completed in: ${duration}s"
    
    rm -f "$large_hostfile"
}

# Test specific optimized functions
test_optimized_functions() {
    echo -e "\n${YELLOW}=== Testing Optimized Functions ===${NC}"
    
    # Test the optimized file reading by checking debug output
    run_test_with_output "Host count calculation" "$MUSSH -h localhost 127.0.0.1 host3 -c 'echo test' -d1" "setting concurrency"
    
    # Test concurrent file operations (tests the optimized PID file handling)
    run_test "Concurrent PID handling" "$MUSSH -h localhost 127.0.0.1 -c 'sleep 0.1; echo test' -m2 -d2" 0
    
    # Test stdin input processing
    echo "echo 'stdin test'" | run_test "Stdin script processing" "$MUSSH -h localhost -C - -d1" 0
}

# Main test execution
main() {
    echo "Starting comprehensive mussh test suite..."
    echo "Testing mussh at: $MUSSH"
    
    # Check if mussh exists
    if [ ! -f "$MUSSH" ]; then
        echo -e "${RED}Error: mussh not found at $MUSSH${NC}"
        exit 1
    fi
    
    setup_test_env
    
    # Run all test suites
    test_basic_functionality
    test_host_processing
    test_file_operations
    test_concurrent_execution
    test_ssh_options
    test_error_handling
    test_performance
    test_optimized_functions
    
    cleanup_test_env
    
    # Print summary
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo "Total tests: $TEST_COUNT"
    echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
    echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
    
    if [ "$FAIL_COUNT" -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed. 😞${NC}"
        exit 1
    fi
}

# Run main function
main "$@"