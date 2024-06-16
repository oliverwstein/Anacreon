extends Node
class_name Tile

var data = null
var position = Vector2()

func _init(tile_data, pos):
	data = tile_data
	position = pos
