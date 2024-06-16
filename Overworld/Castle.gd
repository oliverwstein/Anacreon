@tool
extends Node2D
class_name Castle

# Setting neighbors
@export var up: Castle
@export var down: Castle
@export var left: Castle
@export var right: Castle
@export var tile: Vector2 = Vector2() :
	get:
		return tile
	set(value):
		tile = value
		#position = manager.tilemap.map_to_local(tile)

var arrows = []
# Faction property with setter to update color
@export var faction: String = "" :
	get:
		return faction
	set(value):
		faction = value
		update_color()
@onready var manager: CastleManager = get_parent() as CastleManager

func update_color() -> void:
	if manager:
		var color = manager.get_color_for_faction(faction)
		var sprite: Sprite2D = $Sprite2D as Sprite2D
		if sprite:
			sprite.modulate = color

func _ready():
	update_color()
	position = manager.tilemap.map_to_local(tile)
	$Sprite2D/Label.text = name

