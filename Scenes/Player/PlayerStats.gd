class_name PlayerStats
extends Node
## Gestiona los puntos de vida (10 = 5 corazones) y escudos (máximo 5) del jugador.
## Emite señales cuando cambian los valores para actualizar el HUD sin acoplamiento.

signal health_changed(current_health: int, max_health: int)
signal shields_changed(current_shields: int, max_shields: int)
signal damaged(knockback_direction: Vector2)
signal died

@export var max_health: int = 10
@export var max_shields: int = 5
@export var invulnerability_duration: float = 1.0

var health: int = 10
var shields: int = 0
var is_invulnerable: bool = false

var _invuln_timer: float = 0.0


func _ready() -> void:
	health = max_health
	# Emitimos el estado inicial al final del primer frame para que el HUD se sincronice.
	call_deferred("_emit_initial_state")


func _process(delta: float) -> void:
	if is_invulnerable:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			is_invulnerable = false


func _emit_initial_state() -> void:
	health_changed.emit(health, max_health)
	shields_changed.emit(shields, max_shields)


func take_hit(source_position: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or health <= 0:
		return

	# Regla de diseño: todo golpe quita 1 escudo si hay escudos, o 1 punto de vida (0.5 corazones).
	if shields > 0:
		shields = maxi(0, shields - 1)
		shields_changed.emit(shields, max_shields)
	else:
		health = maxi(0, health - 1)
		health_changed.emit(health, max_health)

	is_invulnerable = true
	_invuln_timer = invulnerability_duration

	var knockback_dir: Vector2 = Vector2.ZERO
	if get_parent() is Node2D and source_position != Vector2.ZERO:
		knockback_dir = (get_parent().global_position - source_position).normalized()

	damaged.emit(knockback_dir)

	if health <= 0:
		died.emit()


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func add_shields(amount: int) -> void:
	shields = mini(max_shields, shields + amount)
	shields_changed.emit(shields, max_shields)
