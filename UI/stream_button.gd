extends Button

@export var button_id: int = 1

var last_click_time := -1000
var tween: Tween

var glow_tween: Tween

func _ready():
	add_to_group("stream_buttons")

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	call_deferred("_setup_pivot")

	load_button()

func _setup_pivot():
	pivot_offset = size / 2.0

func load_button():
	var data = ConfigManager.get_button(button_id)

	if data.is_empty():
		%Icon.texture = null
		%NameLabel.text = ""
		%NameBar.visible = false
		return

	%NameLabel.text = data.get("name", "")
	%NameBar.visible = true

	load_icon()

func load_icon():
	var icon_path = IconManager.get_icon_path(button_id)

	if not FileAccess.file_exists(icon_path):
		%Icon.texture = null
		return

	var image = Image.new()

	if image.load(icon_path) != OK:
		%Icon.texture = null
		return

	%Icon.texture = ImageTexture.create_from_image(image)


func _on_mouse_entered():
	animate_keycap(Vector2(1.04, 1.04), 0.12)


func _on_mouse_exited():
	animate_keycap(Vector2.ONE, 0.12)


func _on_button_down():
	var current_time = Time.get_ticks_msec()

	if current_time - last_click_time < 400:
		var main = get_tree().current_scene
		main.open_settings(button_id)

	last_click_time = current_time

	animate_keycap(Vector2(0.94, 0.94), 0.06)


func _on_button_up():
	if is_hovered():
		animate_keycap(Vector2(1.04, 1.04), 0.10)
	else:
		animate_keycap(Vector2.ONE, 0.10)


func animate_keycap(target_scale: Vector2, duration: float):
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"scale",
		target_scale,
		duration
	)


func refresh():
	load_button()


func refresh_icon():
	load_icon()

func get_executable_name(exe_path: String) -> String:
	var output: Array = []

	var exit_code = OS.execute(
		"powershell.exe",
		[
			"-NoProfile",
			"-Command",
			"(Get-Item -LiteralPath '%s').VersionInfo.FileDescription" % exe_path.replace("'", "''")
		],
		output,
		true
	)

	if exit_code == 0 and not output.is_empty():
		var exe_name = str(output[0]).strip_edges()

		if not exe_name.is_empty():
			return exe_name

	return exe_path.get_file().get_basename()

func press_visual():
	
	animate_keycap(Vector2(0.94, 0.94), 0.06)

	await get_tree().create_timer(0.08).timeout

	if is_hovered():
		animate_keycap(Vector2(1.04, 1.04), 0.10)
	else:
		animate_keycap(Vector2.ONE, 0.10)
