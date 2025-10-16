extends CharacterBody2D

# enums
enum IdleDirection { STAY, UP, DOWN, LEFT, RIGHT }
enum State { IDLE, WALK, ATTACK }

# statsss
@export var speed := 80.0
@export var health := 100
@export var attack_damage := 10
@export var attack_cooldown := 1.5
@export var team := 1
@export var idle_direction_choice : IdleDirection = IdleDirection.STAY
@export var idle_speed := 60.0
@export var detection_radius: float = 100.0   # Circle detection radius

# variables
var target: CharacterBody2D
var can_attack := true
var state: State = State.IDLE

# child nodes
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer := $Timer
@onready var detection_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("npc")

	# Set detection radius
	if detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_radius

	# Timer setup
	timer.wait_time = attack_cooldown
	timer.connect("timeout", Callable(self, "_on_attack_cooldown"))

	# Detection signals
	$Area2D.connect("body_entered", Callable(self, "_on_area_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_area_exited"))

	update_animation()

func _physics_process(delta):
	if target and is_instance_valid(target):
		chase_and_attack(delta)
	else:
		idle_move(delta)

# idle movemnet
func idle_move(delta):
	var dir := get_idle_vector()
	velocity = dir * idle_speed
	move_and_slide()

	# updates animation
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

# chase und attacke
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

# Sieht gengner
func _on_area_entered(body):
	if body.is_in_group("npc") and body.team != team:
		target = body

func _on_area_exited(body):
	if body == target:
		target = null

#Kampf
func attack(enemy):
	if can_attack and is_instance_valid(enemy) and enemy.team != team:
		can_attack = false
		enemy.take_damage(attack_damage)
		timer.start()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func _on_attack_cooldown():
	can_attack = true

# animation für verschiedene states
func update_animation():
	match state:
		State.IDLE:
			if sprite.animation != "idle":
				sprite.play("idle")
		State.WALK:
			if sprite.animation != "walk":
				sprite.play("walk")
		State.ATTACK:
			if sprite.animation != "attack":
				sprite.play("attack")
