#!/bin/bash
# Manual Verification Script for Production System
# This script helps verify the implementation by checking key files

echo "=== Production System Implementation Verification ==="
echo ""

echo "1. Checking database migration file..."
if [ -f "backend/migrations/002_add_building_production_columns.sql" ]; then
    echo "   ✓ Migration file exists"
    echo "   Content preview:"
    head -5 "backend/migrations/002_add_building_production_columns.sql" | sed 's/^/     /'
else
    echo "   ✗ Migration file missing"
fi
echo ""

echo "2. Checking production route..."
if [ -f "backend/src/routes/production.js" ]; then
    echo "   ✓ Production route exists"
    echo "   Endpoints:"
    grep -E "router\.(post|get)" "backend/src/routes/production.js" | sed 's/^/     /'
else
    echo "   ✗ Production route missing"
fi
echo ""

echo "3. Checking app.js integration..."
if grep -q "productionRouter" "backend/src/app.js"; then
    echo "   ✓ Production router imported and registered"
else
    echo "   ✗ Production router not integrated"
fi
echo ""

echo "4. Checking state.js updates..."
if grep -q "is_producing" "backend/src/routes/state.js"; then
    echo "   ✓ State endpoint includes production status"
else
    echo "   ✗ State endpoint not updated"
fi
echo ""

echo "5. Checking Godot client updates..."
if [ -f "Scripts/Main.gd" ]; then
    if grep -q "_parse_iso_time" "Scripts/Main.gd" && grep -q "well_producing" "Scripts/Main.gd"; then
        echo "   ✓ Godot client updated with production logic"
    else
        echo "   ✗ Godot client missing production logic"
    fi
else
    echo "   ✗ Main.gd not found"
fi
echo ""

echo "6. Checking for syntax errors..."
cd backend/src/routes
node --check production.js 2>/dev/null && echo "   ✓ production.js: No syntax errors" || echo "   ✗ production.js: Syntax errors found"
node --check state.js 2>/dev/null && echo "   ✓ state.js: No syntax errors" || echo "   ✗ state.js: Syntax errors found"
cd ../../..
node --check backend/src/app.js 2>/dev/null && echo "   ✓ app.js: No syntax errors" || echo "   ✗ app.js: Syntax errors found"
echo ""

echo "7. Documentation check..."
if [ -f "PRODUCTION_MIGRATION.md" ]; then
    echo "   ✓ Migration guide exists"
else
    echo "   ✗ Migration guide missing"
fi
echo ""

echo "=== Verification Complete ==="
echo ""
echo "Next steps:"
echo "1. Apply database migration: psql -d der_kapitalist -f backend/migrations/002_add_building_production_columns.sql"
echo "2. Restart backend server: cd backend && npm start"
echo "3. Test in Godot client or via curl:"
echo "   curl -X POST http://localhost:3000/production/start \\"
echo "     -H 'Authorization: Bearer <token>' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"building_type\": \"well\", \"quantity\": 1}'"
