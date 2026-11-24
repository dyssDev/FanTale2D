class_name WeaponData
extends Resource
## Recurso de datos para configurar armas cuerpo a cuerpo y a distancia.

@export var weapon_name: String = "Daga"
@export var damage: int = 1
@export var attack_cooldown: float = 0.25
@export var active_duration: float = 0.12
@export var hitbox_size: Vector2 = Vector2(14.0, 10.0)
@export var hitbox_offset: Vector2 = Vector2(12.0, -8.0)
@export var move_speed_multiplier: float = 1.0
@export var self_knockback: float = 0.0
@export var visual_color: Color = Color(0.85, 0.85, 0.9)

@export_group("Distancia (Arco)")
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 210.0
