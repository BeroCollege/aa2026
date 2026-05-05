extends RefCounted
class_name ToolStripIcons

## Horizontal strip: sword | pickaxe | axe | shovel | hoe (left → right).
const STRIP_PATH := "res://assets/tools/tool_strip.png"
const SLICE_MAIN := 205
const SLICE_LAST := 204
const SLICE_H := 229
## Trim shared column boundaries so rotated sprites do not sample the next tool (brown / color streaks).
const ATLAS_INSET := 2

static var _strip_cache: Texture2D

## Strip was flattened to opaque black when it was JPEG; clear PNGs keep alpha. This removes near-black backdrop only.
static func _apply_nearblack_transparent(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var p := img.get_pixel(x, y)
			if p.a < 0.001:
				continue
			# Background is pure/near black; tool pixels stay above this (browns, greys, metals).
			if p.r < 0.035 and p.g < 0.035 and p.b < 0.035:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

## Cached strip texture. Prefer decoding PNG from disk so a missing/invalid `.import` does not break the game.
static func strip_texture() -> Texture2D:
	if _strip_cache:
		return _strip_cache
	if FileAccess.file_exists(STRIP_PATH):
		var buf := FileAccess.get_file_as_bytes(STRIP_PATH)
		if not buf.is_empty():
			var img := Image.new()
			if img.load_png_from_buffer(buf) == OK:
				_apply_nearblack_transparent(img)
				_strip_cache = ImageTexture.create_from_image(img)
				return _strip_cache
	var tex: Texture2D = ResourceLoader.load(STRIP_PATH, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if tex:
		var img2 := tex.get_image()
		if img2:
			_apply_nearblack_transparent(img2)
			_strip_cache = ImageTexture.create_from_image(img2)
		else:
			_strip_cache = tex
		return _strip_cache
	push_error("ToolStripIcons: could not read %s as PNG or imported texture." % STRIP_PATH)
	return null

static func region_for_tool(tool: String) -> Rect2:
	match tool:
		"sword":
			return Rect2(0, 0, SLICE_MAIN - ATLAS_INSET, SLICE_H)
		"pickaxe":
			return Rect2(SLICE_MAIN + ATLAS_INSET, 0, SLICE_MAIN - 2 * ATLAS_INSET, SLICE_H)
		"axe":
			return Rect2(SLICE_MAIN * 2 + ATLAS_INSET, 0, SLICE_MAIN - 2 * ATLAS_INSET, SLICE_H)
		"shovel":
			return Rect2(SLICE_MAIN * 3 + ATLAS_INSET, 0, SLICE_MAIN - 2 * ATLAS_INSET, SLICE_H)
		"hoe":
			return Rect2(SLICE_MAIN * 4 + ATLAS_INSET, 0, SLICE_LAST - ATLAS_INSET, SLICE_H)
		_:
			return Rect2(0, 0, SLICE_MAIN - ATLAS_INSET, SLICE_H)

static func atlas_texture_for_tool(tool: String) -> AtlasTexture:
	var strip := strip_texture()
	var a := AtlasTexture.new()
	a.atlas = strip
	a.region = region_for_tool(tool)
	return a
