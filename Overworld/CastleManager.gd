# CastleManager.gd
extends Node2D
class_name CastleManager

@export var tilemap: TileMap  # The TileMap node

signal opened_castle(new_castle)
signal selected_castle_changed(new_castle)
@export var selected_castle: Castle = null:
	get:
		return selected_castle
	set(value):
		if selected_castle:
			selected_castle.drop_arrows()
		selected_castle = value
		selected_castle.generate_arrows()
		emit_signal("selected_castle_changed", selected_castle)


# Dictionary mapping factions to Color
var faction_colors: Dictionary = {
	"red": Color.RED,
	"blue": Color.BLUE,
	"ally": Color.DARK_GREEN
}

func save_castle_to_json(castle: Castle):
	print(castle.name)
	var castle_data = {
		"name": castle.name,
		"neighbors": {
			"up": get_castle_name(castle.up),
			"down": get_castle_name(castle.down),
			"left": get_castle_name(castle.left),
			"right": get_castle_name(castle.right)
		},
		"description": castle.description,
		"country": castle.country,
		"tile": {
			"x": castle.tile.x,
			"y": castle.tile.y
		},
		"faction": castle.faction
	}
	
	var json_string = JSON.stringify(castle_data, "  ")
	var file_path = "res://Data/Castles/" + castle.name + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	
	print("Exported Castle data to: ", file_path)

func get_or_create_castle(castle_name: String) -> Castle:
	if castle_name == "":
		return null  # Return null if no castle name is provided, indicating no neighbor
	var castle = find_child(castle_name, true, false) as Castle
	if not castle:
		castle = Castle.new()  # Assuming you have a Castle.gd script
		castle.name = castle_name
		add_child(castle)
	return castle

func load_castle_from_json(castle_name: String):
	var file_path = "res://Data/Castles/" + castle_name + ".json"
	var file = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()

		var json_parser = JSON.new()
		var error = json_parser.parse(json_text)  # parse now returns an error code directly in Godot 4
		
		if error == OK:
			var data = json_parser.get_data()  # Get the parsed data using get_data() method
			var castle = get_or_create_castle(castle_name)
			print(data["name"])
			# Update castle properties
			castle.description = data["description"]
			castle.country = data["country"]
			castle.tile = Vector2(data["tile"]["x"], data["tile"]["y"])
			castle.faction = data["faction"]
			# Safely update neighbors checking for empty strings
			castle.up = get_or_create_castle(data["neighbors"].get("up", ""))
			castle.down = get_or_create_castle(data["neighbors"].get("down", ""))
			castle.left = get_or_create_castle(data["neighbors"].get("left", ""))
			castle.right = get_or_create_castle(data["neighbors"].get("right", ""))
			
			print("Loaded Castle data from: ", file_path)
		else:
			print("Failed to parse JSON data from: ", file_path, " Error Code: ", error)
	else:
		print("Failed to open file: ", file_path)

func load_all_castles():
	var dir = DirAccess.open("res://Data/Castles/")  # Open the directory
	if dir:  # Check if the directory was successfully opened
		print("yeah, dir", dir)
		var files = dir.get_files()
		for file_name in files:
			if file_name.ends_with(".json"):
				var castle_name = file_name.replace(".json", "")
				load_castle_from_json(castle_name)
	else:
		print("Failed to open directory.")
	
func get_castle_name(castle: Castle) -> String:
	if castle:
		return castle.name
	return ""
	
func get_color_for_faction(faction: String) -> Color:
	return faction_colors.get(faction, Color.FLORAL_WHITE)

func _ready():
	print("Ready CastleManager")
	selected_castle = selected_castle
		
func open_castle(castle: Castle = selected_castle):
	#print(castle.name, ", ", castle.country, ", ", castle.description)
	emit_signal("opened_castle", castle)
	

func _on_zoom_changed(new_zoom):
	for child in get_children():
		if child is Castle:
			var label = child.get_node("Sprite2D/Label")
			label.scale = Vector2(1, 1) / clampf(new_zoom, .5, 2)

