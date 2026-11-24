extends Node2D

@onready var player: Player = $Player
@onready var hud: HUD = $CanvasLayer/HUD


func _ready() -> void:
	hud.bind_to_player(player)
