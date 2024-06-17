# SceneManager.gd
extends Node

var scenes = {}  # Stores PackedScene objects or instances

func register_preloaded_scene(key: String, preloaded_scene: PackedScene):
	if not scenes.has(key):
		scenes[key] = preloaded_scene

func switch_to_scene(key: String, instance_new: bool = false):
	if scenes.has(key):
		var scene = scenes[key]
		if scene is PackedScene:
			scene = scene.instantiate()  # Create an instance if it's a PackedScene
		
		var current_scene = get_tree().current_scene  # Cache the current scene
		
		# Safely remove and free the current scene
		if current_scene and current_scene.is_inside_tree():
			get_tree().root.remove_child(current_scene)
			current_scene.queue_free()  # Now safe to free the cached reference
		
		# Add the new scene and set it as the current scene
		get_tree().root.add_child(scene)
		get_tree().set_current_scene(scene)
		
		# Optionally update the dictionary if new instance should be reused
		if instance_new:
			scenes[key] = scene
	else:
		print("Scene not registered: " + key)

func get_scene_instance(key: String, new_instance: bool = true) -> Node:
	if scenes.has(key) and scenes[key] is PackedScene:
		if new_instance:
			return scenes[key].instantiate()
		return scenes[key]
	else:
		print("Scene key not found: " + key)
		return null
