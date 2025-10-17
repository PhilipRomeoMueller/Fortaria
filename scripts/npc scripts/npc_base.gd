extends CharacterBody2D

# enums
enum IdleDirection { STAY, UP, DOWN, LEFT, RIGHT }
enum State { IDLE, WALK, ATTACK }

# stats
@export var speed := 80.0
@export var health := 100
@export var attack_damage := 10
@export var attack_cooldown := 1.5
@export var team := 1
@export var idle_direction_choice : IdleDirection = IdleDirection.STAY
@export var idle_speed := 60.0
@export var detection_radius: float = 100.0

# variables
var target: CharacterBody2D
var can_attack := true
var state: State = State.IDLE
var is_selected := false
var manual_target_pos: Vector2 = Vector2.ZERO
var last_facing := "down_right" # letze direction
var facing_left := false  # animationen umdrehen

# Vererbungs nodes
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer := $Timer
@onready var detection_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var click_area: Area2D = $Area2D  # Für click-to-select

# setup
func _ready():
	add_to_group("npc")

	if detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_radius

	timer.wait_time = attack_cooldown
	timer.connect("timeout", Callable(self, "_on_attack_cooldown"))

	# Detection signals
	$Area2D.connect("body_entered", Callable(self, "_on_area_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_area_exited"))

	# Click-to-select setup
	click_area.input_pickable = true
	click_area.connect("input_event", Callable(self, "_on_area_input_event"))

	update_animation()

# main loop
func _physics_process(delta):
	if target and is_instance_valid(target):
		chase_and_attack(delta)
	elif not nav_agent.is_navigation_finished():
		follow_manual_path(delta)
	else:
		idle_move(delta)

# idle movement
func idle_move(delta):
	var dir := get_idle_vector()
	velocity = dir * idle_speed
	move_and_slide()

	state = State.IDLE if dir == Vector2.ZERO else State.WALK
	update_animation()

func get_idle_vector() -> Vector2:
	match idle_direction_choice:
		IdleDirection.STAY:
			return Vector2.ZERO
		IdleDirection.UP:
			return Vector2.UP
		IdleDirection.DOWN:
			return Vector2.DOWN
		IdleDirection.LEFT:
			return Vector2.LEFT
		IdleDirection.RIGHT:
			return Vector2.RIGHT
		_:
			return Vector2.ZERO

# chase and attack function
func chase_and_attack(delta):
	if global_position.distance_to(target.global_position) > 40:
		nav_agent.target_position = target.global_position
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		state = State.WALK
	else:
		velocity = Vector2.ZERO
		state = State.ATTACK
		attack(target)

	update_animation()

# click-to-move path following
func follow_manual_path(delta):
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	state = State.WALK
	update_animation()

# detection events
func _on_area_entered(body):
	if body.is_in_group("npc") and body.team != team:
		target = body

func _on_area_exited(body):
	if body == target:
		target = null

# combat
func attack(enemy):
	if can_attack and is_instance_valid(enemy) and enemy.team != team:
		can_attack = false

		# Determine facing direction based on enemy position
		var dir_to_enemy = (enemy.global_position - global_position).normalized()
		_set_attack_direction(dir_to_enemy)

		enemy.take_damage(attack_damage)
		timer.start()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func _on_attack_cooldown():
	can_attack = true

# clicken ´bug fix 12
func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().call_group("npc", "set_selected", false)
		is_selected = true
		print(name, "selected")

func set_selected(value: bool):
	is_selected = value

# click-to-move
func move_to_point(point: Vector2):
	target = null
	manual_target_pos = point
	nav_agent.target_position = point
	state = State.WALK

# animation handlinggg
func update_animation():
	var anim_prefix := ""
	var anim_action := ""

	# Decide animation state
	match state:
		State.IDLE:
			anim_action = "idle"
		State.WALK:
			anim_action = "walk"
		State.ATTACK:
			anim_action = "attack"

	# directions for animations (with mirror flip)
	var dir = velocity.normalized()

	if state == State.ATTACK and target and is_instance_valid(target):
		# Attack facing direction already set by _set_attack_direction()
		anim_prefix = last_facing
	else:
		if dir == Vector2.ZERO:
			anim_prefix = _get_facing_prefix()
		else:
			if abs(dir.x) > abs(dir.y):
				if dir.x > 0:
					anim_prefix = "down_right"
					facing_left = false
				else:
					anim_prefix = "down_right" # mirror
					facing_left = true
			else:
				if dir.y > 0:
					anim_prefix = "down_right"
					facing_left = false
				else:
					anim_prefix = "up_left"
					facing_left = dir.x < 0
			last_facing = anim_prefix

	var anim_name = anim_action + "_" + anim_prefix

	if not sprite.sprite_frames.has_animation(anim_name):
		anim_name = anim_action + "_down_right"

	sprite.flip_h = facing_left
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _set_attack_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			last_facing = "down_right"
			facing_left = false
		else:
			last_facing = "down_right"
			facing_left = true
	else:
		if dir.y > 0:
			last_facing = "down_right"
			facing_left = false
		else:
			last_facing = "up_left"
			facing_left = dir.x < 0

func _get_facing_prefix() -> String:
	return last_facing
