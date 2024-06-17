extends Control

# Assuming SceneManager is an autoload and has been properly set up
var worldmap_scene: PackedScene

func _ready():
	# Preload the world map scene once and register it with the SceneManager
	worldmap_scene = preload("res://Overworld/worldmap.tscn")
	SceneManager.register_preloaded_scene("world_map", worldmap_scene)

func _on_new_game_button_pressed():
	# Switch to the preloaded and registered scene, requesting a new instance if necessary
	SceneManager.switch_to_scene("world_map", true)  # true if a new instance is needed each time

func _on_exit_button_pressed():
	get_tree().quit()  # This remains unchanged
