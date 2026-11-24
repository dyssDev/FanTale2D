class_name Skeleton
extends Enemy
## Patrulla lentamente y se detiene a lanzar huesos cuando detecta al jugador.

@export var bone_scene: PackedScene
@export var throw_cooldown: float = 1.6
@export var bone_speed: float = 135.0

var _throw_timer: float = 0.0


func _behavior_process(delta: float) -> void:
	if _throw_timer > 0.0:
		_throw_timer -= delta

	var patrol_speed: float = data.move_speed if data else 35.0

	if target_player and target_player.current_state != Player.State.DEAD:
		# Se detiene para apuntar y lanzar huesos al jugador
		velocity.x = 0.0
		var dir_to_player: float = signf(target_player.global_position.x - global_position.x)
		if dir_to_player != 0.0:
			set_facing_direction(int(dir_to_player))

		if _throw_timer <= 0.0:
			_throw_bone()
	else:
		# Patrulla normal dando la vuelta en paredes o precipicios
		if is_on_floor() and (is_on_wall() or not edge_ray.is_colliding()):
			set_facing_direction(-facing_direction)
		velocity.x = facing_direction * patrol_speed


func _throw_bone() -> void:
	_throw_timer = throw_cooldown
	if not bone_scene:
		return

	var bone := bone_scene.instantiate() as Projectile
	bone.shooter_is_player = false
	bone.damage = 1
	bone.speed = bone_speed
	bone.direction = Vector2(facing_direction, 0.0)
	bone.global_position = global_position + Vector2(facing_direction * 10.0, -8.0)
	get_tree().current_scene.add_child(bone)
