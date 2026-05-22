#!/bin/bash

echo "Updating system test list..."
echo "================================"

# Get list of system tests dynamically
tests=($(find test/system -name "*_test.rb" | sort))

echo "Found ${#tests[@]} system tests"
echo "Running system tests one at a time..."
echo "========================================"

failed_tests=()
passed_tests=()

for test in "${tests[@]}"; do
    echo "Running: $test"
    if rails test "$test"; then
        echo "✓ PASSED: $test"
        passed_tests+=("$test")
    else
        echo "✗ FAILED: $test"
        failed_tests+=("$test")
    fi
    echo "---"
done

echo "========================================"
echo "Test Summary:"
echo "Passed: ${#passed_tests[@]}"
echo "Failed: ${#failed_tests[@]}"

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo ""
    echo "Failed tests:"
    for failed_test in "${failed_tests[@]}"; do
        echo "  - $failed_test"
    done
    exit 1
else
    echo "All system tests passed!"
fi
