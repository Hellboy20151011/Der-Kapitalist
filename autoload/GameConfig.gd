extends Node
## GameConfig - Centralized Game Configuration
##
## This autoload provides centralized access to game constants and configuration.
## Extracted from Main.gd as part of Phase 2 refactoring to improve modularity.
##
## Usage: GameConfig.PRODUCTION_COSTS["well"]

# ============================================================================
# PRODUCTION CONFIGURATION
# ============================================================================

## Production costs in coins per unit (must match backend CONFIG)
const PRODUCTION_COSTS = {
	"well": 1,
	"lumberjack": 2,
	"sandgrube": 3
}

# ============================================================================
# UI CONFIGURATION
# ============================================================================

## Timeout for status messages in seconds
const STATUS_MESSAGE_TIMEOUT = 5.0

## Resource type icons for display
const RESOURCE_ICONS = {
	"water": "💧",
	"wood": "🪓", 
	"stone": "🪨",
	"sand": "🏖️"
}

## Resource type display names (German)
const RESOURCE_NAMES = {
	"water": "Wasser",
	"wood": "Holz",
	"stone": "Stein",
	"sand": "Sand"
}

## List of all resource types
const RESOURCE_TYPES = ["water", "wood", "stone", "sand"]

# ============================================================================
# BUILDING CONFIGURATION
# ============================================================================

## Building type display names (German)
const BUILDING_NAMES = {
	"well": "Brunnen",
	"lumberjack": "Holzfäller",
	"sandgrube": "Sandgrube"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Get resource icon for display
func get_resource_icon(resource_type: String) -> String:
	return RESOURCE_ICONS.get(resource_type, "📦")

## Get resource display name
func get_resource_name(resource_type: String) -> String:
	return RESOURCE_NAMES.get(resource_type, resource_type)

## Get building display name
func get_building_name(building_type: String) -> String:
	return BUILDING_NAMES.get(building_type, building_type)

## Get production cost for a building type
func get_production_cost(building_type: String) -> int:
	return PRODUCTION_COSTS.get(building_type, 0)
