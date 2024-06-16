# CastleManager.gd
extends Node2D
class_name CastleManager

@export var tilemap: TileMap  # The TileMap node

# Dictionary mapping factions to Color
var faction_colors: Dictionary = {
	"red": Color.RED,
	"blue": Color.BLUE,
	"ally": Color.DARK_GREEN
}

func get_color_for_faction(faction: String) -> Color:
	return faction_colors.get(faction, Color.FLORAL_WHITE)

func _ready():
	print("Ready CastleManager")



func _on_zoom_changed(new_zoom):
	for child in get_children():
		if child is Castle:
			var label = child.get_node("Sprite2D/Label")
			label.scale = Vector2(1, 1) / clampf(new_zoom, .5, 2)

