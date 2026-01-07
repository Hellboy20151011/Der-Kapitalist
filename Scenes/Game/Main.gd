extends Control

# ============================================================================
# MAIN GAME SCENE CONTROLLER
# ============================================================================
# This file is the main game scene controller (662 lines)
# MODULARITY CONCERN: This file is too large and handles too many responsibilities
# 
# Current Responsibilities (violates Single Responsibility Principle):
# 1. UI State Management (header, dialogs, panels)
# 2. Market System (listings, buying, selling)
# 3. Production Management (production state, timers, polling)
# 4. Building Management (building info, upgrades, construction)
# 5. Inventory and Resources Display
# 6. Authentication and User Session
# 7. Status Messages and Loading States
# 
# SUGGESTED REFACTORING:
# - Extract MarketPanel.gd (market logic ~100 lines)
# - Extract ProductionManager.gd (production logic ~80 lines)
# - Extract BuildingPanel.gd (building UI logic ~60 lines)
# - Extract UIStateManager.gd (loading, status, buttons ~50 lines)
# - Keep only high-level coordination in Main.gd (~200 lines)
# 
# This would improve:
# - Testability (smaller, focused units)
# - Maintainability (easier to find and fix issues)
# - Reusability (components can be used elsewhere)
# - Code organization (clear separation of concerns)
# ============================================================================

# Dev mode - set to true to show dev features (reset button)
@export var DEV_MODE: bool = true

# ============================================================================
# CONFIGURATION CONSTANTS
# ============================================================================
# MODULARITY NOTE: These constants should be moved to a separate config file
# Suggested: res://autoload/GameConfig.gd
# This would centralize all game constants and make them easier to maintain
# ============================================================================

# Production costs (must match backend CONFIG)
const PRODUCTION_COSTS = {
	"well": 1,
	"lumberjack": 2,
	"sandgrube": 3
}

# UI Constants
const STATUS_MESSAGE_TIMEOUT = 5.0
const RESOURCE_ICONS = {"water": "💧", "wood": "🪓", "stone": "🪨", "sand": "🏖️"}
const RESOURCE_NAMES = {"water": "Wasser", "wood": "Holz", "stone": "Stein", "sand": "Sand"}
const RESOURCE_TYPES = ["water", "wood", "stone", "sand"]

# ============================================================================
# UI NODE REFERENCES
# ============================================================================
# MODULARITY NOTE: 50+ @onready references indicates tight coupling to scene tree
# This makes the code fragile and hard to refactor
# 
# SUGGESTED IMPROVEMENT:
# - Group related UI elements into custom Control nodes (e.g., MarketPanel scene)
# - Expose only high-level signals instead of direct node references
# - Use dependency injection for services (Api, GameState)
# 
# Example refactoring:
#   @onready var market_panel: MarketPanel = $VBoxMain/GameArea/MarketPanel
#   market_panel.listing_purchased.connect(_on_market_purchase)
# Instead of managing internal market panel controls here
# ============================================================================

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
@onready var market_btn: Button = $VBoxMain/HeaderBar/HeaderContent/HBox/RightButtons/MarketButton
@onready var dev_reset_btn: Button = $VBoxMain/HeaderBar/HeaderContent/HBox/RightButtons/DevResetButton

@onready var building_selector: OptionButton = $VBoxMain/GameArea/BuildingSelector/SelectorMargin/BuildingOption
@onready var building_info_dialog: PanelContainer = $VBoxMain/GameArea/BuildingInfoDialog
@onready var dialog_title: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/TitleLabel
@onready var dialog_desc: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/DescLabel
@onready var dialog_info: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/InfoLabel
@onready var dialog_action: Label = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/ActionLabel
@onready var dialog_close_btn: Button = $VBoxMain/GameArea/BuildingInfoDialog/DialogMargin/DialogVBox/CloseButton

# Market UI references
@onready var market_panel: PanelContainer = $VBoxMain/GameArea/MarketPanel
@onready var market_close_btn: Button = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/CloseButton
@onready var resource_filter: OptionButton = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Kaufen/FilterHBox/ResourceFilter
@onready var refresh_btn: Button = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Kaufen/FilterHBox/RefreshButton
@onready var listings_container: VBoxContainer = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Kaufen/ListingsScroll/ListingsContainer
@onready var resource_type_option: OptionButton = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Verkaufen/ResourceTypeHBox/ResourceTypeOption
@onready var quantity_input: SpinBox = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Verkaufen/QuantityHBox/QuantityInput
@onready var price_input: SpinBox = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Verkaufen/PriceHBox/PriceInput
@onready var create_listing_btn: Button = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Verkaufen/CreateButton
@onready var my_listings_container: VBoxContainer = $VBoxMain/GameArea/MarketPanel/MarketMargin/MarketVBox/TabContainer/Verkaufen/MyListingsScroll/MyListingsContainer

# Loading spinner
@onready var loading_spinner: PanelContainer = $VBoxMain/GameArea/LoadingSpinner

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

# ============================================================================
# STATE VARIABLES
# ============================================================================
# MODULARITY NOTE: Production state tracking is duplicated between this file
# and the backend. Consider creating a ProductionStateManager class to handle
# this complexity in one place.
# ============================================================================

var poll_timer: Timer
var has_well := false
var has_lumberjack := false
var has_sandgrube := false
var is_loading := false
var current_coins := 0  # Track coins to avoid parsing from UI

# Production state tracking
var well_producing := false
var well_ready_at = null
var lumber_producing := false
var lumber_ready_at = null
var sandgrube_producing := false
var sandgrube_ready_at = null

# ============================================================================
# INITIALIZATION
# ============================================================================
# MODULARITY NOTE: _ready() is 70 lines - too long for a single function
# Should be broken into smaller initialization methods:
# - _setup_ui_connections()
# - _setup_market_panel()
# - _setup_building_controls()
# - _setup_production_polling()
# ============================================================================

func _ready() -> void:
	# Check if logged in
	if GameState.token == "":
		push_error("No token found, returning to login")
		get_tree().change_scene_to_file("res://Scenes/Auth/Login.tscn")
		return
	
	status_label.text = ""
	
	# Dev mode setup
	if dev_reset_btn:
		dev_reset_btn.visible = DEV_MODE
		if DEV_MODE:
			dev_reset_btn.pressed.connect(_dev_reset_account)
	
	# New UI connections
	if logout_btn: logout_btn.pressed.connect(_logout)
	if stats_btn: stats_btn.pressed.connect(_show_stats)
	if buildings_btn: buildings_btn.pressed.connect(_show_buildings_panel)
	if production_btn: production_btn.pressed.connect(_show_production_panel)
	if help_btn: help_btn.pressed.connect(_show_help)
	if market_btn: market_btn.pressed.connect(_show_market)
	
	# Market panel connections
	if market_close_btn: market_close_btn.pressed.connect(_close_market)
	if refresh_btn: refresh_btn.pressed.connect(_refresh_market_listings)
	if resource_filter: resource_filter.item_selected.connect(func(_idx): _refresh_market_listings())
	if create_listing_btn: create_listing_btn.pressed.connect(_create_market_listing)
	
	if building_selector: building_selector.item_selected.connect(_on_building_selected)
	if dialog_close_btn: dialog_close_btn.pressed.connect(_close_dialog)
	
	if home_icon: home_icon.pressed.connect(_on_home_icon_pressed)
	if well_icon: well_icon.pressed.connect(_on_well_icon_pressed)
	if lumber_icon: lumber_icon.pressed.connect(_on_lumber_icon_pressed)
	if stone_icon: stone_icon.pressed.connect(_on_stone_icon_pressed)

	# Legacy UI connections
	if sync_btn: sync_btn.pressed.connect(_sync_state)

	if upgrade_well_btn: upgrade_well_btn.pressed.connect(func(): await _upgrade("well"))
	if upgrade_lumber_btn: upgrade_lumber_btn.pressed.connect(func(): await _upgrade("lumberjack"))
	if upgrade_stone_btn: upgrade_stone_btn.pressed.connect(func(): await _upgrade("sandgrube"))

	if build_well_btn: build_well_btn.pressed.connect(func(): await _build("well"))
	if build_lumber_btn: build_lumber_btn.pressed.connect(func(): await _build("lumberjack"))
	if build_stone_btn: build_stone_btn.pressed.connect(func(): await _build("sandgrube"))

	if well_slider: well_slider.value_changed.connect(func(val): well_qty_label.text = str(int(val)))
	if lumber_slider: lumber_slider.value_changed.connect(func(val): lumber_qty_label.text = str(int(val)))
	if stone_slider: stone_slider.value_changed.connect(func(val): stone_qty_label.text = str(int(val)))

	if well_produce_btn: well_produce_btn.pressed.connect(func(): await _produce("well", int(well_slider.value)))
	if lumber_produce_btn: lumber_produce_btn.pressed.connect(func(): await _produce("lumberjack", int(lumber_slider.value)))
	if stone_produce_btn: stone_produce_btn.pressed.connect(func(): await _produce("sandgrube", int(stone_slider.value)))

	if sell_water_btn: sell_water_btn.pressed.connect(func(): await _sell("water", 10))
	if sell_wood_btn: sell_wood_btn.pressed.connect(func(): await _sell("wood", 10))
	if sell_stone_btn: sell_stone_btn.pressed.connect(func(): await _sell("stone", 10))

	# Polling alle 5 Sekunden für Produktionsstatus
	poll_timer = Timer.new()
	poll_timer.wait_time = 5.0
	poll_timer.autostart = true
	poll_timer.timeout.connect(_poll_production)
	add_child(poll_timer)

	# Direkt nach Start syncen
	await _sync_state()

# ============================================================================
# UI HANDLER METHODS (Navigation & Panels)
# ============================================================================
# MODULARITY NOTE: These methods are simple but scattered throughout the file
# Consider grouping related functionality or extracting to a NavigationManager
# ============================================================================

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

func _show_market() -> void:
	_set_status("Marktplatz öffnen")
	market_panel.visible = true
	_refresh_market_listings()

func _close_market() -> void:
	market_panel.visible = false

# ============================================================================
# MARKET SYSTEM IMPLEMENTATION
# ============================================================================
# MODULARITY CONCERN: ~150 lines of market logic embedded in Main scene
# This should be extracted to a dedicated MarketPanel.gd scene/script
# 
# Benefits of extraction:
# - Reusable market panel component
# - Easier to test market functionality in isolation
# - Clearer separation between game logic and market logic
# - Reduced complexity in Main.gd
# 
# Suggested structure:
#   res://Scenes/UI/MarketPanel.gd
#   - Market listing display logic
#   - Buy/sell transaction handling
#   - Filter and refresh logic
#   Signal: listing_purchased(listing_id)
#   Signal: listing_created(resource_type, quantity, price)
# ============================================================================

func _refresh_market_listings() -> void:
	if is_loading:
		return
	
	_show_loading(true)
	_disable_buttons(true)
	
	# Get selected resource filter
	var filter_idx = resource_filter.selected
	var resource_type = ""
	if filter_idx == 1:
		resource_type = "water"
	elif filter_idx == 2:
		resource_type = "wood"
	elif filter_idx == 3:
		resource_type = "stone"
	elif filter_idx == 4:
		resource_type = "sand"
	
	var res := await Api.get_market_listings(resource_type)
	
	_show_loading(false)
	_disable_buttons(false)
	
	if not res.ok:
		_set_status("❌ Fehler beim Laden: " + _error_string(res), true)
		return
	
	# Clear existing listings
	for child in listings_container.get_children():
		child.queue_free()
	
	var listings = res.data.get("listings", [])
	if listings.size() == 0:
		var label = Label.new()
		label.text = "Keine Angebote verfügbar"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		listings_container.add_child(label)
		_set_status("✓ Keine Angebote gefunden", true)
	else:
		for listing in listings:
			_add_listing_item(listing)
		_set_status("✓ %d Angebote geladen" % listings.size(), true)

func _add_listing_item(listing: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var res_type = listing.get("resource_type", "")
	
	var title_label = Label.new()
	title_label.text = "%s %s" % [RESOURCE_ICONS.get(res_type, "📦"), RESOURCE_NAMES.get(res_type, res_type)]
	title_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(title_label)
	
	var qty_label = Label.new()
	qty_label.text = "Menge: %s" % listing.get("quantity", "0")
	info_vbox.add_child(qty_label)
	
	var price_label = Label.new()
	var price_per_unit = int(listing.get("price_per_unit", "0"))
	var quantity = int(listing.get("quantity", "0"))
	# Prevent integer overflow by capping the calculation
	var total = min(price_per_unit * quantity, 9223372036854775807)  # Max int64
	price_label.text = "Preis: %d Coins/Stück (Gesamt: %d Coins)" % [price_per_unit, total]
	info_vbox.add_child(price_label)
	
	var buy_btn = Button.new()
	buy_btn.text = "Kaufen"
	buy_btn.custom_minimum_size = Vector2(100, 60)
	buy_btn.pressed.connect(func(): await _buy_listing(listing.get("id"), listing))
	hbox.add_child(buy_btn)
	
	listings_container.add_child(panel)

func _buy_listing(listing_id, listing: Dictionary) -> void:
	if is_loading:
		return
	
	_show_loading(true)
	_disable_buttons(true)
	
	var res := await Api.buy_listing(listing_id)
	
	_show_loading(false)
	_disable_buttons(false)
	
	if not res.ok:
		_set_status("❌ Kauf fehlgeschlagen: " + _error_string(res), true)
		return
	
	_set_status("✓ Erfolgreich gekauft!", true)
	await _sync_state()
	_refresh_market_listings()

func _create_market_listing() -> void:
	if is_loading:
		return
	
	_show_loading(true)
	_disable_buttons(true)
	
	# Validate array bounds before accessing
	var selected_idx = resource_type_option.selected
	if selected_idx < 0 or selected_idx >= RESOURCE_TYPES.size():
		_set_status("❌ Ungültiger Ressourcentyp", true)
		_show_loading(false)
		_disable_buttons(false)
		return
	
	var resource_type = RESOURCE_TYPES[selected_idx]
	var quantity = int(quantity_input.value)
	var price_per_unit = int(price_input.value)
	
	var res := await Api.create_market_listing(resource_type, quantity, price_per_unit)
	
	_show_loading(false)
	_disable_buttons(false)
	
	if not res.ok:
		_set_status("❌ Listing fehlgeschlagen: " + _error_string(res), true)
		return
	
	_set_status("✓ Angebot erstellt!", true)
	await _sync_state()

# ============================================================================
# UX HELPER FUNCTIONS
# ============================================================================
# MODULARITY NOTE: These utility functions are well-contained and could be
# extracted to a UIHelper class for reuse across scenes
# ============================================================================

# UX Improvement functions
func _show_loading(show: bool) -> void:
	is_loading = show
	loading_spinner.visible = show

func _disable_buttons(disable: bool) -> void:
	# Disable header buttons
	logout_btn.disabled = disable
	stats_btn.disabled = disable
	buildings_btn.disabled = disable
	production_btn.disabled = disable
	help_btn.disabled = disable
	market_btn.disabled = disable
	if DEV_MODE:
		dev_reset_btn.disabled = disable
	
	# Disable market buttons
	if market_panel.visible:
		refresh_btn.disabled = disable
		create_listing_btn.disabled = disable

func _set_status(msg: String, is_result: bool = false) -> void:
	status_label.text = msg
	# Auto-clear result messages after timeout
	if is_result:
		await get_tree().create_timer(STATUS_MESSAGE_TIMEOUT).timeout
		if status_label.text == msg:
			status_label.text = ""

func _dev_reset_account() -> void:
	if not DEV_MODE:
		return
	
	if is_loading:
		return
	
	_show_loading(true)
	_disable_buttons(true)
	
	var res := await Api.dev_reset_account()
	
	_show_loading(false)
	_disable_buttons(false)
	
	if not res.ok:
		_set_status("❌ Reset fehlgeschlagen: " + _error_string(res), true)
		return
	
	_set_status("✓ Account zurückgesetzt!", true)
	await _sync_state()

# ============================================================================
# BUILDING MANAGEMENT
# ============================================================================
# MODULARITY NOTE: Building dialog and icon management (~50 lines)
# Could be extracted to BuildingInfoPanel component
# ============================================================================

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
	if has_sandgrube:
		_set_status("Sandgrube ausgewählt")
		_show_building_dialog("Sandgrube", "Dies ist deine Sandgrube - Produktionsgebäude", "sand")
	else:
		_set_status("Du hast noch keine Sandgrube. Baue eine!")

func _show_building_dialog(title: String, desc: String, resource_type: String) -> void:
	dialog_title.text = title
	dialog_desc.text = desc
	dialog_info.text = "Dein Gebäude beschäftigt 4 Arbeiter und produziert aktuell Waren in der Qualitätsstufe Q0"
	dialog_action.text = "Klicke auf Produzieren um die Produktion zu starten"
	building_info_dialog.visible = true

# ============================================================================
# STATE SYNCHRONIZATION
# ============================================================================
# MODULARITY NOTE: _sync_state() is a critical 75-line method that handles:
# - Server communication
# - Data parsing and type conversion
# - UI updates across multiple panels
# - Building state management
# - Production state tracking
# 
# This method violates SRP and should be refactored into:
# - _fetch_server_state() -> Dictionary
# - _update_ui_from_state(state: Dictionary) -> void
# - _update_building_states(buildings: Array) -> void
# - _update_production_timers(buildings: Array) -> void
# ============================================================================

func _sync_state() -> void:
	if GameState.token == "":
		_set_status("Nicht eingeloggt.")
		return

	var res := await Api.get_state()
	if not res.ok:
		_set_status("Sync Fehler: %s" % _error_string(res))
		return

	var s = res.data
	# Update GameState
	GameState.update_from_server(s)
	
	# Backend liefert coins/inventory als String (BigInt-safe)
	var coins = str(s.get("coins", "0"))
	coins_label.text = "Coins: %s" % coins
	current_coins = int(coins)  # Store for use in UI updates
	
	# Update new UI stats
	var inv = s.get("inventory", {})
	var water = str(inv.get("water", "0"))
	var wood = str(inv.get("wood", "0"))
	var stone = str(inv.get("stone", "0"))
	
	# Check which buildings the player has
	var buildings = s.get("buildings", [])
	has_well = false
	has_lumberjack = false
	has_sandgrube = false
	var building_count = 0
	
	# Reset production state
	well_producing = false
	well_ready_at = null
	lumber_producing = false
	lumber_ready_at = null
	sandgrube_producing = false
	sandgrube_ready_at = null
	
	for b in buildings:
		building_count += 1
		if b.type == "well":
			has_well = true
			well_producing = b.get("is_producing", false)
			well_ready_at = b.get("ready_at_unix", null)
		elif b.type == "lumberjack":
			has_lumberjack = true
			lumber_producing = b.get("is_producing", false)
			lumber_ready_at = b.get("ready_at_unix", null)
		elif b.type == "sandgrube":
			has_sandgrube = true
			sandgrube_producing = b.get("is_producing", false)
			sandgrube_ready_at = b.get("ready_at_unix", null)
	
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
	
	# Update slider maximums based on coins and production costs
	_update_slider_max(well_slider, "well", has_well, well_producing)
	_update_slider_max(lumber_slider, "lumberjack", has_lumberjack, lumber_producing)
	_update_slider_max(stone_slider, "sandgrube", has_sandgrube, sandgrube_producing)
	
	# Update UI based on owned buildings
	_update_building_ui()

	_set_status("Sync ok (%s)" % str(s.get("server_time", "")))

# ============================================================================
# ECONOMY ACTIONS (Build, Upgrade, Sell)
# ============================================================================

func _upgrade(building_type: String) -> void:
	var res := await Api.upgrade_building(building_type)
	if not res.ok:
		_set_status("Upgrade fehlgeschlagen: %s" % _error_string(res))
		return
	await _sync_state()

func _sell(resource_type: String, qty: int) -> void:
	var res := await Api.sell_resource(resource_type, qty)
	if not res.ok:
		_set_status("Verkauf fehlgeschlagen: %s" % _error_string(res))
		return
	await _sync_state()

func _logout() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://Scenes/Auth/Login.tscn")

# ============================================================================
# ERROR HANDLING & UTILITIES
# ============================================================================

func _error_string(res: Dictionary) -> String:
	# Check for new error details field (network errors, timeouts)
	if res.has("details"):
		return str(res.details)
	if res.has("data") and typeof(res.data) == TYPE_DICTIONARY:
		if res.data.has("error"):
			var error = str(res.data.error)
			# Add user-friendly message for rate limiting
			if error == "too_many_requests" or error == "too_many_auth_attempts":
				return "Zu viele Anfragen. Bitte warten und erneut versuchen."
			return error
	if res.has("code"):
		var code = res.code
		if code == 429:
			return "Zu viele Anfragen (Rate Limit erreicht)"
		return "HTTP %s" % str(code)
	return "unbekannt"

# ============================================================================
# UI UPDATE HELPERS
# ============================================================================
# MODULARITY NOTE: These helper methods manage complex UI state across
# multiple sliders, buttons, and labels. The logic is tightly coupled to
# the production system state.
# 
# Consider creating a ProductionUIController to encapsulate:
# - Slider state management
# - Button enable/disable logic
# - Timer display updates
# - Cost calculations and validation
# ============================================================================

func _update_slider_max(slider: HSlider, building_type: String, has_building: bool, is_producing: bool) -> void:
	## Helper function to update slider max value based on available coins and building state
	if not has_building:
		return
	
	var cost = PRODUCTION_COSTS[building_type]
	var max_qty = max(1, int(float(current_coins) / float(cost)))  # Use float division for accuracy
	slider.max_value = float(max_qty)
	if not is_producing:
		slider.value = min(slider.value, float(max_qty))

# ============================================================================
# BUILDING UI STATE MANAGEMENT
# ============================================================================
# MODULARITY CONCERN: _update_building_ui() is 75 lines of repetitive code
# with very similar logic for well/lumberjack/sandgrube
# 
# This is a prime candidate for refactoring using:
# - Data-driven approach with building config dictionary
# - Helper methods to reduce duplication
# - Observer pattern for production state changes
# 
# Example refactored approach:
#   func _update_building_production_ui(building_type: String, config: Dictionary):
#     # Generic logic for any building type
# ============================================================================

func _update_building_ui() -> void:
	# Enable/disable build buttons based on ownership
	build_well_btn.disabled = has_well
	build_lumber_btn.disabled = has_lumberjack
	build_stone_btn.disabled = has_sandgrube
	
	# Enable/disable upgrade buttons based on ownership
	upgrade_well_btn.disabled = not has_well
	upgrade_lumber_btn.disabled = not has_lumberjack
	upgrade_stone_btn.disabled = not has_sandgrube
	
	# Update production controls based on ownership and production status
	# Well
	var well_cost = PRODUCTION_COSTS["well"]
	well_slider.editable = has_well and not well_producing and current_coins >= well_cost
	if well_producing:
		if well_ready_at:
			var ready_time = well_ready_at  # Already Unix timestamp
			var now = Time.get_unix_time_from_system()
			if ready_time > now:
				well_produce_btn.text = "Produziert... (%ds)" % int(ready_time - now)
				well_produce_btn.disabled = true
			else:
				# Production finished - will be auto-collected on next sync
				well_produce_btn.text = "Fertig"
				well_produce_btn.disabled = true
		else:
			well_produce_btn.text = "Produziert..."
			well_produce_btn.disabled = true
	else:
		well_produce_btn.text = "Produzieren" if current_coins >= well_cost else "Nicht genug Coins"
		well_produce_btn.disabled = not has_well or current_coins < well_cost
	
	# Lumberjack
	var lumber_cost = PRODUCTION_COSTS["lumberjack"]
	lumber_slider.editable = has_lumberjack and not lumber_producing and current_coins >= lumber_cost
	if lumber_producing:
		if lumber_ready_at:
			var ready_time = lumber_ready_at  # Already Unix timestamp
			var now = Time.get_unix_time_from_system()
			if ready_time > now:
				lumber_produce_btn.text = "Produziert... (%ds)" % int(ready_time - now)
				lumber_produce_btn.disabled = true
			else:
				# Production finished - will be auto-collected on next sync
				lumber_produce_btn.text = "Fertig"
				lumber_produce_btn.disabled = true
		else:
			lumber_produce_btn.text = "Produziert..."
			lumber_produce_btn.disabled = true
	else:
		lumber_produce_btn.text = "Produzieren" if current_coins >= lumber_cost else "Nicht genug Coins"
		lumber_produce_btn.disabled = not has_lumberjack or current_coins < lumber_cost
	
	# Sandgrube
	var stone_cost = PRODUCTION_COSTS["sandgrube"]
	stone_slider.editable = has_sandgrube and not sandgrube_producing and current_coins >= stone_cost
	if sandgrube_producing:
		if sandgrube_ready_at:
			var ready_time = sandgrube_ready_at  # Already Unix timestamp
			var now = Time.get_unix_time_from_system()
			if ready_time > now:
				stone_produce_btn.text = "Produziert... (%ds)" % int(ready_time - now)
				stone_produce_btn.disabled = true
			else:
				# Production finished - will be auto-collected on next sync
				stone_produce_btn.text = "Fertig"
				stone_produce_btn.disabled = true
		else:
			stone_produce_btn.text = "Produziert..."
			stone_produce_btn.disabled = true
	else:
		stone_produce_btn.text = "Produzieren" if current_coins >= stone_cost else "Nicht genug Coins"
		stone_produce_btn.disabled = not has_sandgrube or current_coins < stone_cost

# ============================================================================
# PRODUCTION ACTIONS
# ============================================================================

func _build(building_type: String) -> void:
	var res := await Api.build_building(building_type)
	if not res.ok:
		_set_status("Bau fehlgeschlagen: %s" % _error_string(res))
		return
	_set_status("Gebäude gebaut!")
	await _sync_state()

func _produce(building_type: String, quantity: int) -> void:
	# Production is now always a start action
	# Collection happens automatically on the server
	if quantity <= 0:
		_set_status("Bitte Menge auswählen")
		return
	
	var res := await Api.start_production(building_type, quantity)
	if not res.ok:
		_set_status("Produktion fehlgeschlagen: %s" % _error_string(res))
		return
	_set_status("Produktion gestartet!")
	await _sync_state()

# ============================================================================
# PRODUCTION POLLING
# ============================================================================
# MODULARITY NOTE: Polling is a simple timer-based system
# Could be improved with event-based updates or WebSocket connection
# ============================================================================

func _poll_production() -> void:
	if GameState.token == "":
		return
	
	# Check if any building is producing
	if well_producing or lumber_producing or sandgrube_producing:
		# Refresh state to update timers and check if any production is complete
		await _sync_state()