extends Node

const CONFIG_PATH := "user://config.json"

const PAGE_COUNT := 4
const BUTTON_COUNT := 15


var current_page := 1

var config: Dictionary = {}


func _ready():
	load_config()


# ---------------------------------------------------------
# CONFIG
# ---------------------------------------------------------

func create_default_config():
	config = {
		"current_page": 1,
		"pages": {}
	}

	current_page = 1

	ensure_pages()


func save_config():
	config["current_page"] = current_page

	var file := FileAccess.open(
		CONFIG_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("Nie udało się zapisać config.json")
		return

	file.store_string(
		JSON.stringify(config, "\t")
	)

	file.close()


func load_config():
	if not FileAccess.file_exists(CONFIG_PATH):
		create_default_config()
		save_config()
		return

	var file := FileAccess.open(
		CONFIG_PATH,
		FileAccess.READ
	)

	if file == null:
		create_default_config()
		return

	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)

	if data is not Dictionary:
		create_default_config()
		save_config()
		return

	if data.has("buttons") and not data.has("pages"):
		config = {
			"current_page": 1,
			"pages": {
				"1": {
					"buttons": data.get("buttons", {})
				}
			}
		}
	else:
		config = data

	current_page = int(
		config.get("current_page", 1)
	)

	if current_page < 1 or current_page > PAGE_COUNT:
		current_page = 1

	ensure_pages()
	save_config()


func ensure_pages():
	if not config.has("pages"):
		config["pages"] = {}

	for page_id in range(1, PAGE_COUNT + 1):
		var page_key := str(page_id)

		if not config["pages"].has(page_key):
			config["pages"][page_key] = {
				"buttons": {}
			}

		elif not config["pages"][page_key].has("buttons"):
			config["pages"][page_key]["buttons"] = {}


# ---------------------------------------------------------
# PAGES
# ---------------------------------------------------------

func set_current_page(page_id: int):
	if page_id < 1 or page_id > PAGE_COUNT:
		return

	if current_page == page_id:
		return

	current_page = page_id

	save_config()


func get_current_page() -> int:
	return current_page


func get_page_count() -> int:
	return PAGE_COUNT


# ---------------------------------------------------------
# BUTTONS
# ---------------------------------------------------------

func set_button(
	button_id: int,
	button_name: String,
	path: String,
	arguments: String = "",
	shortcut: Dictionary = {}
):
	if not _is_valid_button(button_id):
		return

	var buttons := _get_buttons_for_page(current_page)

	buttons[str(button_id)] = {
		"name": button_name,
		"path": path,
		"arguments": arguments,
		"shortcut": shortcut
	}

	save_config()


func get_button(button_id: int) -> Dictionary:
	if not _is_valid_button(button_id):
		return {}

	var buttons := _get_buttons_for_page(current_page)

	return buttons.get(
		str(button_id),
		{}
	)


func clear_button(button_id: int):
	if not _is_valid_button(button_id):
		return

	var buttons := _get_buttons_for_page(current_page)

	buttons.erase(str(button_id))

	save_config()


# ---------------------------------------------------------
# PAGE CLEAR
# ---------------------------------------------------------

func clear_current_page():
	config["pages"][str(current_page)] = {
		"buttons": {}
	}

	save_config()


# ---------------------------------------------------------
# FULL RESET
# ---------------------------------------------------------

func clear_all():
	create_default_config()
	save_config()


# ---------------------------------------------------------
# INTERNAL
# ---------------------------------------------------------

func _get_buttons_for_page(page_id: int) -> Dictionary:
	ensure_pages()

	return config["pages"][str(page_id)]["buttons"]


func _is_valid_button(button_id: int) -> bool:
	return (
		button_id >= 1
		and button_id <= BUTTON_COUNT
	)
