#!/bin/bash
#
# Performance comparison test for mussh optimizations
# Creates a test scenario to measure the impact of bash internal optimizations
#

# Create a test hostfile with many hosts
create_large_hostfile() {
    local hostfile="$1"
    local count="$2"
    
    echo "# Large host file for performance testing" > "$hostfile"
    for i in $(seq 1 "$count"); do
        echo "host$i.example.com" >> "$hostfile"
    done
}

# Test host list processing performance
test_host_processing() {
    local hostfile="/tmp/perf_hosts.txt"
    local host_count=500
    
    echo "Creating hostfile with $host_count hosts..."
    create_large_hostfile "$hostfile" "$host_count"
    
    echo "Testing host list processing performance..."
    
    # Test 1: Host file reading and processing
    echo -n "Host file processing (500 hosts): "
    time_start=$(date +%s.%N)
    ../mussh -H "$hostfile" -c 'echo test' -d1 >/dev/null 2>&1 || true
    time_end=$(date +%s.%N)
    duration=$(echo "$time_end - $time_start" | bc -l 2>/dev/null || echo "N/A")
    echo "${duration}s"
    
    # Test 2: Multiple individual hosts
    echo -n "Individual host processing (10 hosts): "
    time_start=$(date +%s.%N)
    ../mussh -h host1 host2 host3 host4 host5 host6 host7 host8 host9 host10 -c 'echo test' -d1 >/dev/null 2>&1 || true
    time_end=$(date +%s.%N)
    duration=$(echo "$time_end - $time_start" | bc -l 2>/dev/null || echo "N/A")
    echo "${duration}s"
    
    rm -f "$hostfile"
}

# Test concurrent execution performance
test_concurrent_performance() {
    echo "Testing concurrent execution performance..."
    
    # Test sequential vs concurrent execution
    echo -n "Sequential execution (5 hosts): "
    time_start=$(date +%s.%N)
    timeout 10 ../mussh -h host1 host2 host3 host4 host5 -c 'sleep 0.1; echo test' -m1 -d1 >/dev/null 2>&1 || true
    time_end=$(date +%s.%N)
    duration=$(echo "$time_end - $time_start" | bc -l 2>/dev/null || echo "N/A")
    echo "${duration}s"
    
    echo -n "Concurrent execution (5 hosts, -m5): "
    time_start=$(date +%s.%N)
    timeout 10 ../mussh -h host1 host2 host3 host4 host5 -c 'sleep 0.1; echo test' -m5 -d1 >/dev/null 2>&1 || true
    time_end=$(date +%s.%N)
    duration=$(echo "$time_end - $time_start" | bc -l 2>/dev/null || echo "N/A")
    echo "${duration}s"
}

# Test file operations performance
test_file_performance() {
    echo "Testing file operations performance..."
    
    # Create a large script file
    local scriptfile="/tmp/perf_script.sh"
    echo "#!/bin/bash" > "$scriptfile"
    for i in {1..100}; do
        echo "echo 'Line $i of test script'" >> "$scriptfile"
    done
    
    echo -n "Large script file processing: "
    time_start=$(date +%s.%N)
    ../mussh -h host1 -C "$scriptfile" -d1 >/dev/null 2>&1 || true
    time_end=$(date +%s.%N)
    duration=$(echo "$time_end - $time_start" | bc -l 2>/dev/null || echo "N/A")
    echo "${duration}s"
    
    rm -f "$scriptfile"
}

# Test memory usage (approximate)
test_memory_usage() {
    echo "Testing memory usage..."
    
    # Create a very large hostfile
    local hostfile="/tmp/memory_test_hosts.txt"
    create_large_hostfile "$hostfile" 1000
    
    echo -n "Memory test (1000 hosts): "
    # Use /usr/bin/time if available to get memory stats
    if command -v /usr/bin/time >/dev/null 2>&1; then
        /usr/bin/time -f "Max RSS: %M KB, Time: %e s" \
            ../mussh -H "$hostfile" -c 'echo test' -d1 >/dev/null 2>&1 || true
    else
        echo "time command not available for memory measurement"
    fi
    
    rm -f "$hostfile"
}

main() {
    echo "=== Performance Testing for Optimized mussh ==="
    echo "Note: SSH connection failures are expected and ignored for timing purposes"
    echo ""
    
    # Check if bc is available for time calculations
    if ! command -v bc >/dev/null 2>&1; then
        echo "Warning: 'bc' not available, timing may show as N/A"
    fi
    
    test_host_processing
    echo ""
    test_concurrent_performance
    echo ""
    test_file_performance
    echo ""
    test_memory_usage
    
    echo ""
    echo "=== Performance Test Summary ==="
    echo "The optimized functions should show:"
    echo "- Faster host list processing due to bash internals vs external commands"
    echo "- Better concurrent execution due to optimized PID file handling"  
    echo "- Reduced memory footprint from fewer subprocess spawns"
    echo "- Overall improved responsiveness"
}

main "$@"