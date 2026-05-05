extends Control

const MAIN_SCENE := "res://scenes/Main.tscn"

@onready var _title: Label = $Center/Layout/Title
@onready var _btn_start: Button = $Center/Layout/Buttons/BtnStart
@onready var _btn_best: Button = $Center/Layout/Buttons/BtnBest
@onready var _btn_keys: Button = $Center/Layout/Buttons/BtnKeys
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
	_title.text = "BOB Attack"
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_best.pressed.connect(_on_best_pressed)
	_btn_keys.pressed.connect(_on_keys_pressed)
	_dialog_back.pressed.connect(_close_dialog)
	_dialog.visible = false


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_best_pressed() -> void:
	var best: float = RunRecords.load_best_survival_seconds()
	_dialog_title.text = "Best run"
	if best < 0.0:
		_dialog_body.text = "Longest survival: --:--\n\nPlay a run — your best time is saved when the run ends."
	else:
		_dialog_body.text = "Longest survival: %s" % RunRecords.format_mm_ss(best)
	_open_dialog()


func _on_keys_pressed() -> void:
	_dialog_title.text = "Keybinds"
	_dialog_body.text = _build_keybinds_text()
	_open_dialog()


func _open_dialog() -> void:
	_dialog.visible = true


func _close_dialog() -> void:
	_dialog.visible = false


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
