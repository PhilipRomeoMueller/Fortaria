extends CharacterBody2D

const SPEED: float = 200.0
const STOP_DISTANCE: float = 4.0

var target_position: Vector2
var has_target: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = get_global_mouse_position()
		has_target = true

func _physics_process(delta: float) -> void:
	if has_target:
		var to_target = target_position - global_position

		# Move directly toward the target (allows 8-direction movement)
		var direction = to_target.normalized()
		velocity = direction * SPEED

		# Stop when close enough
		if global_position.distance_to(target_position) < STOP_DISTANCE:
			velocity = Vector2.ZERO
			has_target = false
	else:
		velocity = Vector2.ZERO

	move_and_slide()
