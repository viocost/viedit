#!/usr/bin/env bash

# Run tests for viedit plugin
# Requires plenary.nvim to be installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Run tests
nvim --headless --noplugin -u tests/minimal_init.lua \
    -c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/minimal_init.lua' })"

echo -e "\n${GREEN}Tests completed!${NC}"
