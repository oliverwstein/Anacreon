extends TileMap
class_name LevelMap

var grid = [] # for the 2d grid

# Called when the node enters the scene tree for the first time.
func _ready():
	var dimensions = get_used_rect().size
	for y in dimensions.y:
		grid.append([])
		for x in dimensions.x:
			var tile_data = get_cell_tile_data(0, Vector2(x, y))
			var tile = Tile.new(tile_data, Vector2(x, y))
			grid[y].append({"tile": tile})
	
func SetTile(position, object: Tile):
	grid[int(position.y)][int(position.x)]["tile"] = object
	
func GetTile(position):
	return grid[int(position.y)][int(position.x)]["tile"]
