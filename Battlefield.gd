extends Node2D

func handle_events(events):
	for event in events: handle_domain_event(event)

func handle_domain_event(event):
	print(event)
	match event:
		{"type": "mech_deployed", ..}:
			var unit_scene = preload("res://Unit.tscn")
			var instance = unit_scene.instance()
			var tile_size = Vector2(56, 40)
			instance.position = map_to_world(event.tile_position, tile_size)
			add_child(instance)
			instance.add_to_group("player_unit")
		{"type": "vek_emerged", ..}:
			var unit_scene = preload("res://VekUnit.tscn")
			var instance = unit_scene.instance()
			var tile_size = Vector2(56, 40)
			instance.position = map_to_world(event.tile_position, tile_size)
			add_child(instance)
			instance.add_to_group("vek_unit")
		{"type": "combat_started", ..}:
			var ground_tile = preload("res://GroundTile.tscn")
			var tile_size = Vector2(56, 40)
			var map_size = Vector2(4, 4)
			for x in range(map_size.x):
				for y in range(map_size.y):
					var instance = ground_tile.instance()
					instance.position = map_to_world(Vector2(x, y), tile_size)
					add_child(instance)
					listen_node(instance)
			setup_hud()
		{"type": "overlay_shown", ..}:
			var overlay_scene = preload("res://OverlayTile.tscn")
			var tile_size = Vector2(56, 40)
			for coord in event["coords"]:
				var instance = overlay_scene.instance()
				instance.position = map_to_world(coord, tile_size)
				add_child(instance)
				instance.add_to_group("overlay_tiles")
		{"type": "overlay_reset", ..}:
			get_tree().call_group("overlay_tiles", "free")
		{"type": "path_shown", ..}:
			get_tree().call_group("path_tiles", "free")
			var path_tile = preload("res://PathTile.tscn")
			var tile_size = Vector2(56, 40)
			for coord in event["coords"]:
				var instance = path_tile.instance()
				instance.position = map_to_world(coord, tile_size)
				add_child(instance)
				instance.add_to_group("path_tiles")
		{"type": "path_reset", ..}:
			get_tree().call_group("path_tiles", "free")
		{"type": "mech_moved", "path": var path, ..}:
			var from = path[0]
			var to = path[-1]
			for node in get_tree().get_nodes_in_group("player_unit"):
				var tile_position = world_to_map(node.position, Vector2(56, 40))
				if tile_position == from:
					node.position = map_to_world(to, Vector2(56, 40))
		{"type": "mech_selected", ..}:
			get_tree().call_group("unit_hud", "show")
		{"type": "mech_deselected", ..}:
			get_tree().call_group("unit_ui", "free")
		_:
			print("Event unhandled")
			print(event)

func _on_node_input_event(viewport, event, shape_idx, node):
	var tile_size = Vector2(56, 40)
	var tile_position = world_to_map(node.position, tile_size)
	var game_manager = get_tree().current_scene.get_node('GameManager')
	
	if is_left_click(event):
		game_manager.handle({"type": "click", "position": tile_position})
	elif is_right_click(event):
		# TODO AS: Right Click command?
		pass

func _on_node_mouse_entered(node):
	var tile_size = Vector2(56, 40)
	var tile_position = world_to_map(node.position, tile_size)
	var game_manager = get_tree().current_scene.get_node('GameManager')
	game_manager.handle({"type": "hover", "position": tile_position})

func _on_node_mouse_exited(node):
	# TODO AS: Ignoring mouse exit for now
	return
	var tile_size = Vector2(56, 40)
	var tile_position = world_to_map(node.position, tile_size)
	var game_manager = get_tree().current_scene.get_node('GameManager')
	game_manager.handle_mouse_exited(tile_position)

func listen_node(node):
	node.connect("input_event", self, "_on_node_input_event", [node])
	node.connect("mouse_entered", self, "_on_node_mouse_entered", [node])
	node.connect("mouse_exited", self, "_on_node_mouse_exited", [node])

func setup_hud():
	var repair = get_owner().get_node("UnitUI/VBoxContainer/HBoxContainer/Repair")
	repair.add_to_group("unit_hud")
	repair.connect("gui_input", self, "_on_repair_gui_input_event", [repair])
	
	var primary = get_owner().get_node("UnitUI/VBoxContainer/HBoxContainer/Primary")
	primary.add_to_group("unit_hud")
	primary.connect("gui_input", self, "_on_primary_gui_input_event", [primary])
	
	var avatar = get_owner().get_node("UnitUI/VBoxContainer/HBoxContainer/Avatar")
	avatar.add_to_group("unit_hud")
	get_tree().call_group("unit_hud", "hide")

func _on_repair_gui_input_event(event, node):
	print('Some event here')
	if is_left_click(event):
		var game_manager = get_tree().current_scene.get_node('GameManager')
		game_manager.handle({"type": "click", "ability": "repair"})
		
func _on_primary_gui_input_event(event, node):
	if is_left_click(event):
		var game_manager = get_tree().current_scene.get_node('GameManager')
		game_manager.handle({"type": "click", "ability": "primary"})
		
func is_left_click(event):
	return event is InputEventMouseButton \
		and event.button_index == BUTTON_LEFT \
		and event.pressed

func is_right_click(event):
	return event is InputEventMouseButton \
		and event.button_index == BUTTON_RIGHT \
		and event.pressed

func world_to_map(position, tile_size):
	var shift = Vector2(500, 200)
	position = position - shift
	var diff = (position.x * 2 / tile_size.x)
	var sum = (position.y * 2 / tile_size.y)
	var x = (sum - diff) / 2
	var y = diff + x
	return Vector2(x, y)

func map_to_world(position, tile_size):
	var shift = Vector2(500, 200)
	return shift + Vector2((position.y - position.x) * tile_size.x / 2, (position.x + position.y) * tile_size.y / 2)