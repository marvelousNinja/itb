extends Node2D

func _enter_tree():
	$Battlefield.connect("node_added", self, "_on_node_added")

func _on_node_added(node):
	node.connect("input_event", self, "_on_node_input_event", [node])

func _on_node_input_event(viewport, event, shape_idx, node):
	# TODO AS: Implement that thingy
	# $Overlay.reset_path()
	
	# TODO AS: Should be saved beforehand
	var from = Vector2(0, 0)
	var to = world_to_map(node.position, Vector2(56, 40))
	# var to = Vector2(0, 3)
	# TODO AS: How to represent map?
	var map = null
	var path = shortest_path(map, from, to)

func ___on_node_input_event(viewport, event, shape_idx, node):
	$Overlay.reset_overlay_tiles()
	# TODO AS: Rebuild with groups
	if node.get_name().begins_with('Unit'):
		var map_position = world_to_map(node.position, Vector2(56, 40))
		
		var coords = []
		
		for x in [-1, 1]:
			for y in [-1, 1]:
				var overlay_position = map_to_world(map_position + Vector2(x, y), Vector2(56, 40))
				coords.append(overlay_position)
		
		$Overlay.overlay_tiles(coords)

# TODO AS: Buggy, but revise later
func world_to_map(position, tile_size):
	var diff = (position.x * 2 / tile_size.x)
	var sum = (position.y * 2 / tile_size.y)
	var x = (sum - diff) / 2
	var y = diff + x
	return Vector2(x, y)

func map_to_world(position, tile_size):
	return Vector2((position.y - position.x) * tile_size.x / 2, (position.x + position.y) * tile_size.y / 2)

func shortest_path(map, from, to):
	# Distances should be part of the map
	var distances = []
	distances.resize(4 * 4)
	for x in range(4):
		for y in range(4):
			var vertex_distances = []
			for i in range(4 * 4): vertex_distances.append(9999)
			# Distance to self - zero
			vertex_distances[y*4 + x] = 0
			# Horizontal and vertical neighbors are near
			vertex_distances[clamp(y-1, 0, 3)*4 + x] = 1
			vertex_distances[clamp(y+1, 0, 3)*4 + x] = 1
			vertex_distances[y*4 + clamp(x + 1, 0, 3)] = 1
			vertex_distances[y*4 + clamp(x - 1, 0, 3)] = 1
			distances[y*4 + x] = vertex_distances
	# Dijkstra part
	var initial_node = int(from.y * 4 + from.x)
	var destination_node = int(to.y * 4 + to.x)
	
	# Dijkstra part from Cracking code interview
	var previous = []
	for i in range(4 * 4): previous.append(null)
	
	var path_weight = []
	for i in range(4 * 4): path_weight.append(9999)
	
	path_weight[initial_node] = 0
	
	var remaining = []
	for i in range(4 * 4): remaining.append(i)
	
	while !remaining.empty():
		var min_value = path_weight[remaining[0]]
		var min_node = remaining[0]
		
		for node in remaining:
			if path_weight[node] < min_value:
				min_value = path_weight[node]
				min_node = node
		var n = min_node
		
		var neighbors = []
		var orig_y = min_node / 4
		var orig_x = min_node - orig_y * 4
		
		neighbors.append(clamp(orig_y - 1, 0, 3) * 4 + orig_x)
		neighbors.append(clamp(orig_y + 1, 0, 3) * 4 + orig_x)
		neighbors.append(orig_y * 4 + clamp(orig_x - 1, 0, 3))
		neighbors.append(orig_y * 4 + clamp(orig_x + 1, 0, 3))
		
		for neighbor in neighbors:
			var weight = path_weight[neighbor]
			var new_weight = min_value + distances[n][neighbor]
			if new_weight < weight:
				path_weight[neighbor] = new_weight
				previous[neighbor] = n
		
		remaining.erase(n)

	var path = []
	var next_node = destination_node
	var orig_y = next_node / 4
	var orig_x = next_node - orig_y * 4
	while next_node != null:
		orig_y = next_node / 4
		orig_x = next_node - orig_y * 4
		path.push_front(Vector2(orig_x, orig_y))
		next_node = previous[next_node]
	print(path)
	return path

func is_left_click(event):
	return event is InputEventMouseButton \
		and event.button_index == BUTTON_LEFT \
		and event.pressed

func is_right_click(event):
	return event is InputEventMouseButton \
		and event.button_index == BUTTON_RIGHT \
		and event.pressed