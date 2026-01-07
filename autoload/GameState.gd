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

# Signals for state changes
signal coins_changed(new_amount: int)
signal inventory_changed(resource_type: String, new_amount: int)
signal buildings_changed()

func _ready() -> void:
	# Connect to WebSocket signals when WebSocketClient is available
	if has_node("/root/WebSocketClient"):
		var ws_client = get_node("/root/WebSocketClient")
		ws_client.state_updated.connect(_on_websocket_state_updated)
		ws_client.production_complete.connect(_on_websocket_production_complete)

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
		var old_coins = coins
		coins = int(str(data.get("coins", "0")))
		if old_coins != coins:
			coins_changed.emit(coins)
	
	if data.has("inventory"):
		var inv = data.get("inventory", {})
		for resource_type in ["water", "wood", "stone", "sand"]:
			var old_amount = inventory.get(resource_type, 0)
			var new_amount = int(str(inv.get(resource_type, "0")))
			inventory[resource_type] = new_amount
			if old_amount != new_amount:
				inventory_changed.emit(resource_type, new_amount)
	
	if data.has("buildings"):
		buildings = data.get("buildings", [])
		buildings_changed.emit()
	
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

func _on_websocket_state_updated(state: Dictionary) -> void:
	## Handle state updates from WebSocket
	print("[GameState] Received state update via WebSocket: ", state.get("type", ""))
	
	# Refresh state from server when notified
	# We could update local state directly, but safer to fetch from server
	# to ensure consistency
	var result = await Api.get_state()
	if result.ok and result.data:
		update_from_server(result.data)

func _on_websocket_production_complete(job: Dictionary) -> void:
	## Handle production completion from WebSocket
	print("[GameState] Production complete: ", job)
	
	# Refresh state to get updated inventory
	var result = await Api.get_state()
	if result.ok and result.data:
		update_from_server(result.data)

