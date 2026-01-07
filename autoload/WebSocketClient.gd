extends Node
# ============================================================================
# WEBSOCKET CLIENT - Real-time Communication with Backend
# ============================================================================
# Handles WebSocket connection to backend server for real-time updates:
# - Market listings (new, sold, expired)
# - Production job completion
# - Game state synchronization
# 
# Features:
# - Automatic reconnection with exponential backoff
# - JWT authentication
# - Channel subscription management
# ============================================================================

# Signals for WebSocket events
signal connected_to_server()
signal disconnected_from_server()
signal connection_error(error_message: String)
signal market_new_listing(listing: Dictionary)
signal market_listing_sold(data: Dictionary)
signal production_started(job: Dictionary)
signal production_complete(job: Dictionary)
signal state_updated(state: Dictionary)

# WebSocket peer
var _socket: WebSocketPeer = null
var _is_connected: bool = false

# Connection settings
var ws_base_url: String = "ws://localhost:3000"
var _reconnect_timer: Timer = null
var _reconnect_attempts: int = 0
var _max_reconnect_attempts: int = 10
var _base_reconnect_delay: float = 1.0
var _max_reconnect_delay: float = 30.0

# Authentication
var _authenticated: bool = false
var _pending_subscriptions: Array = []

# Ping/pong for keep-alive
var _ping_timer: Timer = null
var _ping_interval: float = 25.0

func _ready() -> void:
	# Get WebSocket URL from project settings if available
	if ProjectSettings.has_setting("application/config/ws_base_url"):
		ws_base_url = ProjectSettings.get_setting("application/config/ws_base_url")
	
	# Check environment variable (for exports)
	var env_url = OS.get_environment("WS_BASE_URL")
	if env_url != "":
		ws_base_url = env_url
	
	# Create reconnect timer
	_reconnect_timer = Timer.new()
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_attempt_reconnect)
	add_child(_reconnect_timer)
	
	# Create ping timer
	_ping_timer = Timer.new()
	_ping_timer.wait_time = _ping_interval
	_ping_timer.timeout.connect(_send_ping)
	add_child(_ping_timer)

func _process(_delta: float) -> void:
	if _socket == null:
		return
	
	_socket.poll()
	
	var state = _socket.get_ready_state()
	
	# Handle connection state changes
	if state == WebSocketPeer.STATE_OPEN:
		if not _is_connected:
			_is_connected = true
			_reconnect_attempts = 0
			_on_connected()
	elif state == WebSocketPeer.STATE_CLOSED:
		if _is_connected:
			_is_connected = false
			_authenticated = false
			_on_disconnected()
	
	# Process incoming packets
	while _socket.get_ready_state() == WebSocketPeer.STATE_OPEN and _socket.get_available_packet_count() > 0:
		var packet = _socket.get_packet()
		var message = packet.get_string_from_utf8()
		_handle_message(message)

func connect_to_server() -> void:
	"""Initiate connection to WebSocket server"""
	if _socket != null and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		print("[WebSocket] Already connected")
		return
	
	_socket = WebSocketPeer.new()
	var err = _socket.connect_to_url(ws_base_url)
	
	if err != OK:
		print("[WebSocket] Failed to connect: ", err)
		connection_error.emit("Failed to initiate connection")
		_schedule_reconnect()
	else:
		print("[WebSocket] Connecting to ", ws_base_url)

func disconnect_from_server() -> void:
	"""Close WebSocket connection"""
	if _socket != null:
		_socket.close()
		_socket = null
	
	_is_connected = false
	_authenticated = false
	_reconnect_timer.stop()
	_ping_timer.stop()

func subscribe_to_market() -> void:
	"""Subscribe to market updates"""
	if _authenticated:
		_send_event("subscribe:market", {})
	else:
		_pending_subscriptions.append("market")

func subscribe_to_production() -> void:
	"""Subscribe to production updates"""
	if _authenticated:
		_send_event("subscribe:production", {})
	else:
		_pending_subscriptions.append("production")

func _on_connected() -> void:
	"""Called when WebSocket connection is established"""
	print("[WebSocket] Connected to server")
	_authenticate()

func _on_disconnected() -> void:
	"""Called when WebSocket connection is closed"""
	print("[WebSocket] Disconnected from server")
	disconnected_from_server.emit()
	_ping_timer.stop()
	_schedule_reconnect()

func _authenticate() -> void:
	"""Send JWT token for authentication"""
	if GameState.token == "":
		print("[WebSocket] No token available for authentication")
		return
	
	# Socket.io authentication is done via handshake
	# We need to send auth data as a Socket.io packet
	# Format: '42["authenticate",{"token":"..."}]'
	var auth_packet = {
		"token": GameState.token
	}
	
	# For Socket.io, we send as a custom connect packet
	# This is a simplified version - in production, you'd use a proper Socket.io client
	# For now, we'll assume the server accepts token in first message
	_send_event("authenticate", auth_packet)
	
	# Mark as authenticated (in real implementation, wait for server confirmation)
	_authenticated = true
	_ping_timer.start()
	
	# Process pending subscriptions
	for channel in _pending_subscriptions:
		if channel == "market":
			subscribe_to_market()
		elif channel == "production":
			subscribe_to_production()
	_pending_subscriptions.clear()
	
	connected_to_server.emit()

func _send_event(event_name: String, data: Dictionary) -> void:
	"""Send event to server"""
	if _socket == null or _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("[WebSocket] Cannot send event, not connected")
		return
	
	# Socket.io format: '42["event_name",{...data...}]'
	# For WebSocketPeer, we send JSON directly
	var message = JSON.stringify({
		"event": event_name,
		"data": data
	})
	
	var err = _socket.send_text(message)
	if err != OK:
		print("[WebSocket] Failed to send event: ", err)

func _send_ping() -> void:
	"""Send ping to keep connection alive"""
	_send_event("ping", {})

func _handle_message(message: String) -> void:
	"""Handle incoming WebSocket message"""
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		print("[WebSocket] Failed to parse message: ", message)
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		print("[WebSocket] Invalid message format: ", message)
		return
	
	var event = data.get("event", "")
	var payload = data.get("data", {})
	
	# Route events to appropriate signals
	match event:
		"pong":
			pass  # Keep-alive response
		"subscribed":
			print("[WebSocket] Subscribed to channel: ", payload.get("channel", ""))
		"market:new-listing":
			market_new_listing.emit(payload)
		"market:listing-sold":
			market_listing_sold.emit(payload)
		"production:started":
			production_started.emit(payload)
		"production:complete":
			production_complete.emit(payload)
		"state:update":
			state_updated.emit(payload)
		_:
			print("[WebSocket] Unknown event: ", event)

func _schedule_reconnect() -> void:
	"""Schedule reconnection attempt with exponential backoff"""
	if _reconnect_attempts >= _max_reconnect_attempts:
		print("[WebSocket] Max reconnection attempts reached")
		connection_error.emit("Max reconnection attempts reached")
		return
	
	_reconnect_attempts += 1
	var delay = min(
		_base_reconnect_delay * pow(2, _reconnect_attempts - 1),
		_max_reconnect_delay
	)
	
	print("[WebSocket] Scheduling reconnect in ", delay, " seconds (attempt ", _reconnect_attempts, ")")
	_reconnect_timer.start(delay)

func _attempt_reconnect() -> void:
	"""Attempt to reconnect to server"""
	print("[WebSocket] Attempting to reconnect...")
	connect_to_server()

func is_connected() -> bool:
	"""Check if connected to server"""
	return _is_connected and _authenticated
