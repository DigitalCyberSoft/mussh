#!/bin/bash
# Test script for mussh --screen functionality

echo "Testing mussh --screen option..."

# Clean up any existing test screen session
screen -S mussh-session -X quit 2>/dev/null

# Test 1: Basic screen functionality with localhost
echo "Test 1: Basic --screen with single host"
../mussh --screen -h localhost -c "echo 'Hello from screen'"
sleep 2

# Check if screen session was created
if screen -list | grep -q "mussh-session"; then
    echo "✓ Screen session created successfully"
    
    # List windows in the session
    echo "Windows in session:"
    screen -S mussh-session -Q windows
    
    # Clean up
    screen -S mussh-session -X quit
else
    echo "✗ Screen session not found"
fi

echo ""
echo "Test 2: Multiple hosts with --screen"
# Clean up first
screen -S mussh-session -X quit 2>/dev/null

# Test with multiple hosts (using localhost with different names)
../mussh --screen -h localhost -h 127.0.0.1 -c "hostname; echo 'Test from \$HOSTNAME'"
sleep 2

if screen -list | grep -q "mussh-session"; then
    echo "✓ Screen session created for multiple hosts"
    
    # Show session info
    screen -S mussh-session -Q windows
    
    # Clean up
    screen -S mussh-session -X quit
else
    echo "✗ Screen session not found for multiple hosts"
fi

echo ""
echo "Test complete. If successful, you can test manually with:"
echo "  mussh --screen -h host1 -h host2 -c 'your command'"
echo "  screen -r mussh-session"