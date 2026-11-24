class_name Checkpoint
extends Area2D
## Guarda la posición de reaparición del jugador en GameState al pasar por encima.

var is_activated: bool = false
@onready var visual: ColorRect = $ColorRect


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_activated:
		is_activated = true
		visual.color = Color(1.0, 0.8, 0.2) # Se enciende en dorado como una antorcha
		GameState.set_checkpoint(global_position)
