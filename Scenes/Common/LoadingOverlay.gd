extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Margin/VBox/Label
@onready var spinner: Label = $Panel/Margin/VBox/Spinner

var spin_chars := ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
var spin_index := 0
var spin_timer: Timer

func _ready() -> void:
	hide()
	
	# Setup spinner animation
	spin_timer = Timer.new()
	spin_timer.wait_time = 0.1
	spin_timer.timeout.connect(_update_spinner)
	add_child(spin_timer)

func show_loading(message: String = "Bitte warten...") -> void:
	label.text = message
	spin_index = 0
	spinner.text = spin_chars[0]
	panel.visible = true
	show()
	spin_timer.start()

func hide_loading() -> void:
	spin_timer.stop()
	panel.visible = false
	hide()

func _update_spinner() -> void:
	spin_index = (spin_index + 1) % spin_chars.size()
	spinner.text = spin_chars[spin_index]
