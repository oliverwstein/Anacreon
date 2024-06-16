extends Control


func _on_cursor_moved(new_cell):
	var tileType = get_parent().get_cell_tile_data(0, new_cell).get_custom_data("type")
	$SelectionLabel.text = "({x}, {y})\n{type}".format({"x": new_cell.x, "y": new_cell.y, "type": tileType})
	print("triggered _on_cursor_moved")
