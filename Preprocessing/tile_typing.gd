@tool
extends EditorScript

var simple_colors = {
	"water": Color(0, 0, 1),  # Blue
	"field": Color(0, 1, 0),  # Green
	"forest": Color(0, 0.5, 0),  # Dark Green
	"mountain": Color(0.6, 0.3, 0),  # Brown
	"cliff": Color(0.5, 0.25, 0),  # Lighter Brown
	"sand": Color(1, 1, 0)  # Yellow
}

func _run():
	var old_tileset_path = FileDialog.get_open_file("Choose the Tileset", "res://", "TileSet (*.tres)")
	var old_tileset = load(old_tileset_path)
	if old_tileset:
		var new_tileset = process_tileset(old_tileset)
		save_new_tileset(new_tileset, old_tileset_path)
	else:
		print("Failed to load the tileset.")

func process_tileset(old_tileset):
	var new_tileset = TileSet.new()

	for tile_id in old_tileset.get_tiles_ids():
		var texture = old_tileset.tile_get_texture(tile_id)
		var new_texture = simplify_texture(texture)
		var new_tile_id = new_tileset.get_last_unused_tile_id()
		new_tileset.create_tile(new_tile_id)
		new_tileset.tile_set_texture(new_tile_id, new_texture)

	return new_tileset

func simplify_texture(texture):
	var image = texture.get_data()
	image.lock()

	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var original_color = image.get_pixel(x, y)
			var nearest_color = find_nearest_color(original_color)
			image.set_pixel(x, y, nearest_color)

	image.unlock()
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image)
	return new_texture

func find_nearest_color(color):
	var min_distance = float('inf')
	var nearest_color = Color()
	for key in simple_colors:
		var distance = color.distance_to(simple_colors[key])
		if distance < min_distance:
			min_distance = distance
			nearest_color = simple_colors[key]
	return nearest_color

func save_new_tileset(tileset, old_path):
	var save_path = old_path.basename() + "_simplified.tres"
	ResourceSaver.save(save_path, tileset)
	print("New tileset saved to: ", save_path)
