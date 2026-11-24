extends Node
## Autoload que mantiene el estado persistente de la partida: llaves por nivel,
## armas desbloqueadas, armadura equipada, cofres abiertos, checkpoint y elección de diálogo.

signal keys_changed(current_keys: int, required_keys: int)
signal weapon_unlocked(weapon: WeaponData)
signal armor_equipped(shield_bonus: int)

enum DialogChoice { NONE, SPEAK, SILENT }

const REQUIRED_KEYS_PER_LEVEL: int = 3

var keys_collected: int = 0
var unlocked_weapons: Array[WeaponData] = []
var current_weapon_index: int = 0
var equipped_armor_shields: int = 0
var opened_chests: Array[String] = []
var active_checkpoint_position: Vector2 = Vector2.ZERO
var has_active_checkpoint: bool = false
var dialog_choice: DialogChoice = DialogChoice.NONE


func reset_level_progress() -> void:
	keys_collected = 0
	has_active_checkpoint = false
	active_checkpoint_position = Vector2.ZERO
	keys_changed.emit(keys_collected, REQUIRED_KEYS_PER_LEVEL)


func reset_full_game(starting_weapon: WeaponData = null) -> void:
	keys_collected = 0
	unlocked_weapons.clear()
	if starting_weapon:
		unlocked_weapons.append(starting_weapon)
	current_weapon_index = 0
	equipped_armor_shields = 0
	opened_chests.clear()
	has_active_checkpoint = false
	active_checkpoint_position = Vector2.ZERO
	dialog_choice = DialogChoice.NONE
	keys_changed.emit(keys_collected, REQUIRED_KEYS_PER_LEVEL)


func add_key() -> void:
	keys_collected = mini(REQUIRED_KEYS_PER_LEVEL, keys_collected + 1)
	keys_changed.emit(keys_collected, REQUIRED_KEYS_PER_LEVEL)


func has_all_keys(required: int = REQUIRED_KEYS_PER_LEVEL) -> bool:
	return keys_collected >= required


func unlock_weapon(weapon: WeaponData) -> void:
	if not weapon:
		return
	for w: WeaponData in unlocked_weapons:
		if w.weapon_name == weapon.weapon_name:
			return
	unlocked_weapons.append(weapon)
	weapon_unlocked.emit(weapon)


func add_armor_shields(bonus: int) -> void:
	equipped_armor_shields = mini(5, equipped_armor_shields + bonus)
	armor_equipped.emit(equipped_armor_shields)


func register_chest_opened(chest_id: String) -> void:
	if chest_id != "" and not opened_chests.has(chest_id):
		opened_chests.append(chest_id)


func is_chest_opened(chest_id: String) -> bool:
	return chest_id != "" and opened_chests.has(chest_id)


func set_checkpoint(pos: Vector2) -> void:
	active_checkpoint_position = pos
	has_active_checkpoint = true
