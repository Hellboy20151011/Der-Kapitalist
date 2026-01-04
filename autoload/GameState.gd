extends Node
# Note: This is an autoload and globally accessible as 'GameState'
# Do not use class_name with autoloads in Godot 4.5+

# Authentication state
var token: String = ""
var player_id: int = -1

# Player state
var coins: int = 0
var company_name: String = ""

# Inventory - resource_type -> amount
var inventory: Dictionary = {
	"water": 0,
	"wood": 0,
	"stone": 0,
	"sand": 0
}

# Buildings - Array of building dictionaries
var buildings: Array = []

# Server time
var server_time: String = ""

## Reset all state to defaults (e.g., on logout)
func reset() -> void:
	token = ""
	player_id = -1
	coins = 0
	company_name = ""
	inventory = {
		"water": 0,
		"wood": 0,
		"stone": 0,
		"sand": 0
	}
	buildings = []
	server_time = ""

func update_from_server(data: Dictionary) -> void:
	## Update state from server response
	if data.has("coins"):
		coins = int(str(data.get("coins", "0")))
	
	if data.has("inventory"):
		var inv = data.get("inventory", {})
		inventory["water"] = int(str(inv.get("water", "0")))
		inventory["wood"] = int(str(inv.get("wood", "0")))
		inventory["stone"] = int(str(inv.get("stone", "0")))
		inventory["sand"] = int(str(inv.get("sand", "0")))
	
	if data.has("buildings"):
		buildings = data.get("buildings", [])
	
	if data.has("server_time"):
		server_time = str(data.get("server_time", ""))

func has_building(building_type: String) -> bool:
	## Check if player owns a specific building type
	for building in buildings:
		if building.get("type", "") == building_type:
			return true
	return false

func get_building(building_type: String) -> Dictionary:
	## Get building data for a specific type
	for building in buildings:
		if building.get("type", "") == building_type:
			return building
	return {}
