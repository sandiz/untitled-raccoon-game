#!/bin/bash
# Run all tests
# Usage: ./tests/run_tests.sh

GODOT="/Users/moonlake/Projects/spatio_monorepo/godot/bin/moonlake_macos_editor.app/Contents/MacOS/Moonlake"
PROJECT_DIR="$(dirname "$0")/.."

cd "$PROJECT_DIR"

total_passed=0
total_failed=0

echo "========================================"
echo "Running All Tests"
echo "========================================"

for test in tests/test_*.gd; do
    echo ""
    "$GODOT" --headless -s "$test" 2>&1 | grep -E "(===|✓|✗|Results)"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        ((total_failed++))
    else
        ((total_passed++))
    fi
done

echo ""
echo "========================================"
echo "Test Suites: $total_passed passed, $total_failed failed"
echo "========================================"

exit $total_failed
