#!/bin/bash
#
# Quick performance test for mussh optimizations
#

echo "=== Quick Performance Test ==="

# Test 1: Host counting optimization
echo "Testing host counting performance..."
hosts="host1 host2 host3 host4 host5 host6 host7 host8 host9 host10"

echo -n "Host count processing: "
time_start=$(date +%s.%N)
../mussh -h $hosts -c 'echo test' -d1 2>&1 | grep -q "Concurrency:"
time_end=$(date +%s.%N)
if command -v bc >/dev/null 2>&1; then
    duration=$(echo "scale=3; $time_end - $time_start" | bc)
    echo "${duration}s"
else
    echo "completed"
fi

# Test 2: File operations optimization  
echo "Testing file operations performance..."
echo -e "host1\nhost2\nhost3" > /tmp/test_hosts.txt

echo -n "File processing: "
time_start=$(date +%s.%N)
../mussh -H /tmp/test_hosts.txt -c 'echo test' -d1 2>&1 | grep -q "DEBUG:"
time_end=$(date +%s.%N)
if command -v bc >/dev/null 2>&1; then
    duration=$(echo "scale=3; $time_end - $time_start" | bc)
    echo "${duration}s"
else
    echo "completed"
fi

# Test 3: Concurrent execution
echo "Testing concurrent execution..."
echo -n "Concurrent processing: "
time_start=$(date +%s.%N)
timeout 5 ../mussh -h host1 host2 host3 -c 'echo test' -m3 -d2 >/dev/null 2>&1 || true
time_end=$(date +%s.%N)
if command -v bc >/dev/null 2>&1; then
    duration=$(echo "scale=3; $time_end - $time_start" | bc)
    echo "${duration}s"
else
    echo "completed"
fi

# Cleanup
rm -f /tmp/test_hosts.txt

echo ""
echo "=== Optimization Summary ==="
echo "✓ Replaced external 'cat' calls with bash redirection"
echo "✓ Replaced 'wc' calls with bash parameter expansion"  
echo "✓ Replaced 'head -n 1' with bash 'read'"
echo "✓ Optimized 'tail' operations with bash"
echo "✓ Improved PID file handling for concurrent execution"
echo ""
echo "Benefits: Reduced subprocess overhead, faster execution, better performance"