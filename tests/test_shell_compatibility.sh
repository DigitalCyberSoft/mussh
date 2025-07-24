#!/usr/bin/env bash
#
# Comprehensive shell compatibility test for mussh
# Tests both bash and zsh functionality
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test configuration
MUSSH_SCRIPT="../mussh"
TEST_HOST="255.255.255.255"  # Use invalid IP that will fail quickly

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_info() {
    print_status "$BLUE" "ℹ  $1"
}

print_success() {
    print_status "$GREEN" "✓ $1"
}

print_warning() {
    print_status "$YELLOW" "⚠ $1"
}

print_error() {
    print_status "$RED" "✗ $1"
}

# Function to run a test
run_test() {
    local test_name="$1"
    local shell="$2"
    local command="$3"
    local expected_pattern="$4"
    local should_fail="${5:-0}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    print_info "Testing ($shell): $test_name"
    
    # Run the command in the specified shell with timeout
    if [ "$shell" = "bash" ]; then
        output=$(timeout 10s bash -c "$command" 2>&1)
        exit_code=$?
    elif [ "$shell" = "zsh" ]; then
        output=$(timeout 10s zsh -c "$command" 2>&1)
        exit_code=$?
    else
        print_error "Unknown shell: $shell"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # Check results
    if [ "$should_fail" -eq 1 ]; then
        # Test should fail
        if [ $exit_code -ne 0 ] && echo "$output" | grep -q "$expected_pattern"; then
            print_success "Test passed (expected failure)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            print_error "Test failed (should have failed with pattern: $expected_pattern)"
            echo "  Output: $output"
            echo "  Exit code: $exit_code"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        # Test should succeed
        if echo "$output" | grep -q "$expected_pattern"; then
            print_success "Test passed"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            print_error "Test failed (expected pattern: $expected_pattern)"
            echo "  Output: $output"
            echo "  Exit code: $exit_code"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
}

# Function to test shell availability
check_shell_availability() {
    local shell=$1
    
    if ! command -v "$shell" >/dev/null 2>&1; then
        print_warning "$shell not available, skipping $shell tests"
        return 1
    fi
    
    print_success "$shell is available"
    return 0
}

# Function to test basic functionality
test_basic_functionality() {
    local shell=$1
    
    print_info "=== Testing basic functionality in $shell ==="
    
    # Test version output
    run_test "version output" "$shell" \
        "$MUSSH_SCRIPT -V" \
        "Version: [0-9]"
    
    # Test help output
    run_test "help output" "$shell" \
        "$MUSSH_SCRIPT --help" \
        "Usage:"
    
    # Test invalid option handling
    run_test "invalid option handling" "$shell" \
        "$MUSSH_SCRIPT --invalid-option 2>&1" \
        "invalid command" \
        1
    
    # Test basic debug output
    run_test "debug output" "$shell" \
        "$MUSSH_SCRIPT $TEST_HOST -c 'echo test' -d 2>&1" \
        "DEBUG LEVEL:"
}

# Function to test implicit arguments
test_implicit_arguments() {
    local shell=$1
    
    print_info "=== Testing implicit arguments in $shell ==="
    
    # Test implicit hosts
    run_test "implicit hosts" "$shell" \
        "$MUSSH_SCRIPT host1 host2 -c 'echo test' -d2 2>&1" \
        "DEBUG: HOSTLIST:.*host1 host2"
    
    # Test implicit command (use tr to join lines for pattern matching)
    run_test "implicit command" "$shell" \
        "$MUSSH_SCRIPT host1 host2 'echo hello world' -d2 2>&1 | tr '\n' ' '" \
        "DEBUG: THE SCRIPT:.*echo hello world"
    
    # Test safety checks
    run_test "mixed implicit/explicit hosts safety" "$shell" \
        "$MUSSH_SCRIPT -h explicit.host implicit.host -c 'test' 2>&1" \
        "Cannot mix implicit hosts" \
        1
    
    run_test "mixed implicit/explicit commands safety" "$shell" \
        "$MUSSH_SCRIPT -c 'cmd1' host1 'cmd with spaces' 2>&1" \
        "Cannot mix implicit command" \
        1
}

# Function to test advanced features
test_advanced_features() {
    local shell=$1
    
    print_info "=== Testing advanced features in $shell ==="
    
    # Test wildcard pattern detection
    run_test "wildcard pattern detection" "$shell" \
        "$MUSSH_SCRIPT 'test*.example.com' -c 'echo test' -d 2>&1" \
        "Expanding wildcard pattern\\|No hosts found matching pattern"
    
    # Test netgroup handling
    run_test "netgroup handling" "$shell" \
        "$MUSSH_SCRIPT @testgroup -c 'echo test' -d 2>&1" \
        "Expanding netgroup\\|Netgroup testgroup not found"
    
    # Test concurrent execution option
    run_test "concurrent execution option" "$shell" \
        "$MUSSH_SCRIPT $TEST_HOST -m5 -c 'echo test' -d 2>&1" \
        "Concurrency: 5"
    
    # Test SSH options passing
    run_test "SSH options passing" "$shell" \
        "$MUSSH_SCRIPT $TEST_HOST -o ConnectTimeout=10 -c 'echo test' -d2 2>&1" \
        "SSH ARGS:.*ConnectTimeout=10"
}

# Function to test shell-specific features
test_shell_specific_features() {
    local shell=$1
    
    print_info "=== Testing shell-specific features in $shell ==="
    
    # Test array handling (bash vs zsh differences)
    run_test "array handling" "$shell" \
        "$MUSSH_SCRIPT host1 host2 host3 -c 'echo test' -d2 2>&1" \
        "DEBUG: HOSTLIST:.*host1 host2 host3"
    
    # Test parameter expansion (use tr to join lines)
    run_test "parameter expansion" "$shell" \
        "$MUSSH_SCRIPT $TEST_HOST -c 'echo \$HOME' -d2 2>&1 | tr '\n' ' '" \
        "THE SCRIPT:.*echo.*HOME"
    
    # Test variable substitution in commands (use tr to join lines)
    run_test "variable substitution" "$shell" \
        "TEST_VAR='hello' $MUSSH_SCRIPT $TEST_HOST -c 'echo \$TEST_VAR' -d2 2>&1 | tr '\n' ' '" \
        "THE SCRIPT:.*echo.*TEST_VAR"
}

# Function to test error handling
test_error_handling() {
    local shell=$1
    
    print_info "=== Testing error handling in $shell ==="
    
    # Test missing host file
    run_test "missing host file error" "$shell" \
        "$MUSSH_SCRIPT -H nonexistent.hosts -c 'echo test' 2>&1" \
        "Host file.*does not exist" \
        1
    
    # Test missing script file
    run_test "missing script file error" "$shell" \
        "$MUSSH_SCRIPT $TEST_HOST -C nonexistent.script 2>&1" \
        "Script File.*does not exist" \
        1
    
    # Test no hosts specified
    run_test "no hosts specified error" "$shell" \
        "$MUSSH_SCRIPT -c 'echo test' 2>&1" \
        "must specify hosts" \
        1
}

# Function to test platform detection
test_platform_detection() {
    local shell=$1
    
    print_info "=== Testing platform detection in $shell ==="
    
    # Test that platform detection doesn't break functionality
    run_test "platform detection functionality" "$shell" \
        "$MUSSH_SCRIPT $TEST_HOST -c 'echo test' -d2 2>&1" \
        "DEBUG: HOSTLIST:\\|DEBUG: THE SCRIPT:"
}

# Function to generate test report
generate_report() {
    echo
    print_info "=== TEST SUMMARY ==="
    echo "Total tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "All tests passed! ✨"
        return 0
    else
        print_error "Some tests failed!"
        return 1
    fi
}

# Main test execution
main() {
    print_info "Starting comprehensive shell compatibility tests for mussh"
    print_info "Testing script: $MUSSH_SCRIPT"
    echo
    
    # Check if mussh script exists
    if [ ! -f "$MUSSH_SCRIPT" ]; then
        print_error "mussh script not found at $MUSSH_SCRIPT"
        print_error "Please run this test from the tests/ directory"
        exit 1
    fi
    
    # Check shell availability and run tests
    local shells_tested=0
    
    # Test bash
    if check_shell_availability "bash"; then
        echo
        print_info "🐚 TESTING BASH COMPATIBILITY"
        echo "=" "$(printf '%.0s=' {1..50})"
        
        test_basic_functionality "bash"
        test_implicit_arguments "bash"
        test_advanced_features "bash"
        test_shell_specific_features "bash"
        test_error_handling "bash"
        test_platform_detection "bash"
        
        shells_tested=$((shells_tested + 1))
    fi
    
    # Test zsh
    if check_shell_availability "zsh"; then
        echo
        print_info "🐚 TESTING ZSH COMPATIBILITY"
        echo "=" "$(printf '%.0s=' {1..50})"
        
        test_basic_functionality "zsh"
        test_implicit_arguments "zsh"
        test_advanced_features "zsh"
        test_shell_specific_features "zsh"
        test_error_handling "zsh"
        test_platform_detection "zsh"
        
        shells_tested=$((shells_tested + 1))
    fi
    
    # Check if any shells were tested
    if [ $shells_tested -eq 0 ]; then
        print_error "No compatible shells found for testing"
        exit 1
    fi
    
    # Generate final report
    generate_report
}

# Run main function
main "$@"