extends Node2D

signal node_added

func overlay_tiles(coords):
	var overlay_scene = preload("res://OverlayTile.tscn")
	for coord in coords:
		var instance = overlay_scene.instance()
		instance.position = coord
		add_child(instance)
		instance.add_to_group("overlay_tiles")
		emit_signal("node_added", instance)
		

func reset_overlay_tiles():
	get_tree().call_group('overlay_tiles', 'free')