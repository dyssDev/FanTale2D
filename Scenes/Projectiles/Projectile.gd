class_name Projectile
extends Area2D
## Proyectil genérico para flechas del jugador, huesos del Esqueleto y ataques del Jefe.

@export var speed: float = 180.0
@export var damage: int = 1
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.RIGHT
var shooter_is_player: bool = true

@onready var visual: ColorRect = $ColorRect


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

	# Configurar máscaras de colisión según quién dispara:
	# Layer 1 = World, Layer 2 = Player, Layer 3 = Enemies
	collision_layer = 0
	collision_mask = 1 # Siempre choca con paredes/suelo
	if shooter_is_player:
		set_collision_mask_value(3, true) # Golpea enemigos
	else:
		set_collision_mask_value(2, true) # Golpea al jugador

	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if shooter_is_player:
		if body is Enemy:
			body.take_damage(damage, global_position)
			queue_free()
			return
	else:
		if body is Player and body.stats:
			body.stats.take_hit(global_position)
			queue_free()
			return

	# Si choca contra el TileMapLayer (mundo), se destruye
	if body is TileMapLayer or body is StaticBody2D:
		queue_free()
