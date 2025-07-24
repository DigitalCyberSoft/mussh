#!/usr/bin/env bash
#
# Security validation tests for mussh
# Tests the security hardening features
#
# Usage: test_security.sh [hostname]
#   hostname: Test hostname to use (default: testhost)
#
# Example: ./test_security.sh your-test-host.example.com

set -euo pipefail

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
MUSSH_PATH="$SCRIPT_DIR/../mussh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
run_test() {
    local test_name="$1"
    local expected_result="$2"  # "pass" or "fail"
    shift 2
    local command=("$@")
    
    echo -n "Testing: $test_name ... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if "${command[@]}" >/dev/null 2>&1; then
        result="pass"
    else
        result="fail"
    fi
    
    if [[ "$result" == "$expected_result" ]]; then
        echo -e "${GREEN}✓${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} (expected $expected_result, got $result)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_hostname_validation() {
    local test_hostname="$1"
    echo "=== Testing Hostname Validation ==="
    
    # Valid hostnames should pass
    run_test "Valid hostname" "pass" "$MUSSH_PATH" --security-strict -h "$test_hostname" -c "echo test"
    run_test "Valid user@host" "pass" "$MUSSH_PATH" --security-strict -h "user@$test_hostname" -c "echo test"
    run_test "Valid IP address" "pass" "$MUSSH_PATH" --security-strict -h "192.168.1.1" -c "echo test"
    
    # Invalid/dangerous hostnames should fail in strict mode
    run_test "Hostname with semicolon" "fail" "$MUSSH_PATH" --security-strict -h "server;evil" -c "echo test"
    run_test "Hostname with pipe" "fail" "$MUSSH_PATH" --security-strict -h "server|evil" -c "echo test"
    run_test "Hostname with backtick" "fail" "$MUSSH_PATH" --security-strict -h "server\`evil\`" -c "echo test"
    run_test "Hostname with dollar" "fail" "$MUSSH_PATH" --security-strict -h "server\$evil" -c "echo test"
    
    # Same dangerous hostnames should pass with --force-unsafe
    run_test "Dangerous hostname with override" "pass" "$MUSSH_PATH" --force-unsafe -h "server;evil" -c "echo test"
}

test_ssh_option_validation() {
    local test_hostname="$1"
    echo "=== Testing SSH Option Validation ==="
    
    # Valid SSH options should pass
    run_test "Valid BatchMode option" "pass" "$MUSSH_PATH" --security-strict -h "$test_hostname" -o "BatchMode=yes" -c "echo test"
    run_test "Valid ConnectTimeout option" "pass" "$MUSSH_PATH" --security-strict -h "$test_hostname" -o "ConnectTimeout=10" -c "echo test"
    run_test "Valid Port option" "pass" "$MUSSH_PATH" --security-strict -h "$test_hostname" -o "Port=2222" -c "echo test"
    
    # Invalid SSH options should fail in strict mode
    run_test "Invalid SSH option" "fail" "$MUSSH_PATH" --security-strict -h "$test_hostname" -o "EvilOption=yes" -c "echo test"
    run_test "SSH option with injection" "fail" "$MUSSH_PATH" --security-strict -h "$test_hostname" -o "BatchMode=yes;evil" -c "echo test"
    
    # Invalid options should pass with --force-unsafe
    run_test "Invalid option with override" "pass" "$MUSSH_PATH" --force-unsafe -h "$test_hostname" -o "EvilOption=yes" -c "echo test"
}

test_command_validation() {
    local test_hostname="$1"
    echo "=== Testing Command Validation ==="
    
    # Safe commands should pass
    run_test "Safe command" "pass" "$MUSSH_PATH" --security-strict -h "$test_hostname" -c "uptime"
    run_test "Safe piped command" "pass" "$MUSSH_PATH" --security-strict -h "$test_hostname" -c "ps aux | grep nginx"
    
    # Dangerous commands should fail in strict mode
    run_test "Dangerous rm command" "fail" "$MUSSH_PATH" --security-strict -h "$test_hostname" -c "rm -rf /important"
    run_test "Dangerous sudo rm" "fail" "$MUSSH_PATH" --security-strict -h "$test_hostname" -c "sudo rm /etc/passwd"
    run_test "Dangerous mkfs" "fail" "$MUSSH_PATH" --security-strict -h "$test_hostname" -c "mkfs.ext4 /dev/sda"
    
    # Dangerous commands should pass with --force-unsafe
    run_test "Dangerous command with override" "pass" "$MUSSH_PATH" --force-unsafe -h "$test_hostname" -c "rm -rf /tmp/test"
}

test_security_modes() {
    local test_hostname="$1"
    echo "=== Testing Security Modes ==="
    
    # Test different security modes
    run_test "Strict mode rejects dangerous input" "fail" "$MUSSH_PATH" --security-strict -h "server;evil" -c "echo test"
    run_test "Normal mode allows with warning" "pass" "$MUSSH_PATH" --security-normal -h "$test_hostname" -c "echo test"
    run_test "Unsafe mode allows everything" "pass" "$MUSSH_PATH" --force-unsafe -h "server;test" -c "echo test"
}

test_jump_host_validation() {
    local test_hostname="$1"
    echo "=== Testing Jump Host Validation ==="
    
    # Valid jump hosts should pass
    run_test "Valid jump host" "pass" "$MUSSH_PATH" --security-strict -h "$test_hostname" -J "$test_hostname" -c "echo test"
    
    # Invalid jump hosts should fail
    run_test "Invalid jump host" "fail" "$MUSSH_PATH" --security-strict -h "$test_hostname" -J "jump;evil" -c "echo test"
}

# Mock SSH to avoid actual connections during tests
create_mock_ssh() {
    local mock_ssh_dir
    mock_ssh_dir=$(mktemp -d)
    
    cat > "$mock_ssh_dir/ssh" << 'EOF'
#!/bin/bash
# Mock SSH that just validates arguments and exits
echo "Mock SSH called with: $*" >&2
exit 0
EOF
    
    chmod +x "$mock_ssh_dir/ssh"
    export PATH="$mock_ssh_dir:$PATH"
    
    # Return the temp dir for cleanup
    echo "$mock_ssh_dir"
}

# Main test execution
main() {
    local test_hostname="${1:-testhost}"
    
    echo "Starting mussh security validation tests..."
    echo "mussh path: $MUSSH_PATH"
    echo "Test hostname: $test_hostname"
    echo
    
    # Create mock SSH to avoid actual connections
    MOCK_SSH_DIR=$(create_mock_ssh)
    
    # Ensure cleanup happens
    trap "rm -rf '$MOCK_SSH_DIR'" EXIT
    
    # Run all test suites
    test_hostname_validation "$test_hostname"
    echo
    test_ssh_option_validation "$test_hostname"
    echo
    test_command_validation "$test_hostname"
    echo
    test_security_modes "$test_hostname"
    echo
    test_jump_host_validation "$test_hostname"
    echo
    
    # Print summary
    echo "=== Test Summary ==="
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    else
        echo -e "Tests failed: $TESTS_FAILED"
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All security tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some security tests failed!${NC}"
        exit 1
    fi
}

# Check if mussh script exists
if [[ ! -x "$MUSSH_PATH" ]]; then
    echo "Error: mussh script not found or not executable at $MUSSH_PATH"
    exit 1
fi

main "$@"