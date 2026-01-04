extends HBoxContainer
class_name WalletBar

@onready var coins_label: Label = $CoinsLabel
@onready var water_label: Label = $WaterLabel
@onready var wood_label: Label = $WoodLabel
@onready var stone_label: Label = $StoneLabel

func update_coins(coins: int) -> void:
	coins_label.text = "💰 %d" % coins

func update_resources(water: int, wood: int, stone: int, sand: int = 0) -> void:
	water_label.text = "💧 %d" % water
	wood_label.text = "🪓 %d" % wood
	stone_label.text = "🪨 %d" % stone

func update_from_state() -> void:
	## Update UI from GameState
	update_coins(GameState.coins)
	update_resources(
		GameState.inventory.get("water", 0),
		GameState.inventory.get("wood", 0),
		GameState.inventory.get("stone", 0),
		GameState.inventory.get("sand", 0)
	)
