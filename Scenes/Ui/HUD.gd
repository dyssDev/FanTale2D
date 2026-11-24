class_name HUD
extends Control
## Muestra corazones, escudos y contador de llaves (x/3) mediante señales.

@export var color_heart_full: Color = Color(0.9, 0.15, 0.2)
@export var color_heart_half: Color = Color(0.95, 0.55, 0.2)
@export var color_heart_empty: Color = Color(0.2, 0.2, 0.2, 0.6)

@export var color_shield_full: Color = Color(0.2, 0.65, 0.95)
@export var color_shield_empty: Color = Color(0.2, 0.2, 0.2, 0.35)

@onready var hearts_container: HBoxContainer = $MarginContainer/VBoxContainer/HeartsContainer
@onready var shields_container: HBoxContainer = $MarginContainer/VBoxContainer/ShieldsContainer
@onready var keys_label: Label = $MarginContainer/VBoxContainer/KeysLabel


func _ready() -> void:
	GameState.keys_changed.connect(_on_keys_changed)
	_on_keys_changed(GameState.keys_collected, GameState.REQUIRED_KEYS_PER_LEVEL)


func bind_to_player(player: Player) -> void:
	if not player or not player.stats:
		return

	player.stats.health_changed.connect(_on_health_changed)
	player.stats.shields_changed.connect(_on_shields_changed)

	_on_health_changed(player.stats.health, player.stats.max_health)
	_on_shields_changed(player.stats.shields, player.stats.max_shields)


func _on_health_changed(current_health: int, _max_health: int) -> void:
	var heart_nodes: Array[Node] = hearts_container.get_children()
	for i: int in range(heart_nodes.size()):
		var heart_rect := heart_nodes[i] as ColorRect
		if not heart_rect:
			continue

		var heart_value: int = current_health - (i * 2)
		if heart_value >= 2:
			heart_rect.color = color_heart_full
		elif heart_value == 1:
			heart_rect.color = color_heart_half
		else:
			heart_rect.color = color_heart_empty


func _on_shields_changed(current_shields: int, _max_shields: int) -> void:
	var shield_nodes: Array[Node] = shields_container.get_children()
	for i: int in range(shield_nodes.size()):
		var shield_rect := shield_nodes[i] as ColorRect
		if not shield_rect:
			continue

		shield_rect.color = color_shield_full if i < current_shields else color_shield_empty


func _on_keys_changed(current_keys: int, required_keys: int) -> void:
	if keys_label:
		keys_label.text = "Llaves: %d/%d" % [current_keys, required_keys]
