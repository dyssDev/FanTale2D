class_name Player
extends CharacterBody2D
## Controla movimiento, salto responsivo, ataque con arma equipada,
## recepción de daño y máquina de estados del jugador.

enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT, DEAD }

@export_group("Movimiento")
@export var move_speed: float = 110.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0

@export_group("Salto y Gravedad")
@export var jump_velocity: float = -245.0
@export var gravity: float = 720.0
@export var fall_gravity_multiplier: float = 1.35
@export var jump_cut_multiplier: float = 0.5
@export var max_fall_speed: float = 320.0
@export var coyote_time_duration: float = 0.1
@export var jump_buffer_duration: float = 0.1

@export_group("Combate y Daño")
@export var current_weapon: WeaponData
@export var knockback_force: Vector2 = Vector2(130.0, -140.0)
@export var hurt_stun_duration: float = 0.2

var current_state: State = State.IDLE
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var hurt_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var attack_active_timer: float = 0.0
var facing_direction: int = 1
var _hit_targets_this_swing: Array[Node] = []

@onready var visuals: Node2D = $Visuals
@onready var stats: PlayerStats = $PlayerStats
@onready var weapon_hitbox: Area2D = $Visuals/WeaponHitbox
@onready var weapon_shape: CollisionShape2D = $Visuals/WeaponHitbox/CollisionShape2D
@onready var weapon_visual: ColorRect = $Visuals/WeaponHitbox/ColorRect


func _ready() -> void:
	stats.damaged.connect(_on_damaged)
	stats.died.connect(_on_died)
	weapon_hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)
	_apply_weapon_stats()
	GameState.unlock_weapon(current_weapon)
	GameState.armor_equipped.connect(func(bonus: int) -> void: stats.shields = bonus; stats.shields_changed.emit(stats.shields, stats.max_shields))
	GameState.weapon_unlocked.connect(func(w: WeaponData) -> void: equip_weapon(w))

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		move_and_slide()
		return

	_update_timers(delta)
	_apply_gravity(delta)
	_update_invulnerability_blink()

	if current_state == State.HURT:
		hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, friction * 0.5 * delta)
		if hurt_timer <= 0.0:
			current_state = State.IDLE
	else:
		_handle_weapon_switch()
		_handle_attack_input()
		_handle_jump()
		_handle_horizontal_movement(delta)

	move_and_slide()
	_update_state()


func _apply_weapon_stats() -> void:
	if not current_weapon:
		return
	var rect := weapon_shape.shape as RectangleShape2D
	if rect:
		rect.size = current_weapon.hitbox_size
	weapon_shape.position = current_weapon.hitbox_offset
	if weapon_visual:
		weapon_visual.size = current_weapon.hitbox_size
		weapon_visual.position = current_weapon.hitbox_offset - (current_weapon.hitbox_size * 0.5)


func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time_duration
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_duration
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	attack_cooldown_timer = maxf(0.0, attack_cooldown_timer - delta)

	if attack_active_timer > 0.0:
		attack_active_timer -= delta
		if attack_active_timer <= 0.0:
			_end_attack()


func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0 and current_weapon:
		_start_attack()


func _start_attack() -> void:
	current_state = State.ATTACK
	attack_cooldown_timer = current_weapon.attack_cooldown
	attack_active_timer = current_weapon.active_duration
	_hit_targets_this_swing.clear()

	if weapon_visual:
		weapon_visual.visible = true

	if current_weapon.is_ranged and current_weapon.projectile_scene:
		var arrow := current_weapon.projectile_scene.instantiate() as Projectile
		arrow.shooter_is_player = true
		arrow.damage = current_weapon.damage
		arrow.speed = current_weapon.projectile_speed
		arrow.direction = Vector2(facing_direction, 0.0)
		arrow.global_position = global_position + Vector2(facing_direction * 10.0, -8.0)
		get_tree().current_scene.add_child(arrow)
	else:
		weapon_shape.set_deferred("disabled", false)

	if current_weapon.self_knockback > 0.0:
		velocity.x = -facing_direction * current_weapon.self_knockback


func _end_attack() -> void:
	weapon_shape.set_deferred("disabled", true)
	if weapon_visual:
		weapon_visual.visible = false
	if current_state == State.ATTACK:
		current_state = State.IDLE


func _on_weapon_hitbox_body_entered(body: Node2D) -> void:
	if body in _hit_targets_this_swing:
		return
	if body.has_method("take_damage") and current_weapon:
		_hit_targets_this_swing.append(body)
		body.take_damage(current_weapon.damage, global_position)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var current_gravity: float = gravity
	if velocity.y > 0.0:
		current_gravity *= fall_gravity_multiplier

	velocity.y = minf(velocity.y + current_gravity * delta, max_fall_speed)


func _handle_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _handle_horizontal_movement(delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	var speed_mult: float = 1.0
	if current_state == State.ATTACK and current_weapon:
		speed_mult = current_weapon.move_speed_multiplier

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * move_speed * speed_mult, acceleration * delta)
		if current_state != State.ATTACK:
			_set_facing_direction(int(signf(input_dir)))
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _set_facing_direction(dir: int) -> void:
	if dir != facing_direction and dir != 0:
		facing_direction = dir
		visuals.scale.x = float(facing_direction)


func _update_invulnerability_blink() -> void:
	if stats.is_invulnerable:
		visuals.visible = int(Time.get_ticks_msec() / 80) % 2 == 0
	else:
		visuals.visible = true


func _on_damaged(knockback_dir: Vector2) -> void:
	if current_state == State.DEAD:
		return

	_end_attack()
	current_state = State.HURT
	hurt_timer = hurt_stun_duration

	var dir_x: float = signf(knockback_dir.x) if knockback_dir.x != 0.0 else float(-facing_direction)
	velocity = Vector2(dir_x * knockback_force.x, knockback_force.y)


func _on_died() -> void:
	_end_attack()
	current_state = State.DEAD
	visuals.visible = true
	visuals.modulate = Color(0.4, 0.4, 0.4, 0.8)


func _update_state() -> void:
	if current_state in [State.ATTACK, State.HURT, State.DEAD]:
		return

	if not is_on_floor():
		current_state = State.JUMP if velocity.y < 0.0 else State.FALL
	elif absf(velocity.x) > 5.0:
		current_state = State.RUN
	else:
		current_state = State.IDLE
		
func _handle_weapon_switch() -> void:
	if Input.is_action_just_pressed("switch_weapon") and GameState.unlocked_weapons.size() > 1:
		GameState.current_weapon_index = (GameState.current_weapon_index + 1) % GameState.unlocked_weapons.size()
		equip_weapon(GameState.unlocked_weapons[GameState.current_weapon_index])

func equip_weapon(new_weapon: WeaponData) -> void:
	if not new_weapon:
		return
	current_weapon = new_weapon
	_apply_weapon_stats()
	
