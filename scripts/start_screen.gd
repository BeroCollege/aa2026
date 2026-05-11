extends Control

const MAIN_SCENE := "res://scenes/Main.tscn"
const START_BG_PATH := "res://assets/ui/bob_attack_start_screen.png"

const _SETTINGS_SECTION := "GameSettings"
const _KEY_MASTER_PCT := "master_volume_pct"
const _KEY_MUSIC_PCT := "music_volume_pct"
const _KEY_SFX_PCT := "sfx_volume_pct"
const _KEY_FULLSCREEN := "fullscreen"
const _KEY_VSYNC := "vsync"

const _BUS_MASTER := &"Master"
const _BUS_MUSIC := &"Music"
const _BUS_SFX := &"SFX"

@onready var _background_image: TextureRect = $BackgroundImage
@onready var _btn_start: Button = $MenuAnchor/Menu/BtnStart
@onready var _btn_settings: Button = $MenuAnchor/Menu/BtnSettings
@onready var _btn_quit: Button = $MenuAnchor/Menu/BtnQuit
@onready var _dialog: Panel = $Dialog
@onready var _dialog_title: Label = $Dialog/Margin/VBox/DialogTitle
@onready var _settings_panel: Control = $Dialog/Margin/VBox/SettingsPanel
@onready var _slider_master: HSlider = $Dialog/Margin/VBox/SettingsPanel/VolumeRows/MasterRow/SliderMaster
@onready var _lbl_master_pct: Label = $Dialog/Margin/VBox/SettingsPanel/VolumeRows/MasterRow/LblMasterPct
@onready var _slider_music: HSlider = $Dialog/Margin/VBox/SettingsPanel/VolumeRows/MusicRow/SliderMusic
@onready var _lbl_music_pct: Label = $Dialog/Margin/VBox/SettingsPanel/VolumeRows/MusicRow/LblMusicPct
@onready var _slider_sfx: HSlider = $Dialog/Margin/VBox/SettingsPanel/VolumeRows/SfxRow/SliderSfx
@onready var _lbl_sfx_pct: Label = $Dialog/Margin/VBox/SettingsPanel/VolumeRows/SfxRow/LblSfxPct
@onready var _chk_fullscreen: CheckBox = $Dialog/Margin/VBox/SettingsPanel/ChkFullscreen
@onready var _chk_vsync: CheckBox = $Dialog/Margin/VBox/SettingsPanel/ChkVsync
@onready var _keybinds_label: Label = $Dialog/Margin/VBox/SettingsPanel/KeybindsLabel
@onready var _dialog_back: Button = $Dialog/Margin/VBox/DialogBack

var _suppress_settings_persist: bool = false

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
	_btn_quit.pressed.connect(_on_quit_pressed)
	_dialog_back.pressed.connect(_close_dialog)
	_dialog.visible = false

	_slider_master.value_changed.connect(_on_master_volume_changed)
	_slider_music.value_changed.connect(_on_music_volume_changed)
	_slider_sfx.value_changed.connect(_on_sfx_volume_changed)
	_chk_fullscreen.toggled.connect(_on_fullscreen_toggled)
	_chk_vsync.toggled.connect(_on_vsync_toggled)

	_apply_saved_game_settings_at_startup()

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
	_settings_panel.visible = true
	_keybinds_label.text = "Keybinds:\n\n%s" % _build_keybinds_text()
	_refresh_settings_widgets_from_disk()
	_open_dialog()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _open_dialog() -> void:
	_dialog.visible = true
	_dialog_back.grab_focus()


func _close_dialog() -> void:
	_dialog.visible = false
	_settings_panel.visible = false
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


func _default_game_settings() -> Dictionary:
	return {
		_KEY_MASTER_PCT: 100.0,
		_KEY_MUSIC_PCT: 100.0,
		_KEY_SFX_PCT: 100.0,
		_KEY_FULLSCREEN: false,
		_KEY_VSYNC: true,
	}


func _read_game_settings_from_disk() -> Dictionary:
	var out := _default_game_settings()
	var cfg := ConfigFile.new()
	if cfg.load(RunRecords.SETTINGS_PATH) != OK:
		return out
	for k in out.keys():
		if cfg.has_section_key(_SETTINGS_SECTION, k):
			out[k] = cfg.get_value(_SETTINGS_SECTION, k)
	return out


func _apply_saved_game_settings_at_startup() -> void:
	var s := _read_game_settings_from_disk()
	_apply_bus_volume_pct(_BUS_MASTER, float(s[_KEY_MASTER_PCT]))
	_apply_bus_volume_pct(_BUS_MUSIC, float(s[_KEY_MUSIC_PCT]))
	_apply_bus_volume_pct(_BUS_SFX, float(s[_KEY_SFX_PCT]))
	_apply_fullscreen(bool(s[_KEY_FULLSCREEN]))
	_apply_vsync(bool(s[_KEY_VSYNC]))


func _refresh_settings_widgets_from_disk() -> void:
	var s := _read_game_settings_from_disk()
	_suppress_settings_persist = true
	_slider_master.value = float(s[_KEY_MASTER_PCT])
	_slider_music.value = float(s[_KEY_MUSIC_PCT])
	_slider_sfx.value = float(s[_KEY_SFX_PCT])
	_chk_fullscreen.button_pressed = bool(s[_KEY_FULLSCREEN])
	_chk_vsync.button_pressed = bool(s[_KEY_VSYNC])
	_update_volume_pct_labels()
	_suppress_settings_persist = false


func _persist_game_settings_merge() -> void:
	if _suppress_settings_persist:
		return
	var cfg := ConfigFile.new()
	cfg.load(RunRecords.SETTINGS_PATH)
	cfg.set_value(_SETTINGS_SECTION, _KEY_MASTER_PCT, _slider_master.value)
	cfg.set_value(_SETTINGS_SECTION, _KEY_MUSIC_PCT, _slider_music.value)
	cfg.set_value(_SETTINGS_SECTION, _KEY_SFX_PCT, _slider_sfx.value)
	cfg.set_value(_SETTINGS_SECTION, _KEY_FULLSCREEN, _chk_fullscreen.button_pressed)
	cfg.set_value(_SETTINGS_SECTION, _KEY_VSYNC, _chk_vsync.button_pressed)
	cfg.save(RunRecords.SETTINGS_PATH)


func _apply_bus_volume_pct(bus_name: StringName, pct: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var lin := clampf(pct / 100.0, 0.0, 1.0)
	if lin <= 0.0001:
		AudioServer.set_bus_mute(idx, true)
		return
	AudioServer.set_bus_mute(idx, false)
	AudioServer.set_bus_volume_db(idx, linear_to_db(lin))


func _apply_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_vsync(enabled: bool) -> void:
	var mode := DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


func _update_volume_pct_labels() -> void:
	_lbl_master_pct.text = "%d%%" % int(round(_slider_master.value))
	_lbl_music_pct.text = "%d%%" % int(round(_slider_music.value))
	_lbl_sfx_pct.text = "%d%%" % int(round(_slider_sfx.value))


func _on_master_volume_changed(value: float) -> void:
	if _suppress_settings_persist:
		return
	_apply_bus_volume_pct(_BUS_MASTER, value)
	_lbl_master_pct.text = "%d%%" % int(round(value))
	_persist_game_settings_merge()


func _on_music_volume_changed(value: float) -> void:
	if _suppress_settings_persist:
		return
	_apply_bus_volume_pct(_BUS_MUSIC, value)
	_lbl_music_pct.text = "%d%%" % int(round(value))
	_persist_game_settings_merge()


func _on_sfx_volume_changed(value: float) -> void:
	if _suppress_settings_persist:
		return
	_apply_bus_volume_pct(_BUS_SFX, value)
	_lbl_sfx_pct.text = "%d%%" % int(round(value))
	_persist_game_settings_merge()


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if _suppress_settings_persist:
		return
	_apply_fullscreen(button_pressed)
	_persist_game_settings_merge()


func _on_vsync_toggled(button_pressed: bool) -> void:
	if _suppress_settings_persist:
		return
	_apply_vsync(button_pressed)
	_persist_game_settings_merge()
