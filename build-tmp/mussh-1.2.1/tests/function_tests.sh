#!/bin/bash
#
# Unit tests for specific optimized functions in mussh
#

# Test the optimized file reading vs cat
test_file_reading() {
    echo "=== Testing File Reading Optimizations ==="
    
    # Create test file
    echo -e "line1\nline2\nline3" > /tmp/test_file.txt
    
    # Test bash redirection vs cat
    echo "Testing $(<file) vs cat file:"
    time_start=$(date +%s.%N)
    for i in {1..100}; do
        content=$(<"/tmp/test_file.txt")
    done
    time_end=$(date +%s.%N)
    if command -v bc >/dev/null 2>&1; then
        bash_time=$(echo "scale=6; $time_end - $time_start" | bc)
        echo "  Bash redirection (100 iterations): ${bash_time}s"
    fi
    
    time_start=$(date +%s.%N)
    for i in {1..100}; do
        content=$(cat "/tmp/test_file.txt")
    done
    time_end=$(date +%s.%N)
    if command -v bc >/dev/null 2>&1; then
        cat_time=$(echo "scale=6; $time_end - $time_start" | bc)
        echo "  Cat command (100 iterations): ${cat_time}s"
        
        # Calculate improvement
        if [ "$bash_time" != "0" ]; then
            improvement=$(echo "scale=2; ($cat_time - $bash_time) / $cat_time * 100" | bc)
            echo "  Performance improvement: ${improvement}%"
        fi
    fi
    
    rm -f /tmp/test_file.txt
}

# Test word counting optimization
test_word_counting() {
    echo -e "\n=== Testing Word Counting Optimizations ==="
    
    test_string="word1 word2 word3 word4 word5"
    
    echo "Testing bash parameter expansion vs wc -w:"
    
    # Test bash method
    time_start=$(date +%s.%N)
    for i in {1..1000}; do
        set -- $test_string
        count=$#
    done
    time_end=$(date +%s.%N)
    if command -v bc >/dev/null 2>&1; then
        bash_time=$(echo "scale=6; $time_end - $time_start" | bc)
        echo "  Bash parameter expansion (1000 iterations): ${bash_time}s"
    fi
    
    # Test wc method  
    time_start=$(date +%s.%N)
    for i in {1..1000}; do
        count=$(echo "$test_string" | wc -w)
    done
    time_end=$(date +%s.%N)
    if command -v bc >/dev/null 2>&1; then
        wc_time=$(echo "scale=6; $time_end - $time_start" | bc)
        echo "  Wc command (1000 iterations): ${wc_time}s"
        
        # Calculate improvement
        if [ "$bash_time" != "0" ]; then
            improvement=$(echo "scale=2; ($wc_time - $bash_time) / $wc_time * 100" | bc)
            echo "  Performance improvement: ${improvement}%"
        fi
    fi
}

# Test line reading optimization
test_line_reading() {
    echo -e "\n=== Testing Line Reading Optimizations ==="
    
    # Create test file
    echo -e "first_line\nsecond_line\nthird_line" > /tmp/test_lines.txt
    
    echo "Testing bash read vs head -n 1:"
    
    # Test bash method
    time_start=$(date +%s.%N)
    for i in {1..1000}; do
        IFS= read -r first_line < "/tmp/test_lines.txt"
    done
    time_end=$(date +%s.%N)
    if command -v bc >/dev/null 2>&1; then
        bash_time=$(echo "scale=6; $time_end - $time_start" | bc)
        echo "  Bash read (1000 iterations): ${bash_time}s"
    fi
    
    # Test head method
    time_start=$(date +%s.%N)
    for i in {1..1000}; do
        first_line=$(head -n 1 "/tmp/test_lines.txt")
    done
    time_end=$(date +%s.%N)
    if command -v bc >/dev/null 2>&1; then
        head_time=$(echo "scale=6; $time_end - $time_start" | bc)
        echo "  Head command (1000 iterations): ${head_time}s"
        
        # Calculate improvement
        if [ "$bash_time" != "0" ]; then
            improvement=$(echo "scale=2; ($head_time - $bash_time) / $head_time * 100" | bc)
            echo "  Performance improvement: ${improvement}%"
        fi
    fi
    
    rm -f /tmp/test_lines.txt
}

# Summary
print_summary() {
    echo -e "\n=== Optimization Summary ==="
    echo "Mussh has been optimized by replacing external commands with bash internals:"
    echo ""
    echo "1. File Reading:"
    echo "   - OLD: \$(cat file) or cat file | command"
    echo "   - NEW: \$(<file) or direct redirection"
    echo ""
    echo "2. Word Counting:"
    echo "   - OLD: echo \$var | wc -w"
    echo "   - NEW: set -- \$var; echo \$#"
    echo ""
    echo "3. Line Counting:" 
    echo "   - OLD: wc -l < file"
    echo "   - NEW: while read loop with counter"
    echo ""
    echo "4. First Line Reading:"
    echo "   - OLD: head -n 1 file"
    echo "   - NEW: IFS= read -r var < file"
    echo ""
    echo "5. PID File Processing:"
    echo "   - OLD: cat \$dir/*.pid"
    echo "   - NEW: for pidfile in \$dir/*.pid; do CPID=\$(<pidfile); done"
    echo ""
    echo "Benefits: Fewer subprocess forks, reduced memory usage, faster execution"
}

main() {
    if ! command -v bc >/dev/null 2>&1; then
        echo "Note: 'bc' not available, performance measurements will be limited"
        echo ""
    fi
    
    test_file_reading
    test_word_counting  
    test_line_reading
    print_summary
}

main "$@"