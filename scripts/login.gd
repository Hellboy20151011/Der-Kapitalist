extends Control

@onready var email_edit: LineEdit = $Panel/Margin/VBox/EmailLineEdit
@onready var pass_edit: LineEdit = $Panel/Margin/VBox/PasswordLineEdit
@onready var status_label: Label = $Panel/Margin/VBox/StatusLabel
@onready var login_btn: Button = $Panel/Margin/VBox/Buttons/LoginButton
@onready var register_btn: Button = $Panel/Margin/VBox/Buttons/RegisterButton

func _ready() -> void:
	status_label.text = ""
	login_btn.pressed.connect(_on_login_pressed)
	register_btn.pressed.connect(_on_register_pressed)

	# Optional: Felder vorfüllen für локales Testing
	# email_edit.text = "test@example.com"
	# pass_edit.text = "test1234"

func _set_busy(busy: bool) -> void:
	login_btn.disabled = busy
	register_btn.disabled = busy
	email_edit.editable = not busy
	pass_edit.editable = not busy

func _on_login_pressed() -> void:
	await _auth(false)

func _on_register_pressed() -> void:
	await _auth(true)

func _auth(register: bool) -> void:
	var email := email_edit.text.strip_edges()
	var password := pass_edit.text

	if email == "" or password == "":
		status_label.text = "Bitte E-Mail und Passwort eingeben."
		return

	_set_busy(true)
	status_label.text = "Bitte warten..."

	var endpoint := "/auth/register" if register else "/auth/login"
	var res := await Net.post_json(endpoint, {"email": email, "password": password})

	if not res.ok:
		var msg := "Fehler"
		if typeof(res.data) == TYPE_DICTIONARY and res.data.has("error"):
			msg = str(res.data.error)
		status_label.text = (register ? "Registrierung fehlgeschlagen: " : "Login fehlgeschlagen: ") + msg
		_set_busy(false)
		return

	if typeof(res.data) != TYPE_DICTIONARY or not res.data.has("token"):
		status_label.text = "Serverantwort unerwartet."
		_set_busy(false)
		return

	Net.token = str(res.data.token)
	status_label.text = "Erfolgreich."

	# Wechsel zur Main Szene
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")