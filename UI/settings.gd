extends Control


const INVALID_BUTTON_ID := -1

const KEY_POPUP_WIDTH := 280
const KEY_POPUP_HEIGHT := 320

const MODIFIER_KEYS := [
	KEY_CTRL,
	KEY_SHIFT,
	KEY_ALT,
	KEY_META
]

const SPECIAL_KEYS := [
	KEY_ESCAPE,
	KEY_TAB,
	KEY_ENTER,
	KEY_SPACE,
	KEY_BACKSPACE,
	KEY_INSERT,
	KEY_DELETE,
	KEY_HOME,
	KEY_END,
	KEY_PAGEUP,
	KEY_PAGEDOWN,
	KEY_UP,
	KEY_DOWN,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_CAPSLOCK,
	KEY_NUMLOCK,
	KEY_SCROLLLOCK,
	KEY_PRINT,
	KEY_PAUSE
]

const SYMBOL_KEYS := [
	["-", KEY_MINUS],
	["=", KEY_EQUAL],
	["[", KEY_BRACKETLEFT],
	["]", KEY_BRACKETRIGHT],
	["\\", KEY_BACKSLASH],
	[";", KEY_SEMICOLON],
	["'", KEY_APOSTROPHE],
	[",", KEY_COMMA],
	[".", KEY_PERIOD],
	["/", KEY_SLASH],
	["`", KEY_QUOTELEFT]
]

const KEY_TRANSLATIONS := {
	KEY_ESCAPE: "ESCAPE",
	KEY_SPACE: "SPACE",
	KEY_BACKSPACE: "BACKSPACE",
	KEY_INSERT: "INSERT",
	KEY_DELETE: "DELETE_KEY",
	KEY_HOME: "HOME_KEY",
	KEY_END: "END_KEY",
	KEY_PAGEUP: "PAGE_UP",
	KEY_PAGEDOWN: "PAGE_DOWN",
	KEY_UP: "ARROW_UP",
	KEY_DOWN: "ARROW_DOWN",
	KEY_LEFT: "ARROW_LEFT",
	KEY_RIGHT: "ARROW_RIGHT",
	KEY_CAPSLOCK: "CAPS_LOCK",
	KEY_NUMLOCK: "NUM_LOCK",
	KEY_SCROLLLOCK: "SCROLL_LOCK",
	KEY_PRINT: "PRINT_SCREEN",
	KEY_PAUSE: "PAUSE_KEY"
}


@onready var toolbox_label: Label = %ToolboxLabel
@onready var icon_preview: TextureRect = %IconPreview

@onready var name_edit: LineEdit = %NameEdit
@onready var path_edit: LineEdit = %PathEdit
@onready var arguments_edit: LineEdit = %ArgumentsEdit

@onready var title_caption: Label = %TitleCaption
@onready var path_caption: Label = %PathCaption
@onready var arguments_caption: Label = %ArgumentsCaption
@onready var shortcut_caption: Label = %ShortcutCaption

@onready var manual_title_label: Label = %TitleLabel
@onready var key_label: Label = %KeyLabel

@onready var browse_button: Button = %BrowseButton
@onready var delete_button: Button = %DeleteButton

@onready var shortcut_button: Button = %ShortcutButton
@onready var manual_shortcut_button: Button = %ManualShortcutButton
@onready var clear_shortcut_button: Button = %ClearShortcutButton

@onready var file_dialog: FileDialog = $FileDialog

@onready var manual_shortcut_popup: PopupPanel = $ManualShortcutPopup

@onready var ctrl_toggle: Button = %CtrlToggle
@onready var shift_toggle: Button = %ShiftToggle
@onready var alt_toggle: Button = %AltToggle
@onready var win_toggle: Button = %WinToggle

@onready var key_option: OptionButton = %KeyOption
@onready var apply_manual_button: Button = %ApplyManualButton


var current_button_id := INVALID_BUTTON_ID
var loading_data := false

var capturing_shortcut := false
var current_shortcut: Dictionary = {}


func _ready():
	_connect_signals()
	_setup_key_popup()
	update_language()


# ---------------------------------------------------------
# SETUP
# ---------------------------------------------------------

func _connect_signals():
	browse_button.pressed.connect(_on_browse_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

	file_dialog.file_selected.connect(_on_file_selected)

	name_edit.text_changed.connect(_on_field_changed)
	path_edit.text_changed.connect(_on_field_changed)
	arguments_edit.text_changed.connect(_on_field_changed)

	shortcut_button.pressed.connect(_on_shortcut_pressed)
	manual_shortcut_button.pressed.connect(_on_manual_shortcut_pressed)
	clear_shortcut_button.pressed.connect(_on_clear_shortcut_pressed)

	apply_manual_button.pressed.connect(_on_apply_manual_pressed)


func _setup_key_popup():
	var popup := key_option.get_popup()

	popup.min_size = Vector2i(
		KEY_POPUP_WIDTH,
		0
	)

	popup.max_size = Vector2i(
		KEY_POPUP_WIDTH,
		KEY_POPUP_HEIGHT
	)


# ---------------------------------------------------------
# BUTTON SELECTION
# ---------------------------------------------------------

func open_for_button(button_id: int):
	current_button_id = button_id

	var data: Dictionary = ConfigManager.get_button(button_id)

	loading_data = true

	_set_fields(
		str(data.get("name", "")),
		str(data.get("path", "")),
		str(data.get("arguments", ""))
	)

	current_shortcut = data.get(
		"shortcut",
		{}
	).duplicate(true)

	_load_icon()

	loading_data = false

	visible = true

	_refresh_ui()


func clear_view():
	loading_data = true

	current_button_id = INVALID_BUTTON_ID

	_reset_editor_state()

	loading_data = false

	_refresh_ui()


func _reset_editor_state():
	_clear_fields()

	current_shortcut = {}
	capturing_shortcut = false

	icon_preview.texture = null

	manual_shortcut_popup.hide()


func _set_fields(
	button_name: String,
	path: String,
	arguments: String
):
	name_edit.text = button_name
	path_edit.text = path
	arguments_edit.text = arguments


func _clear_fields():
	_set_fields(
		"",
		"",
		""
	)


func _has_selected_button() -> bool:
	return current_button_id >= 1


# ---------------------------------------------------------
# UI REFRESH
# ---------------------------------------------------------

func _refresh_ui():
	_update_toolbox_title()
	_refresh_shortcut_ui()


func _refresh_shortcut_ui():
	update_shortcut_button()
	update_action_mode_ui()


func _update_toolbox_title():
	if not _has_selected_button():
		toolbox_label.text = tr("TOOLBOX")
		return

	toolbox_label.text = (
		tr("TOOLBOX")
		+ ": "
		+ tr("BUTTON")
		+ " "
		+ str(current_button_id)
	)


# ---------------------------------------------------------
# SAVE
# ---------------------------------------------------------

func save_current_button():
	if not _has_selected_button():
		return

	ConfigManager.set_button(
		current_button_id,
		name_edit.text,
		path_edit.text,
		arguments_edit.text,
		current_shortcut
	)

	refresh_stream_button()


func _save_and_refresh():
	save_current_button()
	_refresh_ui()


func refresh_stream_button():
	for button in get_tree().get_nodes_in_group(
		"stream_buttons"
	):
		if button.button_id == current_button_id:
			button.refresh()
			return


# ---------------------------------------------------------
# FIELDS
# ---------------------------------------------------------

func _on_field_changed(_text: String):
	if loading_data:
		return

	save_current_button()


func _on_delete_pressed():
	if not _has_selected_button():
		return

	loading_data = true

	ConfigManager.clear_button(current_button_id)
	IconManager.delete_icon(current_button_id)

	_reset_editor_state()

	loading_data = false

	_refresh_ui()
	refresh_stream_button()


# ---------------------------------------------------------
# APPLICATION
# ---------------------------------------------------------

func _on_browse_pressed():
	if not _has_selected_button():
		return

	file_dialog.popup_centered_ratio(0.7)


func _on_file_selected(path: String):
	if not _has_selected_button():
		return

	loading_data = true

	path_edit.text = path
	name_edit.text = get_application_name(path)

	_update_icon_preview_from_file(path)

	loading_data = false

	IconManager.extract_icon(
		path,
		current_button_id
	)

	save_current_button()


func _update_icon_preview_from_file(path: String):
	var texture = IconManager.extract_icon_temp(path)

	if texture != null:
		icon_preview.texture = texture


func _load_icon():
	icon_preview.texture = null

	if not _has_selected_button():
		return

	var icon_path := IconManager.get_icon_path(
		current_button_id
	)

	if not FileAccess.file_exists(icon_path):
		return

	var image := Image.new()

	if image.load(icon_path) != OK:
		return

	icon_preview.texture = ImageTexture.create_from_image(
		image
	)


func get_application_name(path: String) -> String:
	if path.get_extension().to_lower() == "lnk":
		return path.get_file().get_basename()

	var output: Array = []

	var safe_path := path.replace(
		"'",
		"''"
	)

	var command := (
		"(Get-Item -LiteralPath '%s').VersionInfo.FileDescription"
		% safe_path
	)

	var exit_code := OS.execute(
		"powershell.exe",
		[
			"-NoProfile",
			"-Command",
			command
		],
		output,
		true
	)

	if exit_code == 0 and not output.is_empty():
		var app_name := str(
			output[0]
		).strip_edges()

		if not app_name.is_empty():
			return app_name

	return path.get_file().get_basename()


# ---------------------------------------------------------
# SHORTCUT CAPTURE
# ---------------------------------------------------------

func _on_shortcut_pressed():
	if not _has_selected_button():
		return

	capturing_shortcut = true

	update_shortcut_button()

	shortcut_button.release_focus()


func _on_clear_shortcut_pressed():
	_apply_shortcut({})


func _input(event):
	if not capturing_shortcut:
		return

	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not _is_valid_shortcut_event(key_event):
		return

	var keycode := _get_event_keycode(key_event)

	if keycode == KEY_NONE:
		return

	if _is_modifier_key(keycode):
		return

	_apply_shortcut(
		_create_shortcut(
			keycode,
			key_event.ctrl_pressed,
			key_event.shift_pressed,
			key_event.alt_pressed,
			key_event.meta_pressed
		)
	)

	get_viewport().set_input_as_handled()


func _is_valid_shortcut_event(
	event: InputEventKey
) -> bool:
	return (
		event.pressed
		and not event.echo
	)


func _get_event_keycode(
	event: InputEventKey
) -> int:
	if event.keycode != KEY_NONE:
		return event.keycode

	return event.physical_keycode


func _is_modifier_key(keycode: int) -> bool:
	return keycode in MODIFIER_KEYS


func _create_shortcut(
	keycode: int,
	ctrl: bool,
	shift: bool,
	alt: bool,
	meta: bool
) -> Dictionary:
	return {
		"keycode": keycode,
		"ctrl": ctrl,
		"shift": shift,
		"alt": alt,
		"meta": meta
	}


func _apply_shortcut(shortcut: Dictionary):
	current_shortcut = shortcut.duplicate(true)
	capturing_shortcut = false

	_save_and_refresh()


# ---------------------------------------------------------
# SHORTCUT DISPLAY
# ---------------------------------------------------------

func update_shortcut_button():
	if capturing_shortcut:
		shortcut_button.text = tr(
			"PRESS_SHORTCUT"
		)
		return

	if current_shortcut.is_empty():
		shortcut_button.text = tr("NONE")
		return

	var parts: Array[String] = []

	_append_modifier_names(parts)

	var keycode := _get_current_keycode()

	parts.append(
		get_shortcut_key_name(keycode)
	)

	shortcut_button.text = " + ".join(parts)


func _append_modifier_names(
	parts: Array[String]
):
	if current_shortcut.get("ctrl", false):
		parts.append("Ctrl")

	if current_shortcut.get("shift", false):
		parts.append("Shift")

	if current_shortcut.get("alt", false):
		parts.append("Alt")

	if current_shortcut.get("meta", false):
		parts.append("Win")


func _get_current_keycode(
	default_key: int = KEY_NONE
) -> int:
	return int(
		current_shortcut.get(
			"keycode",
			default_key
		)
	)


func get_shortcut_key_name(
	keycode: int
) -> String:
	var translation_key := str(
		KEY_TRANSLATIONS.get(
			keycode,
			""
		)
	)

	if not translation_key.is_empty():
		return tr(translation_key)

	return OS.get_keycode_string(keycode)


# ---------------------------------------------------------
# ACTION MODE
# ---------------------------------------------------------

func update_action_mode_ui():
	var has_shortcut := (
		not current_shortcut.is_empty()
	)

	_set_application_fields_enabled(
		not has_shortcut
	)


func _set_application_fields_enabled(
	enabled: bool
):
	path_edit.editable = enabled
	arguments_edit.editable = enabled
	browse_button.disabled = not enabled

	var tooltip := ""

	if not enabled:
		tooltip = tr(
			"REMOVE_SHORTCUT_FIRST"
		)

	path_edit.tooltip_text = tooltip
	arguments_edit.tooltip_text = tooltip
	browse_button.tooltip_text = tooltip


# ---------------------------------------------------------
# MANUAL SHORTCUT
# ---------------------------------------------------------

func setup_manual_keys():
	key_option.clear()

	_add_key_range(KEY_A, KEY_Z)
	_add_key_range(KEY_0, KEY_9)
	_add_key_range(KEY_F1, KEY_F12)

	for keycode in SPECIAL_KEYS:
		add_manual_key(
			get_shortcut_key_name(keycode),
			keycode
		)

	for key_data in SYMBOL_KEYS:
		add_manual_key(
			str(key_data[0]),
			int(key_data[1])
		)


func _add_key_range(
	first_key: int,
	last_key: int
):
	for keycode in range(
		first_key,
		last_key + 1
	):
		add_manual_key(
			OS.get_keycode_string(keycode),
			keycode
		)


func add_manual_key(
	label: String,
	keycode: int
):
	key_option.add_item(label)

	key_option.set_item_metadata(
		key_option.item_count - 1,
		keycode
	)


func _on_manual_shortcut_pressed():
	if not _has_selected_button():
		return

	capturing_shortcut = false

	_load_manual_shortcut_controls()

	manual_shortcut_popup.popup_centered()


func _load_manual_shortcut_controls():
	ctrl_toggle.button_pressed = current_shortcut.get(
		"ctrl",
		false
	)

	shift_toggle.button_pressed = current_shortcut.get(
		"shift",
		false
	)

	alt_toggle.button_pressed = current_shortcut.get(
		"alt",
		false
	)

	win_toggle.button_pressed = current_shortcut.get(
		"meta",
		false
	)

	select_manual_key(
		_get_current_keycode(
			KEY_ESCAPE
		)
	)


func select_manual_key(keycode: int):
	for i in range(key_option.item_count):
		var item_keycode := int(
			key_option.get_item_metadata(i)
		)

		if item_keycode == keycode:
			key_option.select(i)
			return

	key_option.select(0)


func _on_apply_manual_pressed():
	if key_option.selected < 0:
		return

	var keycode := int(
		key_option.get_item_metadata(
			key_option.selected
		)
	)

	var shortcut := _create_shortcut(
		keycode,
		ctrl_toggle.button_pressed,
		shift_toggle.button_pressed,
		alt_toggle.button_pressed,
		win_toggle.button_pressed
	)

	manual_shortcut_popup.hide()

	_apply_shortcut(shortcut)


# ---------------------------------------------------------
# LANGUAGE
# ---------------------------------------------------------

func update_language():
	title_caption.text = tr("NAME") + ":"
	path_caption.text = tr("APPLICATION_PATH") + ":"
	arguments_caption.text = tr("ARGUMENTS") + ":"
	shortcut_caption.text = tr("SHORTCUT") + ":"

	manual_title_label.text = tr(
		"CHOOSE_SHORTCUT"
	)

	key_label.text = tr("KEY")

	manual_shortcut_button.text = tr(
		"MANUAL"
	)

	apply_manual_button.text = tr(
		"APPLY"
	)

	ctrl_toggle.text = "Ctrl"
	shift_toggle.text = "Shift"
	alt_toggle.text = "Alt"
	win_toggle.text = "Win"

	var selected_key := _get_current_keycode(
		KEY_ESCAPE
	)

	setup_manual_keys()
	select_manual_key(selected_key)

	_refresh_ui()
