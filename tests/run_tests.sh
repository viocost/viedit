#!/usr/bin/env bash

# Run tests for viedit plugin
# Requires plenary.nvim to be installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running viedit tests...${NC}\n"

# Check if plenary is installed
PLENARY_PATH="$HOME/.local/share/nvim/lazy/plenary.nvim"
if [ ! -d "$PLENARY_PATH" ]; then
    echo -e "${RED}Error: plenary.nvim not found at $PLENARY_PATH${NC}"
    echo "Please install plenary.nvim first:"
    echo "  Lazy.nvim: Add 'nvim-lua/plenary.nvim' to your plugins"
    echo "  Packer: use 'nvim-lua/plenary.nvim'"
    exit 1
fi

# Create temporary file to capture output
TEMP_OUTPUT=$(mktemp)

# Run tests and capture output
set +e  # Temporarily disable exit on error to capture exit code
nvim --headless --noplugin -u tests/minimal_init.lua \
    -c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/minimal_init.lua' })" \
    2>&1 | tee "$TEMP_OUTPUT"
TEST_EXIT_CODE=$?
set -e

# Parse results
total_success=0
total_failed=0
total_errors=0
suites_passed=0
suites_failed=0

# Track per-suite results
suite_failed=0
suite_errors=0

while IFS= read -r line; do
    # Strip ANSI color codes
    line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ $line =~ ^Success:[[:space:]]+([0-9]+) ]]; then
        success="${BASH_REMATCH[1]}"
        total_success=$((total_success + success))
        suite_failed=0
        suite_errors=0
    elif [[ $line =~ ^Failed[[:space:]]+:[[:space:]]+([0-9]+) ]]; then
        failed="${BASH_REMATCH[1]}"
        total_failed=$((total_failed + failed))
        suite_failed=$failed
    elif [[ $line =~ ^Errors[[:space:]]+:[[:space:]]+([0-9]+) ]]; then
        errors="${BASH_REMATCH[1]}"
        total_errors=$((total_errors + errors))
        suite_errors=$errors
        
        # Count suite as passed or failed (after we've seen all three: Success, Failed, Errors)
        if [[ $suite_failed -eq 0 && $suite_errors -eq 0 ]]; then
            suites_passed=$((suites_passed + 1))
        else
            suites_failed=$((suites_failed + 1))
        fi
    fi
done < "$TEMP_OUTPUT"

# Print summary
echo ""
echo -e "${BOLD}${CYAN}========================================${NC}"
echo -e "${BOLD}${CYAN}           TEST SUMMARY${NC}"
echo -e "${BOLD}${CYAN}========================================${NC}"
if [[ $total_failed -eq 0 && $total_errors -eq 0 ]]; then
    echo -e "${GREEN}Total Tests Passed:   $total_success${NC}"
    echo -e "${GREEN}Total Tests Failed:   $total_failed${NC}"
    echo -e "${GREEN}Total Errors:         $total_errors${NC}"
    echo -e "${GREEN}Total Suites Passed:  $suites_passed${NC}"
    echo -e "${GREEN}Total Suites Failed:  $suites_failed${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${GREEN}ALL TESTS PASSED!${NC}"
else
    echo -e "${GREEN}Total Tests Passed:   $total_success${NC}"
    echo -e "${RED}Total Tests Failed:   $total_failed${NC}"
    echo -e "${RED}Total Errors:         $total_errors${NC}"
    echo -e "${GREEN}Total Suites Passed:  $suites_passed${NC}"
    echo -e "${RED}Total Suites Failed:  $suites_failed${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${RED}SOME TESTS FAILED!${NC}"
fi

# Cleanup
rm -f "$TEMP_OUTPUT"

# Exit with error if any tests failed
if [[ $total_failed -gt 0 || $total_errors -gt 0 ]]; then
    exit 1
fi
