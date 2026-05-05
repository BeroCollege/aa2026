extends Panel
## This panel uses PROCESS_MODE_ALWAYS so Escape still closes pause while the scene tree is paused.

signal resume_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
