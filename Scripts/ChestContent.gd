class_name ChestContent
extends Resource
## Define qué recompensa entrega un cofre al abrirse (llave, arma o armadura).

enum ContentType { KEY, WEAPON, ARMOR }

@export var type: ContentType = ContentType.KEY
@export var weapon_data: WeaponData
@export var armor_shield_bonus: int = 0
@export var pickup_message: String = "¡Has encontrado una llave!"
