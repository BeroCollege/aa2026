extends Control

const MAIN_SCENE := "res://scenes/Main.tscn"
const START_BG_PATH := "res://assets/ui/bob_attack_start_screen.png"

@onready var _background_image: TextureRect = $BackgroundImage
@onready var _btn_start: Button = $MenuAnchor/Menu/BtnStart
@onready var _btn_settings: Button = $MenuAnchor/Menu/BtnSettings
@onready var _btn_credits: Button = $MenuAnchor/Menu/BtnCredits
@onready var _btn_quit: Button = $MenuAnchor/Menu/BtnQuit
@onready var _dialog: Panel = $Dialog
@onready var _dialog_title: Label = $Dialog/Margin/VBox/DialogTitle
@onready var _dialog_body: Label = $Dialog/Margin/VBox/DialogBody
@onready var _dialog_back: Button = $Dialog/Margin/VBox/DialogBack

## Order matches `project.godot` gameplay actions (readable labels).
const _ACTION_LABELS: Array = [
	["move_left", "Move left"],
	["move_right", "Move right"],
	["move_up", "Move up / climb intent"],
	["move_down", "Move down"],
	["jump", "Jump"],
	["interact", "Interact / gather"],
	["craft_tool", "Craft menu (toggle)"],
	["feed_bob", "Feed B.O.B."],
	["place_block", "Place block"],
	["mine_block", "Mine / break"],
	["cycle_place_kind", "Cycle place material"],
	["place_totem", "Place calm totem"],
	["toggle_debug_mode", "Toggle debug overlay"],
]


func _ready() -> void:
	# Bypass broken/missing `.png.import` (valid=false leaves TextureRect empty → gray screen).
	_apply_start_screen_background_texture()
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_credits.pressed.connect(_on_credits_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_dialog_back.pressed.connect(_close_dialog)
	_dialog.visible = false
	_btn_start.grab_focus()


func _apply_start_screen_background_texture() -> void:
	var disk_path := ProjectSettings.globalize_path(START_BG_PATH)
	var img := _load_image_from_file_ignore_extension(disk_path)
	if img == null:
		push_warning(
			"Start screen: could not load background image at %s "
			+ "(file missing, or wrong format — e.g. JPEG saved as .png)."
			% disk_path
		)
		return
	_background_image.texture = ImageTexture.create_from_image(img)


## `Image.load_from_file` picks a decoder from the file extension. Assets sometimes use a
## `.png` filename with JPEG (or other) bytes; decode by trying formats explicitly.
func _load_image_from_file_ignore_extension(absolute_path: String) -> Image:
	if not FileAccess.file_exists(absolute_path):
		return null
	var f := FileAccess.open(absolute_path, FileAccess.READ)
	if f == null:
		return null
	var buf: PackedByteArray = f.get_buffer(f.get_length())
	if buf.is_empty():
		return null
	var img := Image.new()
	if img.load_png_from_buffer(buf) == OK:
		return img
	if img.load_jpg_from_buffer(buf) == OK:
		return img
	if img.load_webp_from_buffer(buf) == OK:
		return img
	return null


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_settings_pressed() -> void:
	_dialog_title.text = "Settings"
	_dialog_body.text = "Coming soon."
	_open_dialog()


func _on_credits_pressed() -> void:
	_dialog_title.text = "Credits"
	_dialog_body.text = "Coming soon.\n\nKeybinds:\n%s" % _build_keybinds_text()
	_open_dialog()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _open_dialog() -> void:
	_dialog.visible = true


func _close_dialog() -> void:
	_dialog.visible = false
	_btn_start.grab_focus()


func _format_action_line(action: String, label: String) -> String:
	if not InputMap.has_action(action):
		return ""
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "%s: (not bound)" % label
	var parts: PackedStringArray = []
	for ev in events:
		if ev is InputEvent:
			parts.append((ev as InputEvent).as_text())
	return "%s: %s" % [label, ", ".join(parts)]


func _build_keybinds_text() -> String:
	var lines: PackedStringArray = []
	for row in _ACTION_LABELS:
		var action: String = row[0]
		var lbl: String = row[1]
		var line := _format_action_line(action, lbl)
		if not line.is_empty():
			lines.append(line)
	lines.append("")
	lines.append("[1–5] Select tool — sword, pickaxe, axe, shovel, hoe")
	lines.append("[6] Craft shovel (while craft menu is open)")
	return "\n".join(lines)
