extends Camera2D


func _on_zoom_changed(new_zoom):
	zoom = Vector2(new_zoom, new_zoom)
