extends Control


func _on_new_game_button_pressed():
	get_tree().change_scene_to_file("res://Overworld/worldmap.tscn")

func _on_exit_button_pressed():
	get_tree().quit() # Replace with function body.
