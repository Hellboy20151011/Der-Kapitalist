extends Control

@onready var coins_label: Label = $RootPanel/Margin/VBox/TopBar/CoinsLabel
@onready var sync_btn: Button = $RootPanel/Margin/VBox/TopBar/SyncButton
@onready var logout_btn: Button = $RootPanel/Margin/VBox/TopBar/LogoutButton

@onready var water_value: Label = $RootPanel/Margin/VBox/InventoryGrid/WaterValue
@onready var wood_value: Label  = $RootPanel/Margin/VBox/InventoryGrid/WoodValue
@onready var stone_value: Label = $RootPanel/Margin/VBox/InventoryGrid/StoneValue

@onready var upgrade_well_btn: Button = $RootPanel/Margin/VBox/BuildingButtons/UpgradeWellButton
@onready var upgrade_lumber_btn: Button = $RootPanel/Margin/VBox/BuildingButtons/UpgradeLumberButton
@onready var upgrade_stone_btn: Button = $RootPanel/Margin/VBox/BuildingButtons/UpgradeStoneButton

@onready var build_well_btn: Button = $RootPanel/Margin/VBox/BuildButtons/BuildWellButton
@onready var build_lumber_btn: Button = $RootPanel/Margin/VBox/BuildButtons/BuildLumberButton
@onready var build_stone_btn: Button = $RootPanel/Margin/VBox/BuildButtons/BuildStoneButton

@onready var well_slider: HSlider = $RootPanel/Margin/VBox/Production/WellProduction/WellSlider
@onready var well_produce_btn: Button = $RootPanel/Margin/VBox/Production/WellProduction/WellProduceButton
@onready var well_qty_label: Label = $RootPanel/Margin/VBox/Production/WellProduction/WellQtyLabel

@onready var lumber_slider: HSlider = $RootPanel/Margin/VBox/Production/LumberProduction/LumberSlider
@onready var lumber_produce_btn: Button = $RootPanel/Margin/VBox/Production/LumberProduction/LumberProduceButton
@onready var lumber_qty_label: Label = $RootPanel/Margin/VBox/Production/LumberProduction/LumberQtyLabel

@onready var stone_slider: HSlider = $RootPanel/Margin/VBox/Production/StoneProduction/StoneSlider
@onready var stone_produce_btn: Button = $RootPanel/Margin/VBox/Production/StoneProduction/StoneProduceButton
@onready var stone_qty_label: Label = $RootPanel/Margin/VBox/Production/StoneProduction/StoneQtyLabel

@onready var sell_water_btn: Button = $RootPanel/Margin/VBox/SellButtons/SellWater10
@onready var sell_wood_btn: Button  = $RootPanel/Margin/VBox/SellButtons/SellWood10
@onready var sell_stone_btn: Button = $RootPanel/Margin/VBox/SellButtons/SellStone10

@onready var status_label: Label = $RootPanel/Margin/VBox/StatusLabel

var poll_timer: Timer
var has_well := false
var has_lumberjack := false
var has_stonemason := false

func _ready() -> void:
	status_label.text = ""

	sync_btn.pressed.connect(_sync_state)
	logout_btn.pressed.connect(_logout)

	upgrade_well_btn.pressed.connect(func(): await _upgrade("well"))
	upgrade_lumber_btn.pressed.connect(func(): await _upgrade("lumberjack"))
	upgrade_stone_btn.pressed.connect(func(): await _upgrade("stonemason"))

	build_well_btn.pressed.connect(func(): await _build("well"))
	build_lumber_btn.pressed.connect(func(): await _build("lumberjack"))
	build_stone_btn.pressed.connect(func(): await _build("stonemason"))

	well_slider.value_changed.connect(func(val): well_qty_label.text = str(int(val)))
	lumber_slider.value_changed.connect(func(val): lumber_qty_label.text = str(int(val)))
	stone_slider.value_changed.connect(func(val): stone_qty_label.text = str(int(val)))

	well_produce_btn.pressed.connect(func(): await _produce("well", int(well_slider.value)))
	lumber_produce_btn.pressed.connect(func(): await _produce("lumberjack", int(lumber_slider.value)))
	stone_produce_btn.pressed.connect(func(): await _produce("stonemason", int(stone_slider.value)))

	sell_water_btn.pressed.connect(func(): await _sell("water", 10))
	sell_wood_btn.pressed.connect(func(): await _sell("wood", 10))
	sell_stone_btn.pressed.connect(func(): await _sell("stone", 10))

	# Polling alle 5 Sekunden für Produktionsstatus
	poll_timer = Timer.new()
	poll_timer.wait_time = 5.0
	poll_timer.autostart = true
	poll_timer.timeout.connect(_poll_production)
	add_child(poll_timer)

	# Direkt nach Start syncen
	await _sync_state()

func _set_status(msg: String) -> void:
	status_label.text = msg

func _sync_state() -> void:
	if Net.token == "":
		_set_status("Nicht eingeloggt.")
		return

	var res := await Net.get_json("/state")
	if not res.ok:
		_set_status("Sync Fehler: %s" % _error_string(res))
		return

	var s = res.data
	# Backend liefert coins/inventory als String (BigInt-safe)
	coins_label.text = "Coins: %s" % str(s.get("coins", "0"))

	var inv = s.get("inventory", {})
	water_value.text = str(inv.get("water", "0"))
	wood_value.text  = str(inv.get("wood", "0"))
	stone_value.text = str(inv.get("stone", "0"))

	# Check which buildings the player has
	var buildings = s.get("buildings", [])
	has_well = false
	has_lumberjack = false
	has_stonemason = false
	
	for b in buildings:
		if b.type == "well":
			has_well = true
		elif b.type == "lumberjack":
			has_lumberjack = true
		elif b.type == "stonemason":
			has_stonemason = true
	
	# Update UI based on owned buildings
	_update_building_ui()

	_set_status("Sync ok (%s)" % str(s.get("server_time", "")))

func _upgrade(building_type: String) -> void:
	var res := await Net.post_json("/economy/buildings/upgrade", {"building_type": building_type})
	if not res.ok:
		_set_status("Upgrade fehlgeschlagen: %s" % _error_string(res))
		return
	await _sync_state()

func _sell(resource_type: String, qty: int) -> void:
	var res := await Net.post_json("/economy/sell", {"resource_type": resource_type, "quantity": qty})
	if not res.ok:
		_set_status("Verkauf fehlgeschlagen: %s" % _error_string(res))
		return
	await _sync_state()

func _logout() -> void:
	Net.token = ""
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _error_string(res: Dictionary) -> String:
	if res.has("data") and typeof(res.data) == TYPE_DICTIONARY and res.data.has("error"):
		return str(res.data.error)
	if res.has("code"):
		return "HTTP %s" % str(res.code)
	return "unbekannt"

func _update_building_ui() -> void:
	# Enable/disable build buttons based on ownership
	build_well_btn.disabled = has_well
	build_lumber_btn.disabled = has_lumberjack
	build_stone_btn.disabled = has_stonemason
	
	# Enable/disable upgrade buttons based on ownership
	upgrade_well_btn.disabled = not has_well
	upgrade_lumber_btn.disabled = not has_lumberjack
	upgrade_stone_btn.disabled = not has_stonemason
	
	# Enable/disable production controls based on ownership
	well_slider.editable = has_well
	well_produce_btn.disabled = not has_well
	lumber_slider.editable = has_lumberjack
	lumber_produce_btn.disabled = not has_lumberjack
	stone_slider.editable = has_stonemason
	stone_produce_btn.disabled = not has_stonemason

func _build(building_type: String) -> void:
	var res := await Net.post_json("/economy/buildings/build", {"building_type": building_type})
	if not res.ok:
		_set_status("Bau fehlgeschlagen: %s" % _error_string(res))
		return
	_set_status("Gebäude gebaut!")
	await _sync_state()

func _produce(building_type: String, quantity: int) -> void:
	if quantity <= 0:
		_set_status("Bitte Menge auswählen")
		return
	
	var res := await Net.post_json("/economy/production/start", {"building_type": building_type, "quantity": quantity})
	if not res.ok:
		_set_status("Produktion fehlgeschlagen: %s" % _error_string(res))
		return
	_set_status("Produktion gestartet!")
	await _sync_state()

func _poll_production() -> void:
	if Net.token == "":
		return
	
	var res := await Net.get_json("/economy/production/status")
	if res.ok and res.data.has("in_progress"):
		# Only sync state if there are productions (to collect completed ones)
		var in_progress = res.data.get("in_progress", [])
		if in_progress.size() > 0:
			await _sync_state()