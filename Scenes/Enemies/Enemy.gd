class_name Enemy
extends CharacterBody2D
## Clase base para todos los enemigos. Gestiona salud, recepción de daño con
## parpadeo blanco, knockback, detección de bordes y daño por contacto al jugador.

signal died(enemy_position: Vector2)

@export var data: EnemyData
@export var gravity: float = 720.0
@export var knockback_force: Vector2 = Vector2(110.0, -90.0)

var current_health: int = 2
var facing_direction: int = 1
var target_player: Player = null
var is_hurt: bool = false
var _hurt_timer: float = 0.0

@onready var visuals: Node2D = $Visuals
@onready var edge_ray: RayCast2D = $Visuals/EdgeRayCast
@onready var detection_area: Area2D = $DetectionArea
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	if data:
		current_health = data.max_health

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if is_hurt:
		_hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		if _hurt_timer <= 0.0:
			is_hurt = false
			visuals.modulate = Color.WHITE
	else:
		_behavior_process(delta)

	move_and_slide()
	_check_continuous_player_contact()


## Método virtual pensado para que cada enemigo concreto (Goblin, Esqueleto, Orco) lo sobreescriba.
func _behavior_process(_delta: float) -> void:
	pass


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 320.0)


func set_facing_direction(dir: int) -> void:
	if dir != facing_direction and dir != 0:
		facing_direction = dir
		visuals.scale.x = float(facing_direction)


func take_damage(amount: int, source_position: Vector2) -> void:
	if current_health <= 0:
		return

	current_health -= amount
	is_hurt = true
	_hurt_timer = 0.16

	# Parpadeo blanco de impacto (se ve brillante usando modulate alto).
	visuals.modulate = Color(3.0, 3.0, 3.0, 1.0)

	var resistance: float = data.knockback_resistance if data else 1.0
	var dir_x: float = signf(global_position.x - source_position.x)
	if dir_x == 0.0:
		dir_x = float(-facing_direction)

	velocity = Vector2(dir_x * (knockback_force.x / resistance), knockback_force.y / resistance)

	if current_health <= 0:
		_die()


func _die() -> void:
	died.emit(global_position)
	queue_free()


func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		target_player = body


func _on_detection_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null


func _on_hurtbox_body_entered(body: Node2D) -> void:
	_damage_player(body)


func _check_continuous_player_contact() -> void:
	# Permite volver a dañar al jugador si sigue tocando al enemigo cuando acaba su invulnerabilidad.
	for body: Node2D in hurtbox.get_overlapping_bodies():
		_damage_player(body)


func _damage_player(body: Node2D) -> void:
	if body is Player and body.stats:
		body.stats.take_hit(global_position)
