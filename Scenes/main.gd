extends Node

@onready var tray: StatusIndicator = $StatusIndicator
@onready var tray_menu: PopupMenu = $TrayMenu

@onready var settings = $UI/Settings

@onready var status_dot = %StatusDot

@onready var language_button: Button = %LanguageButton
@onready var language_menu: PopupMenu = %LanguageMenu

@onready var page_1: Button = %Page1
@onready var page_2: Button = %Page2
@onready var page_3: Button = %Page3
@onready var page_4: Button = %Page4

@onready var reset_button: Button = %ResetButton
@onready var reset_dialog: ConfirmationDialog = $ResetConfirmDialog


var serial: GdSerial

var last_button_id := -1
var last_button_time := 0

var was_minimized := false

var serial_connected := false
var serial_retry_timer := 0.0


func _ready():
	setup_serial()
	setup_tray_menu()
	setup_language_menu()

	get_window().files_dropped.connect(_on_files_dropped)

	page_1.pressed.connect(_on_page_pressed.bind(1))
	page_2.pressed.connect(_on_page_pressed.bind(2))
	page_3.pressed.connect(_on_page_pressed.bind(3))
	page_4.pressed.connect(_on_page_pressed.bind(4))

	reset_button.pressed.connect(_on_reset_pressed)
	reset_dialog.confirmed.connect(_on_reset_confirmed)

	update_language()


func _process(delta):
	handle_window_state()
	handle_serial()

	if not serial_connected:
		serial_retry_timer -= delta

		if serial_retry_timer <= 0.0:
			setup_serial()
			serial_retry_timer = 2.0


# =========================================================
# SERIAL
# =========================================================

func setup_serial():
	serial_connected = false

	serial = GdSerial.new()
	serial.set_baud_rate(115200)

	var ports = serial.list_ports()

	for port in ports.values():
		var port_type: String = port.get("port_type", "")
		var port_name: String = port.get("port_name", "")

		if "VID: 0403" not in port_type:
			continue

		if "PID: 6001" not in port_type:
			continue

		serial.set_port(port_name)

		if serial.open():
			serial.clear_buffer()

			serial_connected = true
			update_connection_status()

			return

	update_connection_status()


func handle_serial():
	if not serial_connected:
		return

	if not serial.is_open():
		serial_connected = false
		update_connection_status()
		return

	if serial.bytes_available() <= 0:
		return

	var data = serial.readline().strip_edges()

	if not data.begins_with("BUTTON:"):
		return

	var button_id := int(
		data.trim_prefix("BUTTON:")
	)

	var now := Time.get_ticks_msec()

	if (
		button_id == last_button_id
		and now - last_button_time < 500
	):
		return

	last_button_id = button_id
	last_button_time = now

	ActionManager.execute_button(button_id)
	animate_button(button_id)


func update_connection_status():
	if serial_connected:
		status_dot.add_theme_color_override(
			"font_color",
			Color("#B026FF")
		)
	else:
		status_dot.add_theme_color_override(
			"font_color",
			Color("#555555")
		)


# =========================================================
# WINDOW / TRAY
# =========================================================

func setup_tray_menu():
	get_tree().auto_accept_quit = false

	tray_menu.id_pressed.connect(
		_on_tray_menu_pressed
	)

	update_tray_menu()


func update_tray_menu():
	tray_menu.clear()

	tray_menu.add_item(
		tr("OPEN"),
		0
	)

	tray_menu.add_item(
		tr("SETTINGS"),
		1
	)

	tray_menu.add_separator()

	tray_menu.add_item(
		tr("EXIT"),
		2
	)


func handle_window_state():
	var window = get_window()

	if (
		window.mode == Window.MODE_MINIMIZED
		and not was_minimized
	):
		was_minimized = true
		call_deferred("minimize_to_tray")

	elif window.mode != Window.MODE_MINIMIZED:
		was_minimized = false


func show_main_window():
	var window = get_window()

	tray.visible = false

	window.unfocusable = false
	window.mode = Window.MODE_WINDOWED
	window.show()
	window.move_to_foreground()
	window.grab_focus()


func minimize_to_tray():
	var window = get_window()

	window.unfocusable = true
	window.mode = Window.MODE_MINIMIZED

	tray.visible = true


func _on_tray_menu_pressed(id: int):
	match id:
		0:
			show_main_window()

		1:
			show_main_window()
			open_settings(1)

		2:
			get_tree().quit()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		minimize_to_tray()


# =========================================================
# SETTINGS
# =========================================================

func open_settings(button_id: int):
	settings.visible = true
	settings.open_for_button(button_id)


# =========================================================
# DRAG & DROP
# =========================================================

func _on_files_dropped(files: PackedStringArray):
	if files.size() != 1:
		return

	var file := files[0]
	var extension := file.get_extension().to_lower()

	if extension != "exe" and extension != "lnk":
		return

	var mouse_position := get_viewport().get_mouse_position()

	var button = find_button_at_position(
		mouse_position
	)

	if button == null:
		return

	var app_name = button.get_executable_name(
		file
	)

	ConfigManager.set_button(
		button.button_id,
		app_name,
		file,
		""
	)

	IconManager.extract_icon(
		file,
		button.button_id
	)

	button.refresh()

	if settings.visible:
		settings.open_for_button(
			button.button_id
		)


func find_button_at_position(position: Vector2) -> Button:
	for button in get_tree().get_nodes_in_group(
		"stream_buttons"
	):
		if button.get_global_rect().has_point(position):
			return button

	return null


# =========================================================
# BUTTON VISUAL
# =========================================================

func animate_button(button_id: int):
	for button in get_tree().get_nodes_in_group(
		"stream_buttons"
	):
		if button.button_id == button_id:
			button.press_visual()
			return


func refresh_all_buttons():
	for button in get_tree().get_nodes_in_group(
		"stream_buttons"
	):
		button.refresh()


# =========================================================
# PAGES
# =========================================================

func _on_page_pressed(page_id: int):
	if ConfigManager.get_current_page() == page_id:
		return

	ConfigManager.set_current_page(page_id)

	refresh_all_buttons()
	settings.clear_view()

	update_reset_dialog()


# =========================================================
# RESET CURRENT PAGE
# =========================================================

func _on_reset_pressed():
	update_reset_dialog()
	reset_dialog.popup_centered()


func _on_reset_confirmed():
	ConfigManager.clear_current_page()

	for button_id in range(1, 16):
		IconManager.delete_icon(button_id)

	refresh_all_buttons()
	settings.clear_view()


func update_reset_dialog():
	var page_id := ConfigManager.get_current_page()

	reset_dialog.title = (
		tr("RESET_PAGE")
		+ " "
		+ str(page_id)
	)

	reset_dialog.dialog_text = tr(
		"RESET_PAGE_CONFIRM"
	)

	reset_dialog.get_ok_button().text = tr(
		"CLEAR"
	)

	reset_dialog.get_cancel_button().text = tr(
		"CANCEL"
	)


# =========================================================
# LANGUAGE
# =========================================================

func setup_language_menu():
	language_menu.clear()

	language_menu.add_item(
		"🇵🇱 Polski",
		0
	)

	language_menu.add_item(
		"🇬🇧 English",
		1
	)

	language_button.pressed.connect(
		_on_language_button_pressed
	)

	language_menu.id_pressed.connect(
		_on_language_selected
	)


func _on_language_button_pressed():
	language_menu.position = Vector2(
		language_button.global_position.x
			- language_menu.size.x
			+ language_button.size.x,

		language_button.global_position.y
			+ language_button.size.y
			+ 6
	)

	language_menu.popup()


func _on_language_selected(id: int):
	match id:
		0:
			TranslationServer.set_locale("pl")

		1:
			TranslationServer.set_locale("en")

	update_language()


func update_language_button():
	var locale := TranslationServer.get_locale()

	if locale.begins_with("pl"):
		language_button.text = "🇵🇱"

	elif locale.begins_with("en"):
		language_button.text = "🇬🇧"

	else:
		language_button.text = "🌐"


func update_language():
	update_language_button()
	update_connection_status()

	update_tray_menu()
	update_reset_dialog()

	settings.update_language()

	refresh_all_buttons()
