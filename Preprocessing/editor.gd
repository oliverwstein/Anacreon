@tool
extends EditorScript

func _run():
	print("Run!")
	var scene_path = "res://Overworld/tile_map.tscn"  # Path to your scene file
	var new_scene_path = "res://Overworld/tile_map_simplified.tscn"  # Path to your scene file
	var scene = load(scene_path)  # Load the scene resource
	if scene:
		var node = scene.instantiate()  # Create an instance of the scene
		var tile_map = scene.get_local_scene().duplicate(true) # Find the TileMap node in the scene
		if tile_map and tile_map.tile_set:
			tile_map.tile_set = process_tileset(tile_map.tile_set.duplicate(true))  # Duplicate and process the TileSet
			var tile_set = tile_map.tile_set as TileSet
			save_scene(tile_map, new_scene_path)  # Save the modified scene
			open_scene_in_editor(new_scene_path)  # Optionally open the modified scene in the editor
		else:
			print("TileMap or TileSet not found in the scene.")
	else:
		print("Failed to load the scene.")

func save_scene(node, path):
	var packed_scene = PackedScene.new()
	packed_scene.pack(node)
	if packed_scene.pack(node) == 0:
		var error = ResourceSaver.save(packed_scene, path)
		if error == OK:
			print("Scene saved successfully to:", path)
		else:
			print("Failed to save the scene:", error)
	else:
		print("Failed to pack the scene.")

func open_scene_in_editor(path):
	EditorInterface.open_scene_from_path(path)
	print("Scene opened in editor:", path)

var reference_tiles = {
		"water": Vector2i(0, 0),
		"field": Vector2i(9,0),
		"forest": Vector2i(10, 1),
		"mountain": Vector2i(12, 11),
		"cliff": Vector2i(13, 7),
		"sand": Vector2i(2, 15),
		"road": Vector2i(16, 4),
	}
var reference_dists = {}

func process_tileset(tileset: TileSet):
	print("process_tileset, ", tileset)
	var atlas = tileset.get_source_count()  # Get all tile IDs
	print("atlas, ", atlas)
	var tile_source = tileset.get_source(0) as TileSetAtlasSource
	print(tile_source)
	print("tile_count, ", tile_source.get_tiles_count())
	var image = tile_source.get_texture().get_image() as Image
	for category in reference_tiles.keys():
		var tile_id_vec = reference_tiles[category]
		var texture_region = tile_source.get_tile_texture_region(tile_id_vec)
		reference_dists[category] = get_color_distribution(image.get_region(tile_source.get_tile_texture_region(tile_id_vec)))

	for id in range(0, tile_source.get_tiles_count()):
		var tile_id_vec = tile_source.get_tile_id(id)
		var texture_region = tile_source.get_tile_texture_region(tile_id_vec)
		var category = _process_tile(image.get_region(texture_region), reference_dists)
		#print(tile_id_vec, category)
		tile_source.get_tile_data(tile_id_vec, 0).set_custom_data("tileType", category[0])
	
	print("Tileset processed!")
	print(tile_source.get_tile_data(Vector2i(0,0), 0).get_custom_data("tileType"))
	return tileset

func _process_tile(tileImage: Image, reference_dists: Dictionary):
	var colorDist = get_color_distribution(tileImage)
	var best_match_value = INF
	var best_match = ""
	for ref in reference_dists.keys():
		var emd = calculate_emd(colorDist, reference_dists[ref])
		if emd < best_match_value:
			best_match = ref
			best_match_value = emd
	return [best_match, best_match_value]
	

func get_color_distribution(image: Image):
	# Dictionary to store color counts
	var color_distribution = {}
	var width = image.get_width()
	var height = image.get_height()
	# Iterate over each pixel in the image
	for x in range(width):
		for y in range(height):
			var color = image.get_pixel(x, y).to_rgba32()  # Convert color to a unique integer key
			# Increment the count for this color in the distribution
			if color in color_distribution:
				color_distribution[color] += 1
			else:
				color_distribution[color] = 1

	return color_distribution

static func sum(array):
	var sum = 0.0
	for element in array:
		sum += element
	return sum
	
static func get_unique_elements(arr):
	var unique_dict = {}  # Use a dictionary to track unique elements
	var unique_list = []  # List to store the unique elements

	# Iterate over each element in the array
	for element in arr:
		if not unique_dict.has(element):
			unique_dict[element] = true
			unique_list.append(element)

	return unique_list
# Calculates the Earth Mover's Distance (EMD) between two distributions
func calculate_emd(distribution1, distribution2):
	var keys1 = distribution1.keys()
	var keys2 = distribution2.keys()
	
	# All unique keys/colors from both distributions
	var all_keys = get_unique_elements(keys1 + keys2)
	# Normalize distributions
	var total1 = sum(distribution1.values())
	var total2 = sum(distribution2.values())
	var norm1 = normalize_distribution(distribution1, total1)
	var norm2 = normalize_distribution(distribution2, total2)

	# Calculate the cumulative distribution functions (CDFs)
	var cdf1 = calculate_cdf(norm1, all_keys)
	var cdf2 = calculate_cdf(norm2, all_keys)

	# Calculate the EMD
	var emd = 0.0
	for i in range(all_keys.size()):
		emd += abs(cdf1[i] - cdf2[i])
	return emd

# Normalize a distribution
func normalize_distribution(distribution, total):
	var normalized = {}
	for key in distribution.keys():
		normalized[key] = distribution[key] / total
	return normalized

# Calculate cumulative distribution function (CDF) for the normalized distribution
func calculate_cdf(norm_distribution, all_keys):
	var cdf = []
	var cumulative = 0.0
	for key in all_keys:
		cumulative += norm_distribution.get(key, 0)  # Use 0 if the key is not present
		cdf.append(cumulative)
	return cdf
