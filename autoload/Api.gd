extends Node
class_name Api

const BASE_URL := "http://localhost:3000"

# Legacy compatibility - kept for gradual migration
var token: String = "":
	get:
		return GameState.token
	set(value):
		GameState.token = value

var base_url := BASE_URL

func _headers() -> PackedStringArray:
	var h := PackedStringArray(["Content-Type: application/json"])
	if GameState.token != "":
		h.append("Authorization: Bearer %s" % GameState.token)
	return h

# ============================================================================
# AUTH ENDPOINTS
# ============================================================================

func login(email: String, password: String) -> Dictionary:
	"""Login with email and password. Returns token on success."""
	return await post_json("/auth/login", {"email": email, "password": password})

func register(email: String, password: String) -> Dictionary:
	"""Register new account with email and password. Returns token on success."""
	return await post_json("/auth/register", {"email": email, "password": password})

# ============================================================================
# STATE ENDPOINTS
# ============================================================================

func get_state() -> Dictionary:
	"""Get current player state (coins, inventory, buildings, etc.)"""
	return await get_json("/state")

# ============================================================================
# ECONOMY ENDPOINTS
# ============================================================================

func build_building(building_type: String) -> Dictionary:
	"""Build a new building of the specified type"""
	return await post_json("/economy/buildings/build", {"building_type": building_type})

func upgrade_building(building_type: String) -> Dictionary:
	"""Upgrade an existing building"""
	return await post_json("/economy/buildings/upgrade", {"building_type": building_type})

func sell_resource(resource_type: String, quantity: int) -> Dictionary:
	"""Sell resources for coins"""
	return await post_json("/economy/sell", {"resource_type": resource_type, "quantity": quantity})

# ============================================================================
# PRODUCTION ENDPOINTS
# ============================================================================

func start_production(building_type: String, quantity: int) -> Dictionary:
	"""Start production job for specified building and quantity"""
	return await post_json("/production/start", {"building_type": building_type, "quantity": quantity})

# ============================================================================
# MARKET ENDPOINTS
# ============================================================================

func get_market_listings(resource_type: String = "") -> Dictionary:
	"""Get market listings, optionally filtered by resource type"""
	var path = "/market/listings"
	if resource_type != "":
		path += "?resource_type=" + resource_type
	return await get_json(path)

func create_market_listing(resource_type: String, quantity: int, price_per_unit: int) -> Dictionary:
	"""Create a new market listing"""
	return await post_json("/market/listings", {
		"resource_type": resource_type,
		"quantity": quantity,
		"price_per_unit": price_per_unit
	})

func buy_listing(listing_id) -> Dictionary:
	"""Buy a market listing"""
	return await post_json("/market/listings/%s/buy" % str(listing_id), {})

# ============================================================================
# DEV ENDPOINTS
# ============================================================================

func dev_reset_account() -> Dictionary:
	"""Reset account to initial state (dev only)"""
	return await post_json("/dev/reset-account", {})

# ============================================================================
# LOW-LEVEL HTTP METHODS
# ============================================================================

func post_json(path: String, body: Dictionary) -> Dictionary:
	"""Make a POST request with JSON body"""
	var http := HTTPRequest.new()
	add_child(http)
	var err := http.request(base_url + path, _headers(), HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "request_failed"}
	var result = await http.request_completed
	http.queue_free()

	var code: int = result[1]
	var bytes: PackedByteArray = result[3]
	var text := bytes.get_string_from_utf8()
	var data = {}
	if text != "":
		data = JSON.parse_string(text)
	return {"ok": code >= 200 and code < 300, "code": code, "data": data}

func get_json(path: String) -> Dictionary:
	"""Make a GET request"""
	var http := HTTPRequest.new()
	add_child(http)
	var err := http.request(base_url + path, _headers(), HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "request_failed"}
	var result = await http.request_completed
	http.queue_free()

	var code: int = result[1]
	var bytes: PackedByteArray = result[3]
	var text := bytes.get_string_from_utf8()
	var data = {}
	if text != "":
		data = JSON.parse_string(text)
	return {"ok": code >= 200 and code < 300, "code": code, "data": data}
