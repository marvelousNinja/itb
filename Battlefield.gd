extends Node2D

signal node_added

func _ready():
	var ground_tile = preload("res://GroundTile.tscn")
	var tile_size = Vector2(56, 40)
	var map_size = Vector2(4, 4)
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			var instance = ground_tile.instance()
			instance.position = map_to_world(Vector2(x,y), tile_size)
			add_child(instance)
			emit_signal("node_added", instance)
	
	var unit_scene = preload("res://Unit.tscn")
	var instance = unit_scene.instance()
	instance.position = map_to_world(Vector2(0, 0), tile_size)
	add_child(instance)
	emit_signal("node_added", instance)

func map_to_world(position, tile_size):
	return Vector2((position.y - position.x) * tile_size.x / 2, (position.x + position.y) * tile_size.y / 2)
