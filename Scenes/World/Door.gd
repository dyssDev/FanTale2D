class_name Door
extends Area2D
## Puerta que exige las llaves del nivel para abrirse y avanzar de escena.

signal door_opened(next_scene_path: String)

@export var required_keys: int = 3
@export_file("*.tscn") var next_scene_path: String = ""

var is_open: bool = false
var _player_in_range: bool = false

@onready var visual: ColorRect = $ColorRect
@onready var message_label: Label = $MessageLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and not is_open and event.is_action_pressed("interact"):
		_try_open()


func _try_open() -> void:
	if GameState.has_all_keys(required_keys):
		is_open = true
		visual.color = Color(0.2, 0.75, 0.35, 0.6)
		message_label.text = "¡Abierta!"
		door_opened.emit(next_scene_path)
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
	else:
		message_label.text = "Faltan llaves (%d/%d)" % [GameState.keys_collected, required_keys]
		message_label.visible = true


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_open:
		_player_in_range = true
		message_label.text = "Abrir [F]"
		message_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		message_label.visible = false
