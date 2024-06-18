extends Control

@export var castle: Castle;

func _ready():
	hide()
	
func _on_selected_castle_change(new_castle: Castle):
	print("_on_selected_castle_change")
	castle = new_castle
	$TabContainer/Atlas/Label.text = castle.name
	$TabContainer/Atlas/ScrollContainer/CastleDescription.text = castle.description

func _on_open_castle(new_castle: Castle):
	_on_selected_castle_change(new_castle)
	visible = !visible


