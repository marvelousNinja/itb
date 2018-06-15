extends Node2D

var selected_unit = null
var battlefield = null
var game_state = null
var overlay_shown = false

func _ready():
	battlefield = get_tree().current_scene.get_node("Battlefield")

	game_state = {
		"mechs": [{
			"tile_position": Vector2(0, 0)
		}]
	}

	var events = [
		{"type": "combat_started"},
		{"type": "mech_deployed"}
	]
	battlefield.handle_events(events)

func handle_mouse_entered(tile_position):
	var events = []
	
	if selected_unit:
		var path = shortest_path(
			null,
			selected_unit["tile_position"],
			tile_position
		)
		
		events.append({"type": "path_shown", "coords": path})
	else:
		var unit = unit_on(game_state, tile_position)
		
		if unit:
			overlay_shown = true
				
			events.append({
				"type": "overlay_shown",
				"coords": tiles_in_distance(tile_position, 1)
			})

	battlefield.handle_events(events)

func handle_mouse_exited(tile_position):
	var events = []
	if !selected_unit and overlay_shown:
		overlay_shown = false
		events.append({
			"type": "overlay_reset"
		})
	battlefield.handle_events(events)

func handle_left_click(tile_position):
	var events = []
	var unit = unit_on(game_state, tile_position)
	if unit:
		selected_unit = unit
		overlay_shown = true
		
		events.append({
			"type": "mech_selected",
			"tile_position": tile_position
		})
		
		events.append({
			"type": "overlay_reset"
		})
		
		events.append({
			"type": "overlay_shown",
			"coords": tiles_in_distance(tile_position, 1)
		})
	battlefield.handle_events(events)
	
func handle_right_click(tile_position):
	var events = []
	selected_unit = null
	overlay_shown = false
	
	events.append({
		"type": "mech_deselected",
		"tile_position": tile_position
	})
	
	events.append({
		"type": "overlay_reset"
	})
	
	events.append({
		"type": "path_reset"
	})
	
	battlefield.handle_events(events)

func unit_on(game_state, tile_position):
	var units = game_state["mechs"]
	for unit in units:
		if tile_position == unit["tile_position"]:
			return unit

# TODO AS: Actually use distance
func tiles_in_distance(source_position, distance):
	return [
		source_position + Vector2(1, 0),
		source_position + Vector2(-1, 0),
		source_position + Vector2(0, 1),
		source_position + Vector2(0, -1)
	]

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