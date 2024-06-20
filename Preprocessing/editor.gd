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
	#tileset.add_physics_layer()
	var tile_source = tileset.get_source(0) as TileSetAtlasSource
	print(tile_source)
	print("tile_count, ", tile_source.get_tiles_count())
	var image = tile_source.get_texture().get_image() as Image
	for category in reference_tiles.keys():
		var tile_id_vec = reference_tiles[category]
		var texture_region = tile_source.get_tile_texture_region(tile_id_vec)
		reference_dists[category] = get_color_distribution(image.get_region(tile_source.get_tile_texture_region(tile_id_vec)))

	for id in range(0, 8):#tile_source.get_tiles_count()):
		var tile_id_vec = tile_source.get_tile_id(id)
		var texture_region = tile_source.get_tile_texture_region(tile_id_vec)
		var tile_image = image.get_region(texture_region)
		#var category = _process_tile(tile_image, reference_dists)
		print(tile_id_vec)
		#tile_source.get_tile_data(tile_id_vec, 0).set_custom_data("tileType", category[0])
		#var frequency_matrix = find_pixel_frequencies(tile_image, reference_dists[category[0]])
		#var inclusion_matrix = initialize_inclusion_matrix(frequency_matrix)
		#prune_negative_values(frequency_matrix, inclusion_matrix)
		#var hull = find_largest_convex_hull_from_components(inclusion_matrix)
		#if hull != null:
			#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygons_count(0, 1)
			#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygon_points(0, 0, adjust_contour_points(hull))
			
		var pixel_category_matrix = _process_tile_by_pixel(tile_image, reference_dists, true)
		var regions = region_grower(pixel_category_matrix)
		var polyCount = 0
		var polygonsTotal = 0
		for key in regions.keys():
			for polygon in regions[key]:
				polygonsTotal += 1
		tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygons_count(0, polygonsTotal)
		for key in regions.keys():
			for region in regions[key]:
				var polygon = adjust_contour_points(get_perimeter(region))
				print(polygon)
				tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygon_points(0, polyCount, polygon)
				polyCount += 1
		
		#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygons_count(0, polygonsTotal)
		#for key in regions.keys():
			#if len(regions[key]) > 0:
				##print(key,", ", len(regions[key]))
				#var pixels = 0
				#for polygon in regions[key]:
					##tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygon_points(0, polyCount, adjust_contour_points(polygon))
					##print(polygon)
					#polyCount += 1
					#pixels += len(polygon)
				#print("pixels, ", pixels)
		

		# Now, find connected regions and extract polygons
		#var regions_data = group_pixels_into_regions(pixel_category_matrix)
		#var polygons = extract_largest_regions(regions_data['region_sizes'], regions_data['region_categories'], regions_data['region_ids'], 3)
#
		## Each entry in polygons now contains the category, size, and points that form the boundary of the region
		#var polygon_layer_count = 0
		#for polygon in polygons:
			#print("Polygon Category: ", polygon['category'])
			#print("Polygon Points: ", polygon['points'])
			#if len(polygon['points']) > 3:
				#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygons_count(polygon_layer_count, 1)
				#tile_source.get_tile_data(tile_id_vec, 0).set_collision_polygon_points(polygon_layer_count, 0, adjust_contour_points(polygon['points']))
				#polygon_layer_count += 1
		
	return tileset

func _process_tile(tileImage: Image, reference_dists: Dictionary):
	var colorDist = get_color_distribution(tileImage)
	var best_match_value = INF#6
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
	var total = sum(color_distribution.values())
	var normed_distribution = normalize_distribution(color_distribution, total)
	return normed_distribution

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

func find_pixel_frequencies(image: Image, reference_distribution: Dictionary) -> Array:
	var width = image.get_width()
	var height = image.get_height()
	var frequency_matrix = Array()

	# Initialize the frequency matrix with default value -0.1
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(-0.1)  # Default value for unmatched pixels
		frequency_matrix.append(row)

	# Populate the frequency matrix with values from the reference distribution
	for x in range(width):
		for y in range(height):
			var pixel_color = image.get_pixel(x, y).to_rgba32()
			if reference_distribution.has(pixel_color):
				frequency_matrix[y][x] = reference_distribution[pixel_color]
			else:
				frequency_matrix[y][x] = -0.1  # This line is optional since it's already initialized

	return frequency_matrix
	
func initialize_inclusion_matrix(frequency_matrix):
	var inclusion_matrix = []
	for i in range(frequency_matrix.size()):
		var row = []
		for j in range(frequency_matrix[i].size()):
			row.append(1)  # Start with all points included
		inclusion_matrix.append(row)
	return inclusion_matrix

func prune_negative_values(frequency_matrix, inclusion_matrix):
	var changes = true
	while changes:
		changes = false
		for i in range(frequency_matrix.size()):
			for j in range(frequency_matrix[i].size()):
				if inclusion_matrix[i][j] == 1 and frequency_matrix[i][j] < 0:
					# Check if setting this point to 0 increases the total value
					if can_remove_point(frequency_matrix, inclusion_matrix, i, j):
						inclusion_matrix[i][j] = 0
						changes = true
func can_remove_point(frequency_matrix, inclusion_matrix, i, j):
	# Additional checks can be added here to decide if removing a point is beneficial
	return true  # Simplistic approach for now
func calculate_offsets(contour):
	var min_x = float('inf')
	var max_x = float('-inf')
	var min_y = float('inf')
	var max_y = float('-inf')
	
	for point in contour:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	return Vector2(width / 2 + min_x, height / 2 + min_y)  # Return the offsets for x and y

func adjust_contour_points(contour):
	var offsets = calculate_offsets(contour)
	var offset_x = offsets[0]
	var offset_y = offsets[1]
	
	var adjusted_contour = PackedVector2Array()
	for point in contour:
		var adjusted_point = Vector2(point.x - offset_x, point.y - offset_y)
		adjusted_contour.append(adjusted_point)
	
	return adjusted_contour

func get_pixel_panels(image: Image, span: int) -> Dictionary:
	var panels = Dictionary()

	# Iterate through each pixel in the image
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			# Calculate the sub-image bounds
			var min_x = max(x - span, 0)
			var max_x = min(x + span, image.get_width() - 1)
			var min_y = max(y - span, 0)
			var max_y = min(y + span, image.get_height() - 1)
			
			# Create a new sub-image for these bounds
			var sub_image = image.get_region(Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
			panels[Vector2(x, y)] = sub_image

	return panels
	
func _process_tile_by_pixel(tileImage: Image, reference_dists: Dictionary, expanded: bool = false) -> Array:
	var pixel_category_matrix = Array()
	var panels = get_pixel_panels(tileImage, 2)
	for y in range(tileImage.get_height()):
		var row = []
		for x in range(tileImage.get_width()):
			var colorDist = get_color_distribution(panels[Vector2(x, y)])
			var best_match_value = INF#6
			var best_match = ""
			var cell_dict = {}
			for ref in reference_dists.keys():
				var emd = calculate_emd(colorDist, reference_dists[ref])
				cell_dict[ref] = emd
				if emd < best_match_value:
					best_match = ref
					best_match_value = emd
			if expanded:
				row.append(cell_dict)
			else:
				row.append(best_match)
		pixel_category_matrix.append(row)
	return pixel_category_matrix

func region_grower(pixel_matrix:Array) -> Dictionary: 
	var regions = {}
	var visited = []
	visited.resize(pixel_matrix.size())
	for row in pixel_matrix.size():
		visited[row] = []
		visited[row].resize(pixel_matrix.size())
		visited[row].fill(false)
	var directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
	]
	# Main loop
	while true:
		var seed = _find_seed(pixel_matrix, visited)
		if seed == null:
			break
		var new_region = _grow_region(seed, pixel_matrix, visited, directions)
		if new_region[0].size() >= 8:
			if regions.get(new_region[1], false):
				regions[new_region[1]].append(new_region[0])
			else:
				regions[new_region[1]] = [new_region[0]]
	return regions

func _find_seed(pixel_matrix, visited):
	var min_distance = INF
	var seed_point = null
	
	for x in pixel_matrix.size():
		for y in pixel_matrix[x].size():
			if visited[y][x] == false:
				var distances = pixel_matrix[y][x] as Dictionary
				for key in distances.keys():
					if distances[key] < min_distance:
						min_distance = distances[key]
						seed_point = Vector2(x, y)
	return seed_point

func _grow_region(seed:Vector2, pixel_matrix:Array, visited:Array, directions:Array) -> Array:
	var stack = []
	var region = []
	stack.push_back(seed)
	var category = _best_category(pixel_matrix[seed.y][seed.x])
	
	while !stack.is_empty():
		var point = stack.pop_back()
		if visited[point.y][point.x] == false:
			visited[point.y][point.x] = true
			region.append(point)
			for dir in directions:
				var neighbor = point + dir
				if is_valid_index(neighbor, pixel_matrix):
					if visited[neighbor.y][neighbor.x] == false:
						if _is_similar(point, neighbor, pixel_matrix):
							stack.push_back(neighbor)
	return [region, category]

func _is_similar(point1:Vector2, point2:Vector2, pixel_matrix) -> bool:
	var key1 = _best_category(pixel_matrix[point1.y][point1.x])
	var key2 = _best_category(pixel_matrix[point2.y][point2.x])
	return key1 == key2
	
func _best_category(cat_distances:Dictionary) -> String:
	var min_distance = INF
	var best_key = null
	for key in cat_distances.keys():
		if cat_distances[key] < min_distance:
			min_distance = cat_distances[key]
			best_key = key
	return best_key
				
		
func is_valid_index(index: Vector2, grid: Array) -> bool:
	# Check if y is within the range of the grid's outer array
	if index.y >= 0 and index.y < grid.size():
		# Check if x is within the range of the inner array at the y-th position
		if index.x >= 0 and index.x < grid[int(index.y)].size():
			return true
	return false



func is_collinear(p1: Vector2, p2: Vector2, p3: Vector2) -> bool:
	return (p3.y - p2.y) * (p2.x - p1.x) == (p2.y - p1.y) * (p3.x - p2.x)

func _create_edge_map(tiles) -> Dictionary:
	var edges = {}
	var directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
	]
	for tile in tiles:
		for dir in directions:
			var neighbor = tile + dir
			if neighbor not in tiles:
				edges.merge(_create_edge(tile, dir))
	return edges
	
func _create_edge(tile: Vector2, direction: Vector2):
	if direction == Vector2(0, -1):  # Up
		return {Vector2(tile.x, tile.y): Vector2(tile.x + 1, tile.y)}
	elif direction == Vector2(0, 1):  # Down
		return {Vector2(tile.x + 1, tile.y + 1): Vector2(tile.x, tile.y + 1)}
	elif direction == Vector2(-1, 0):  # Left
		return {Vector2(tile.x, tile.y + 1): Vector2(tile.x, tile.y)}
	elif direction == Vector2(1, 0):  # Right
		return {Vector2(tile.x + 1, tile.y): Vector2(tile.x + 1, tile.y + 1)}
		
func get_perimeter(tiles):
	var edges = _create_edge_map(tiles)
	var starting_point = edges.keys()[0] # It shouldn't matter which one this is.
	var perimeter = [starting_point]
	var current_point = edges[starting_point]
	while current_point != starting_point:
		if !is_collinear(perimeter.back(), current_point, edges[current_point]):
			perimeter.append(current_point)
			current_point = edges[current_point]
		else:
			current_point = edges[current_point]
	if is_collinear(perimeter.back(), starting_point, edges[starting_point]):
		perimeter.pop_front()
		perimeter.append(perimeter[0])
	else:
		perimeter.append(current_point)
	
	return PackedVector2Array(perimeter)
		
	
	
