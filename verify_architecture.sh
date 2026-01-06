#!/bin/bash
# Verification script for architectural improvements

echo "=== Verifying Der-Kapitalist Architectural Improvements ==="
echo ""

# Check directory structure
echo "1. Checking directory structure..."
if [ -d "Scenes/Auth" ] && [ -d "Scenes/Game" ] && [ -d "Scenes/UI" ] && [ -d "Scenes/Common" ]; then
    echo "   ✓ All required directories exist"
else
    echo "   ✗ Missing directories"
    exit 1
fi

# Check for old files
echo ""
echo "2. Checking that old files are removed..."
if [ ! -f "Scenes/Login.tscn" ] && [ ! -f "Scenes/Main.tscn" ] && [ ! -d "Scripts" ]; then
    echo "   ✓ Old files properly removed"
else
    echo "   ✗ Old files still exist"
    exit 1
fi

# Check autoloads
echo ""
echo "3. Checking autoload files..."
if [ -f "autoload/GameState.gd" ] && [ -f "autoload/Api.gd" ] && [ -f "autoload/net.gd" ]; then
    echo "   ✓ All autoload files exist"
else
    echo "   ✗ Missing autoload files"
    exit 1
fi

# Check scene files
echo ""
echo "4. Checking scene files..."
if [ -f "Scenes/Auth/Login.tscn" ] && [ -f "Scenes/Auth/Login.gd" ] && \
   [ -f "Scenes/Game/Main.tscn" ] && [ -f "Scenes/Game/Main.gd" ] && \
   [ -f "Scenes/Common/LoadingOverlay.tscn" ] && [ -f "Scenes/Common/LoadingOverlay.gd" ] && \
   [ -f "Scenes/UI/WalletBar.tscn" ] && [ -f "Scenes/UI/WalletBar.gd" ]; then
    echo "   ✓ All scene files exist"
else
    echo "   ✗ Missing scene files"
    exit 1
fi

# Check documentation
echo ""
echo "5. Checking documentation..."
if [ -f "docs/API.md" ] && [ -f "docs/ARCHITECTURE.md" ] && [ -f "docs/DOCS_INDEX.md" ]; then
    echo "   ✓ Documentation files exist in docs/ folder"
else
    echo "   ✗ Missing documentation"
    exit 1
fi

# Check project.godot
echo ""
echo "6. Checking project.godot configuration..."
if grep -q "res://Scenes/Auth/Login.tscn" project.godot && \
   grep -q "GameState=" project.godot && \
   grep -q "Api=" project.godot; then
    echo "   ✓ project.godot properly configured"
else
    echo "   ✗ project.godot not properly configured"
    exit 1
fi

# Check script references
echo ""
echo "7. Checking scene script references..."
if grep -q "res://Scenes/Auth/Login.gd" Scenes/Auth/Login.tscn && \
   grep -q "res://Scenes/Game/Main.gd" Scenes/Game/Main.tscn && \
   grep -q "res://Scenes/Common/LoadingOverlay.gd" Scenes/Common/LoadingOverlay.tscn && \
   grep -q "res://Scenes/UI/WalletBar.gd" Scenes/UI/WalletBar.tscn; then
    echo "   ✓ All scene script references are correct"
else
    echo "   ✗ Scene script references are incorrect"
    exit 1
fi

# Check for Api usage in scripts
echo ""
echo "8. Checking Api usage in refactored scripts..."
if grep -q "Api\." Scenes/Auth/Login.gd && \
   grep -q "Api\." Scenes/Game/Main.gd && \
   grep -q "GameState\." Scenes/Auth/Login.gd && \
   grep -q "GameState\." Scenes/Game/Main.gd; then
    echo "   ✓ Scripts use new Api and GameState"
else
    echo "   ✗ Scripts don't properly use Api and GameState"
    exit 1
fi

echo ""
echo "=== All Checks Passed! ✓ ==="
echo ""
echo "Summary of Improvements:"
echo "  • Organized structure: Auth, Game, UI, Common"
echo "  • Global state management via GameState"
echo "  • Clean API layer via Api autoload"
echo "  • Modular UI components (WalletBar, LoadingOverlay)"
echo "  • Complete API documentation"
echo "  • Architecture documentation"
echo ""
echo "Next steps:"
echo "  • Test in Godot editor"
echo "  • Start backend server and test login flow"
echo "  • Verify all game functionality works"
