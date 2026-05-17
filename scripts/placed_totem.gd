extends Area2D

## A Calm Totem placed by the player. While B.O.B. is inside its aura,
## his autonomous behavior is forced into FRIENDLY mode. The aura lasts
## briefly, so players need to choose when to spend one.

@export var aura_radius: float = 200.0
@export var pulse_speed: float = 1.6
@export var lifetime_seconds: float = 60.0

var _pulse_t: float = 0.0
var _bob_inside_count: int = 0
var _bob_inside: Node = null

@onready var _aura: Polygon2D = $Aura
@onready var _shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("calm_totem")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = aura_radius
	z_index = 1
	get_tree().create_timer(lifetime_seconds).timeout.connect(_expire, CONNECT_ONE_SHOT)

func _process(delta: float) -> void:
	_pulse_t += delta * pulse_speed
	if _aura:
		var s := 0.92 + 0.08 * sin(_pulse_t)
		_aura.scale = Vector2(s, s)
		var a := 0.10 + 0.05 * (0.5 + 0.5 * sin(_pulse_t))
		var col := _aura.color
		col.a = a
		_aura.color = col

func _on_body_entered(body: Node) -> void:
	if not body:
		return
	if body.is_in_group("bob_agent"):
		_bob_inside_count += 1
		_bob_inside = body
		if body.has_method("set_calm_aura_active"):
			body.set_calm_aura_active(true)

func _on_body_exited(body: Node) -> void:
	if not body:
		return
	if body.is_in_group("bob_agent"):
		_bob_inside_count = maxi(0, _bob_inside_count - 1)
		if _bob_inside_count == 0 and body.has_method("set_calm_aura_active"):
			body.set_calm_aura_active(false)
			_bob_inside = null

func _expire() -> void:
	if _bob_inside and is_instance_valid(_bob_inside) and _bob_inside.has_method("set_calm_aura_active"):
		_bob_inside.set_calm_aura_active(false)
	queue_free()
