extends Node
# ============================================================================
# API LAYER - HTTP Communication with Backend
# ============================================================================
# FILE SIZE: 238 lines
# 
# MODULARITY ASSESSMENT:
# This file serves as a centralized API client for all backend communication
# 
# STRUCTURE:
# 1. Configuration & Setup (~30 lines)
# 2. Auth Endpoints (~10 lines)
# 3. State Endpoints (~5 lines)
# 4. Economy Endpoints (~15 lines)
# 5. Production Endpoints (~5 lines)
# 6. Market Endpoints (~15 lines)
# 7. Dev Endpoints (~5 lines)
# 8. HTTP Helper Methods (~110 lines)
# 9. Error Handling (~40 lines)
# 
# STRENGTHS:
# - Excellent encapsulation of all HTTP logic in one place
# - Type-safe method signatures for each endpoint
# - Centralized error handling with German error messages
# - Timeout handling and network error detection
# - Good separation between high-level API methods and low-level HTTP
# 
# MODULARITY EVALUATION: ★★★★★ Excellent
# This file is a textbook example of good API layer design:
# - Single responsibility (HTTP communication)
# - Clear abstraction boundary
# - Easy to test and mock
# - Consistent error handling
# - Well-organized by feature area
# 
# MINOR SUGGESTIONS (optional):
# 1. Could extract error message mapping to separate file if it grows
# 2. Could add request retry logic for transient failures
# 3. Could add request/response logging for debugging
# 
# RECOMMENDATION: Keep as-is. This file is well-structured and maintainable.
# Do NOT split this file - it's at optimal size and organization.
# ============================================================================

# Note: This is an autoload and globally accessible as 'Api'
# Do not use class_name with autoloads in Godot 4.5+

# Base URL can be configured in project settings or overridden via environment
# Default to localhost for development
const DEFAULT_BASE_URL := "http://localhost:3000"
const DEFAULT_WS_URL := "ws://localhost:3000"

# Legacy compatibility - kept for gradual migration
var token: String = "":
	get:
		return GameState.token
	set(value):
		GameState.token = value

var base_url := _get_base_url()

func _ready() -> void:
	## Initialize project settings on first run
	_ensure_project_settings()

func _ensure_project_settings() -> void:
	## Create project settings if they don't exist
	# API Base URL setting
	if not ProjectSettings.has_setting("application/config/api_base_url"):
		ProjectSettings.set_setting("application/config/api_base_url", DEFAULT_BASE_URL)
		ProjectSettings.set_initial_value("application/config/api_base_url", DEFAULT_BASE_URL)
		# Add property info for the editor
		ProjectSettings.add_property_info({
			"name": "application/config/api_base_url",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		})
		print("[Api] Created project setting: application/config/api_base_url = ", DEFAULT_BASE_URL)
	
	# WebSocket Base URL setting
	if not ProjectSettings.has_setting("application/config/ws_base_url"):
		ProjectSettings.set_setting("application/config/ws_base_url", DEFAULT_WS_URL)
		ProjectSettings.set_initial_value("application/config/ws_base_url", DEFAULT_WS_URL)
		# Add property info for the editor
		ProjectSettings.add_property_info({
			"name": "application/config/ws_base_url",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		})
		print("[Api] Created project setting: application/config/ws_base_url = ", DEFAULT_WS_URL)
	
	# Save the project settings to disk
	var save_err = ProjectSettings.save()
	if save_err != OK:
		print("[Api] Warning: Could not save project settings: ", save_err)

func _get_base_url() -> String:
	# Check for project setting first
	if ProjectSettings.has_setting("application/config/api_base_url"):
		return ProjectSettings.get_setting("application/config/api_base_url")
	# Check environment variable (for exports)
	var env_url = OS.get_environment("API_BASE_URL")
	if env_url != "":
		return env_url
	# Fall back to default
	return DEFAULT_BASE_URL

func _headers() -> PackedStringArray:
	var h := PackedStringArray(["Content-Type: application/json"])
	if GameState.token != "":
		h.append("Authorization: Bearer %s" % GameState.token)
	return h

# ============================================================================
# AUTH ENDPOINTS
# ============================================================================

func login(email: String, password: String) -> Dictionary:
	## Login with email and password. Returns token on success.
	return await post_json("/auth/login", {"email": email, "password": password})

func register(email: String, password: String) -> Dictionary:
	## Register new account with email and password. Returns token on success.
	return await post_json("/auth/register", {"email": email, "password": password})

# ============================================================================
# STATE ENDPOINTS
# ============================================================================

func get_state() -> Dictionary:
	## Get current player state (coins, inventory, buildings, etc.)
	return await get_json("/state")

# ============================================================================
# ECONOMY ENDPOINTS
# ============================================================================

func build_building(building_type: String) -> Dictionary:
	## Build a new building of the specified type
	return await post_json("/economy/buildings/build", {"building_type": building_type})

func upgrade_building(building_type: String) -> Dictionary:
	## Upgrade an existing building
	return await post_json("/economy/buildings/upgrade", {"building_type": building_type})

func sell_resource(resource_type: String, quantity: int) -> Dictionary:
	## Sell resources for coins
	return await post_json("/economy/sell", {"resource_type": resource_type, "quantity": quantity})

# ============================================================================
# PRODUCTION ENDPOINTS
# ============================================================================

func start_production(building_type: String, quantity: int) -> Dictionary:
	## Start production job for specified building and quantity
	return await post_json("/production/start", {"building_type": building_type, "quantity": quantity})

# ============================================================================
# MARKET ENDPOINTS
# ============================================================================

func get_market_listings(resource_type: String = "") -> Dictionary:
	## Get market listings, optionally filtered by resource type
	var path = "/market/listings"
	if resource_type != "":
		path += "?resource_type=" + resource_type
	return await get_json(path)

func create_market_listing(resource_type: String, quantity: int, price_per_unit: int) -> Dictionary:
	## Create a new market listing
	return await post_json("/market/listings", {
		"resource_type": resource_type,
		"quantity": quantity,
		"price_per_unit": price_per_unit
	})

func buy_listing(listing_id) -> Dictionary:
	## Buy a market listing
	return await post_json("/market/listings/%s/buy" % str(listing_id), {})

# ============================================================================
# DEV ENDPOINTS
# ============================================================================

func dev_reset_account() -> Dictionary:
	## Reset account to initial state (dev only)
	return await post_json("/dev/reset-account", {})

# ============================================================================
# LOW-LEVEL HTTP METHODS
# ============================================================================

func post_json(path: String, body: Dictionary, timeout: float = 30.0) -> Dictionary:
	## Make a POST request with JSON body
	var http := HTTPRequest.new()
	add_child(http)
	
	# Timeout-Timer erstellen (use array for mutable state in lambda)
	var timer := get_tree().create_timer(timeout)
	var timed_out := [false]
	
	# Timeout-Handler (vor Request registrieren!)
	timer.timeout.connect(func():
		timed_out[0] = true
		if is_instance_valid(http):
			http.cancel_request()
	)
	
	# Request senden
	var err := http.request(base_url + path, _headers(), HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "request_failed", "details": "Anfrage konnte nicht gesendet werden"}
	
	# Warte auf Response
	var result = await http.request_completed
	http.queue_free()
	
	# Check Timeout
	if timed_out[0]:
		return {"ok": false, "error": "timeout", "details": "Server antwortet nicht (Timeout nach %ds)" % int(timeout)}
	
	# Check Netzwerkfehler (result[0])
	var request_result: int = result[0]
	if request_result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"error": "network_error",
			"details": _get_network_error_message(request_result)
		}
	
	# Parse Response (wie bisher)
	var code: int = result[1]
	var bytes: PackedByteArray = result[3]
	var text := bytes.get_string_from_utf8()
	var data = {}
	if text != "":
		data = JSON.parse_string(text)
	
	return {"ok": code >= 200 and code < 300, "code": code, "data": data}

func get_json(path: String, timeout: float = 30.0) -> Dictionary:
	## Make a GET request
	var http := HTTPRequest.new()
	add_child(http)
	
	# Timeout-Timer erstellen (use array for mutable state in lambda)
	var timer := get_tree().create_timer(timeout)
	var timed_out := [false]
	
	# Timeout-Handler (vor Request registrieren!)
	timer.timeout.connect(func():
		timed_out[0] = true
		if is_instance_valid(http):
			http.cancel_request()
	)
	
	# Request senden
	var err := http.request(base_url + path, _headers(), HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "request_failed", "details": "Anfrage konnte nicht gesendet werden"}
	
	# Warte auf Response
	var result = await http.request_completed
	http.queue_free()
	
	# Check Timeout
	if timed_out[0]:
		return {"ok": false, "error": "timeout", "details": "Server antwortet nicht (Timeout nach %ds)" % int(timeout)}
	
	# Check Netzwerkfehler (result[0])
	var request_result: int = result[0]
	if request_result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"error": "network_error",
			"details": _get_network_error_message(request_result)
		}
	
	# Parse Response (wie bisher)
	var code: int = result[1]
	var bytes: PackedByteArray = result[3]
	var text := bytes.get_string_from_utf8()
	var data = {}
	if text != "":
		data = JSON.parse_string(text)
	
	return {"ok": code >= 200 and code < 300, "code": code, "data": data}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _get_network_error_message(error_code: int) -> String:
	## Returns user-friendly German error messages for network errors
	match error_code:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "Kann keine Verbindung zum Server herstellen"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Server-Adresse konnte nicht aufgelöst werden (DNS-Fehler)"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Verbindung wurde unterbrochen"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "Sichere Verbindung fehlgeschlagen (SSL/TLS-Fehler)"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "Server antwortet nicht"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "Server-Antwort zu groß"
		HTTPRequest.RESULT_TIMEOUT:
			return "Zeitüberschreitung - Server antwortet zu langsam"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "Anfrage fehlgeschlagen"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "Zu viele Weiterleitungen"
		_:
			return "Netzwerkfehler (Code: %d)" % error_code
