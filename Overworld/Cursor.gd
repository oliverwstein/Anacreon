extends Node2D

var lerp_speed = 5  # This can be adjusted to control the speed of the lerp
var lerp_progress = 0.0
var completed_movement = true
var target_position = Vector2()

signal cursor_moved(position)

func start_movement(targetCastle:Castle):	
	target_position = targetCastle.global_position
	completed_movement = false
	lerp_progress = 0.0
	
	#for arrow in SelectedCastle.arrows:
		#SelectedCastle.remove_child(arrow)
	#SelectedCastle.arrows.clear()
	#SelectedCastle = targetCastle
	
func _process(delta):
	if not completed_movement:
		lerp_progress += lerp_speed * delta
		position = position.lerp(target_position, lerp_progress)
		if lerp_progress >= 1.0 or position.distance_to(target_position) < 1.0:
			position = target_position
			completed_movement = true
			lerp_progress = 0.0
			emit_signal("cursor_moved", position)  # Emit the cursor moved signal


func _on_selected_castle_changed(new_castle):
	start_movement(new_castle)
