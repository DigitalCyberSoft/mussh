#!/bin/bash
#
# Test suite for mussh implicit hosts and commands features
# This tests the new functionality added to allow:
# 1. mussh host1 host2 -c "command"  (implicit hosts)
# 2. mussh host1 host2 "command"      (implicit hosts and command)
#

MUSSH="../mussh"
TOTAL_TESTS=0
PASSED_TESTS=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test function
test_case() {
    local description="$1"
    local command="$2"
    local expected="$3"
    local should_fail="${4:-no}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Test $TOTAL_TESTS: $description ... "
    
    # Execute command and capture output
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    # Check results
    if [ "$should_fail" = "yes" ]; then
        if [ $exit_code -ne 0 ] && echo "$output" | grep -q "$expected"; then
            echo -e "${GREEN}PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}FAIL${NC}"
            echo "  Expected failure with: $expected"
            echo "  Got: $output" | head -3
        fi
    else
        if echo "$output" | grep -q "$expected"; then
            echo -e "${GREEN}PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}FAIL${NC}"
            echo "  Expected: $expected"
            echo "  Got: $output" | head -3
        fi
    fi
}

echo -e "${YELLOW}=== Testing mussh implicit arguments ===${NC}"
echo

# Basic functionality tests
echo -e "${YELLOW}Basic Implicit Hosts Tests:${NC}"
test_case "Single implicit host" \
    "$MUSSH testhost -c 'echo test' -d2 2>&1" \
    "DEBUG: HOSTLIST:.*testhost"

test_case "Multiple implicit hosts" \
    "$MUSSH host1 host2 host3 -c 'echo test' -d2 2>&1" \
    "DEBUG: HOSTLIST:.*host1 host2 host3"

# Test wildcard pattern recognition (use pattern that won't match to avoid hanging)
test_case "Implicit hosts with wildcard (pattern detection)" \
    "$MUSSH 'nonexistent*.example.com' -c 'echo test' -d 2>&1" \
    "Expanding wildcard pattern\|No hosts found matching pattern"

test_case "Implicit hosts with netgroup" \
    "$MUSSH @testgroup -c 'echo test' -d 2>&1" \
    "Expanding netgroup\|Netgroup testgroup not found"

echo

# Implicit command tests
echo -e "${YELLOW}Implicit Command Tests:${NC}"
test_case "Implicit command with spaces" \
    "$MUSSH host1 host2 'echo hello world' -d2 2>&1 | tr '\n' ' '" \
    "DEBUG: THE SCRIPT:.*echo hello world"

test_case "Command with internal options" \
    "$MUSSH server1 'ps aux | grep ssh' -d2 2>&1 | tr '\n' ' '" \
    "DEBUG: THE SCRIPT:.*ps aux | grep ssh"

test_case "Single word (no spaces) treated as host" \
    "$MUSSH host1 host2 uptime -d2 2>&1" \
    "DEBUG: HOSTLIST:.*host1 host2 uptime"

echo

# Safety checks (these should fail)
echo -e "${YELLOW}Safety Check Tests (expecting failures):${NC}"
test_case "Cannot mix -h with implicit hosts" \
    "$MUSSH -h server1 -c 'test' implicit 2>&1" \
    "Cannot mix implicit hosts with -h" \
    "yes"

test_case "Cannot mix -H with implicit hosts" \
    "$MUSSH -H /etc/hosts -c 'test' implicit.host 2>&1" \
    "Cannot mix implicit hosts with -h" \
    "yes"

test_case "Cannot mix -c with implicit command" \
    "$MUSSH -c 'command1' host1 'command with spaces' 2>&1" \
    "Cannot mix implicit command with -c" \
    "yes"

test_case "Only one implicit command allowed" \
    "$MUSSH host1 'first command' 'second command' 2>&1" \
    "Only one implicit command allowed" \
    "yes"

echo

# Documentation tests
echo -e "${YELLOW}Documentation Tests:${NC}"
test_case "Usage shows implicit syntax" \
    "$MUSSH --help 2>&1" \
    "\\[-c cmd | -C scriptfile | \"command\"\\]"

test_case "Help mentions implicit hosts" \
    "$MUSSH --help 2>&1" \
    "Hosts can be specified without -h flag"

test_case "Examples show implicit usage" \
    "$MUSSH --help 2>&1" \
    "mussh host1 host2 \"cat /etc/hosts\""

echo
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo "Total tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $((TOTAL_TESTS - PASSED_TESTS))"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi