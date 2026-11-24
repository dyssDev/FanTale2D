class_name Chest
extends Area2D
## Cofre interactuable configurable mediante ChestContent. Guarda su estado en GameState.

@export var chest_id: String = ""
@export var content: ChestContent

var is_opened: bool = false
var _player_in_range: bool = false

@onready var visual: ColorRect = $ColorRect
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if GameState.is_chest_opened(chest_id):
		_set_opened_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and not is_opened and event.is_action_pressed("interact"):
		_open()


func _open() -> void:
	is_opened = true
	GameState.register_chest_opened(chest_id)
	_set_opened_visuals()

	if not content:
		GameState.add_key()
		return

	match content.type:
		ChestContent.ContentType.KEY:
			GameState.add_key()
		ChestContent.ContentType.WEAPON:
			GameState.unlock_weapon(content.weapon_data)
		ChestContent.ContentType.ARMOR:
			GameState.add_armor_shields(content.armor_shield_bonus)


func _set_opened_visuals() -> void:
	is_opened = true
	visual.color = Color(0.35, 0.25, 0.18, 0.8)
	prompt_label.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_opened:
		_player_in_range = true
		prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		prompt_label.visible = false
