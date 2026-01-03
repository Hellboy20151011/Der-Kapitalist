extends Control

# New UI references
@onready var company_label: Label = $VBoxMain/HeaderBar/HeaderContent/HBox/LeftInfo/CompanyLabel
@onready var stats_line1: Label = $VBoxMain/HeaderBar/HeaderContent/HBox/LeftInfo/StatsLine1
@onready var stats_line2: Label = $VBoxMain/HeaderBar/HeaderContent/HBox/LeftInfo/StatsLine2
@onready var stats_line3: Label = $VBoxMain/HeaderBar/HeaderContent/HBox/LeftInfo/StatsLine3
@onready var logout_btn: Button = $VBoxMain/HeaderBar/HeaderContent/HBox/RightButtons/LogoutButton
@onready var stats_btn: Button = $VBoxMain/HeaderBar/HeaderContent/HBox/RightButtons/StatsButton
@onready var buildings_btn: Button = $VBoxMain/HeaderBar/HeaderContent/HBox/RightButtons/BuildingsButton
@onready var production_btn: Button = $VBoxMain/HeaderBar/HeaderContent/HBox/RightButtons/ProductionButton
@onready var help_btn: Button = $VBoxMain/HeaderBar/HeaderContent/HBox/RightButtons/HelpButton

@onready var building_selector: OptionButton = $VBoxMain/GameArea/BuildingSelector/SelectorMargin/BuildingOption
@onready var building_info_dialog: PanelContainer = $VBoxMain/GameArea/BuildingInfoDialog
@onready var dialog_title: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/TitleLabel
@onready var dialog_desc: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/DescLabel
@onready var dialog_info: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/InfoLabel
@onready var dialog_action: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/ActionLabel
@onready var dialog_close_btn: Button = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/CloseButton

@onready var home_icon: Button = $VBoxMain/GameArea/BuildingIconBar/HomeIcon
@onready var well_icon: Button = $VBoxMain/GameArea/BuildingIconBar/WellIcon
@onready var lumber_icon: Button = $VBoxMain/GameArea/BuildingIconBar/LumberIcon
@onready var stone_icon: Button = $VBoxMain/GameArea/BuildingIconBar/StoneIcon

@onready var status_label: Label = $VBoxMain/BottomPanel/BottomContent/StatusLabel

# Legacy UI references
@onready var coins_label: Label = $LegacyUI/RootPanel/Margin/VBox/TopBar/CoinsLabel
@onready var sync_btn: Button = $LegacyUI/RootPanel/Margin/VBox/TopBar/SyncButton

@onready var water_value: Label = $LegacyUI/RootPanel/Margin/VBox/InventoryGrid/WaterValue
@onready var wood_value: Label  = $LegacyUI/RootPanel/Margin/VBox/InventoryGrid/WoodValue
@onready var stone_value: Label = $LegacyUI/RootPanel/Margin/VBox/InventoryGrid/StoneValue

@onready var upgrade_well_btn: Button = $LegacyUI/RootPanel/Margin/VBox/BuildingButtons/UpgradeWellButton
@onready var upgrade_lumber_btn: Button = $LegacyUI/RootPanel/Margin/VBox/BuildingButtons/UpgradeLumberButton
@onready var upgrade_stone_btn: Button = $LegacyUI/RootPanel/Margin/VBox/BuildingButtons/UpgradeStoneButton

@onready var build_well_btn: Button = $LegacyUI/RootPanel/Margin/VBox/BuildButtons/BuildWellButton
@onready var build_lumber_btn: Button = $LegacyUI/RootPanel/Margin/VBox/BuildButtons/BuildLumberButton
@onready var build_stone_btn: Button = $LegacyUI/RootPanel/Margin/VBox/BuildButtons/BuildStoneButton

@onready var well_slider: HSlider = $LegacyUI/RootPanel/Margin/VBox/Production/WellProduction/WellSlider
@onready var well_produce_btn: Button = $LegacyUI/RootPanel/Margin/VBox/Production/WellProduction/WellProduceButton
@onready var well_qty_label: Label = $LegacyUI/RootPanel/Margin/VBox/Production/WellProduction/WellQtyLabel

@onready var lumber_slider: HSlider = $LegacyUI/RootPanel/Margin/VBox/Production/LumberProduction/LumberSlider
@onready var lumber_produce_btn: Button = $LegacyUI/RootPanel/Margin/VBox/Production/LumberProduction/LumberProduceButton
@onready var lumber_qty_label: Label = $LegacyUI/RootPanel/Margin/VBox/Production/LumberProduction/LumberQtyLabel

@onready var stone_slider: HSlider = $LegacyUI/RootPanel/Margin/VBox/Production/StoneProduction/StoneSlider
@onready var stone_produce_btn: Button = $LegacyUI/RootPanel/Margin/VBox/Production/StoneProduction/StoneProduceButton
@onready var stone_qty_label: Label = $LegacyUI/RootPanel/Margin/VBox/Production/StoneProduction/StoneQtyLabel

@onready var sell_water_btn: Button = $LegacyUI/RootPanel/Margin/VBox/SellButtons/SellWater10
@onready var sell_wood_btn: Button  = $LegacyUI/RootPanel/Margin/VBox/SellButtons/SellWood10
@onready var sell_stone_btn: Button = $LegacyUI/RootPanel/Margin/VBox/SellButtons/SellStone10

var poll_timer: Timer
var has_well := false
var has_lumberjack := false
var has_stonemason := false

func _ready() -> void:
	status_label.text = ""
	
	# New UI connections
	logout_btn.pressed.connect(_logout)
	stats_btn.pressed.connect(_show_stats)
	buildings_btn.pressed.connect(_show_buildings_panel)
	production_btn.pressed.connect(_show_production_panel)
	help_btn.pressed.connect(_show_help)
	
	building_selector.item_selected.connect(_on_building_selected)
	dialog_close_btn.pressed.connect(_close_dialog)
	
	home_icon.pressed.connect(_on_home_icon_pressed)
	well_icon.pressed.connect(_on_well_icon_pressed)
	lumber_icon.pressed.connect(_on_lumber_icon_pressed)
	stone_icon.pressed.connect(_on_stone_icon_pressed)

	# Legacy UI connections
	sync_btn.pressed.connect(_sync_state)

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

# New UI handlers
func _show_stats() -> void:
	_set_status("Statistiken anzeigen")
	# TODO: Implement stats panel

func _show_buildings_panel() -> void:
	_set_status("Gebäude-Panel anzeigen")
	# Show info dialog as example
	building_info_dialog.visible = true

func _show_production_panel() -> void:
	_set_status("Produktions-Panel anzeigen")
	# TODO: Implement production panel

func _show_help() -> void:
	_set_status("Hilfe anzeigen")
	# TODO: Implement help dialog

func _on_building_selected(index: int) -> void:
	_set_status("Gebäude ausgewählt: " + building_selector.get_item_text(index))

func _close_dialog() -> void:
	building_info_dialog.visible = false

func _on_home_icon_pressed() -> void:
	_set_status("Übersicht")
	building_info_dialog.visible = false

func _on_well_icon_pressed() -> void:
	if has_well:
		_set_status("Brunnen ausgewählt")
		_show_building_dialog("Brunnen", "Dies ist dein Brunnen - Produktionsgebäude", "water")
	else:
		_set_status("Du hast noch keinen Brunnen. Baue einen!")

func _on_lumber_icon_pressed() -> void:
	if has_lumberjack:
		_set_status("Holzfäller ausgewählt")
		_show_building_dialog("Holzfäller", "Dies ist dein Holzfäller - Produktionsgebäude", "wood")
	else:
		_set_status("Du hast noch keinen Holzfäller. Baue einen!")

func _on_stone_icon_pressed() -> void:
	if has_stonemason:
		_set_status("Steinmetz ausgewählt")
		_show_building_dialog("Steinmetz", "Dies ist dein Steinmetz - Produktionsgebäude", "stone")
	else:
		_set_status("Du hast noch keinen Steinmetz. Baue einen!")

func _show_building_dialog(title: String, desc: String, resource_type: String) -> void:
	dialog_title.text = title
	dialog_desc.text = desc
	dialog_info.text = "Dein Gebäude beschäftigt 4 Arbeiter und produziert aktuell Waren in der Qualitätsstufe Q0"
	dialog_action.text = "Klicke auf Produzieren um die Produktion zu starten"
	building_info_dialog.visible = true

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
	var coins = str(s.get("coins", "0"))
	coins_label.text = "Coins: %s" % coins
	
	# Update new UI stats
	var inv = s.get("inventory", {})
	var water = str(inv.get("water", "0"))
	var wood = str(inv.get("wood", "0"))
	var stone = str(inv.get("stone", "0"))
	
	# Check which buildings the player has
	var buildings = s.get("buildings", [])
	has_well = false
	has_lumberjack = false
	has_stonemason = false
	var building_count = 0
	
	for b in buildings:
		building_count += 1
		if b.type == "well":
			has_well = true
		elif b.type == "lumberjack":
			has_lumberjack = true
		elif b.type == "stonemason":
			has_stonemason = true
	
	# Update new UI stats
	stats_line1.text = "Bargeld: %s €" % coins
	# Calculate approximate total capital (coins + building count * 1000 as rough estimate)
	var total_capital = int(coins) + (building_count * 1000)
	stats_line2.text = "Gesamtkapital: %s €" % str(total_capital)
	stats_line3.text = "Markt: 0  Gebäude: %d  Coins: %s" % [building_count, coins]
	
	# Update legacy UI
	water_value.text = water
	wood_value.text = wood
	stone_value.text = stone
	
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