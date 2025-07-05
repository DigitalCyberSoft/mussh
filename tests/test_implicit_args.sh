#!/bin/bash
#
# Test script for mussh implicit arguments feature
# Tests implicit hosts and implicit commands functionality
#

# Set up test environment
MUSSH="../mussh"
TEST_HOST="127.0.0.1"  # Use localhost for testing
FAILED=0
PASSED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_pattern="$3"
    local should_fail="${4:-0}"  # Default: expect success
    
    echo -n "Testing: $test_name ... "
    
    # Run command and capture output and exit code
    output=$($command 2>&1)
    exit_code=$?
    
    if [ "$should_fail" -eq 1 ]; then
        # Expecting failure
        if [ $exit_code -ne 0 ] && echo "$output" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}PASSED${NC}"
            ((PASSED++))
        else
            echo -e "${RED}FAILED${NC}"
            echo "  Expected to fail with pattern: $expected_pattern"
            echo "  Got: $output"
            ((FAILED++))
        fi
    else
        # Expecting success
        if [ $exit_code -eq 0 ] || echo "$output" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}PASSED${NC}"
            ((PASSED++))
        else
            echo -e "${RED}FAILED${NC}"
            echo "  Expected pattern: $expected_pattern"
            echo "  Got: $output"
            ((FAILED++))
        fi
    fi
}

echo "=== Testing mussh implicit arguments feature ==="
echo

# Test 1: Basic implicit hosts
echo "== Testing implicit hosts =="
run_test "Single implicit host" \
    "$MUSSH nonexistent.host -c 'echo test' -d" \
    "HOSTLIST:.*nonexistent.host"

run_test "Multiple implicit hosts" \
    "$MUSSH host1 host2 host3 -c 'echo test' -d" \
    "HOSTLIST:.*host1.*host2.*host3"

run_test "Implicit hosts with wildcards" \
    "$MUSSH 'server*.example.com' -c 'echo test' -d" \
    "Expanding wildcard pattern"

run_test "Implicit hosts with netgroup" \
    "$MUSSH @webservers -c 'echo test' -d" \
    "Expanding netgroup"

echo

# Test 2: Implicit commands
echo "== Testing implicit commands =="
run_test "Implicit command with double quotes" \
    "$MUSSH host1 host2 \"echo hello world\" -d2" \
    "THE SCRIPT:.*echo hello world"

run_test "Implicit command with single quotes" \
    "$MUSSH host1 host2 'echo hello world' -d2" \
    "THE SCRIPT:.*echo hello world"

run_test "Implicit command with nested quotes" \
    "$MUSSH host1 'echo \"hello world\"' -d2" \
    "THE SCRIPT:.*echo \"hello world\""

echo

# Test 3: Safety checks - these should fail
echo "== Testing safety checks (expecting failures) =="
run_test "Mixing -h with implicit hosts" \
    "$MUSSH -h explicit.host implicit.host -c 'echo test'" \
    "Cannot mix implicit hosts with -h or -H options" \
    1

run_test "Mixing -H with implicit hosts" \
    "$MUSSH -H /etc/hosts -c 'echo test' extra.host" \
    "Cannot mix implicit hosts with -h or -H options" \
    1

run_test "Mixing implicit command with -c" \
    "$MUSSH -c 'first command' host1 \"second command\"" \
    "Cannot mix implicit command with -c or -C options" \
    1

run_test "Multiple implicit commands" \
    "$MUSSH host1 \"first command\" host2 \"second command\"" \
    "Only one implicit command allowed" \
    1

echo

# Test 4: Edge cases
echo "== Testing edge cases =="
run_test "Host without spaces (should be treated as host)" \
    "$MUSSH host1 uptime -d" \
    "HOSTLIST:.*host1.*uptime"

run_test "File-like argument without -h" \
    "$MUSSH script.sh -c 'echo test' -d" \
    "HOSTLIST:.*script.sh"

run_test "Path-like argument" \
    "$MUSSH /etc/hosts -c 'echo test' -d" \
    "HOSTLIST:.*/etc/hosts"

echo

# Test 5: Complex combinations
echo "== Testing complex combinations =="
run_test "Implicit hosts with options before command" \
    "$MUSSH host1 host2 -d -v1 'echo test' 2>&1 | grep -E '(DEBUG|THE SCRIPT)'" \
    "echo test"

run_test "Implicit hosts and command with other options" \
    "$MUSSH server1 server2 -m5 -d 'uptime' 2>&1 | grep 'Concurrency'" \
    "Concurrency: 5"

echo

# Test 6: Usage and help
echo "== Testing usage and help =="
run_test "Help shows implicit syntax" \
    "$MUSSH --help" \
    "host\.\.\] \[-c cmd | -C scriptfile | \"command\"\]"

run_test "Examples show implicit usage" \
    "$MUSSH --help | grep -A20 EXAMPLES" \
    "mussh host1 host2 \"cat /etc/hosts\""

echo
echo "=== Test Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi