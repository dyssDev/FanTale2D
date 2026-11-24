class_name Goblin
extends Enemy

func _behavior_process(_delta: float) -> void:
	var patrol_speed: float = data.move_speed if data else 45.0
	var chase_speed: float = data.chase_speed if data else 70.0

	if target_player and target_player.current_state != Player.State.DEAD:
		var dir_to_player: float = signf(target_player.global_position.x - global_position.x)
		if dir_to_player != 0.0:
			set_facing_direction(int(dir_to_player))

		if is_on_floor() and not edge_ray.is_colliding():
			velocity.x = 0.0
		else:
			velocity.x = facing_direction * chase_speed
	else:
		if is_on_floor() and (is_on_wall() or not edge_ray.is_colliding()):
			set_facing_direction(-facing_direction)
		velocity.x = facing_direction * patrol_speed
