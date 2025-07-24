#!/bin/bash
#
# Simple direct tests for mussh implicit arguments
#

echo "=== Direct command tests ==="
echo

echo "1. Testing implicit hosts with explicit command:"
../mussh host1 host2 -c "echo test" -d 2>&1 | grep -E "(HOSTLIST|error)"
echo

echo "2. Testing implicit command with double quotes:"
../mussh host1 host2 "echo hello" -d2 2>&1 | grep -E "(THE SCRIPT|error)"
echo

echo "3. Testing safety: mixing -h with implicit host (should fail):"
../mussh -h server1 extrahost -c "test" 2>&1 | grep -E "(Cannot mix|invalid)"
echo

echo "4. Testing safety: mixing -c with implicit command (should fail):"
../mussh -c "cmd1" host1 "cmd2 with space" 2>&1 | grep -E "(Cannot mix|error)"
echo

echo "5. Testing multiple implicit commands (should fail):"
../mussh host1 "cmd one" host2 "cmd two" 2>&1 | grep -E "(Only one|error)"
echo

echo "6. Testing command with options inside:"
../mussh server1 server2 "df -h" -d2 2>&1 | grep "THE SCRIPT" -A2
echo

echo "7. Testing options placement:"
../mussh server1 server2 -m5 -d2 "uptime" 2>&1 | grep -E "(Concurrency:|THE SCRIPT)"
echo

echo "=== Done ==="