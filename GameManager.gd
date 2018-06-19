extends Node2D

var store = EventStore.new()
var battlefield = null

class Utils:
	static func unit_on(units, position):
		for unit in units:
			if position == unit["position"]:
				return unit

	# TODO AS: Actually use distance
	static func tiles_in_distance(source_position, distance):
		return [
			source_position + Vector2(1, 0),
			source_position + Vector2(-1, 0),
			source_position + Vector2(0, 1),
			source_position + Vector2(0, -1)
		]
	
	static func unit_can_move(unit):
		return unit["can_move"]
	
	static func unit_can_cast(unit):
		return unit["can_cast"]
	
	static func ability_target_tiles(source_position, ability):
		if ability == 'repair':
			return [source_position]
		elif ability == 'primary':
			return [
				source_position + Vector2(1, 0),
				source_position + Vector2(-1, 0),
				source_position + Vector2(0, 1),
				source_position + Vector2(0, -1)
			]
		else:
			return []
	
	static func shortest_path(map, from, to):
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
class MechAbilitySelected:
	func on_enter(game):
		game.apply({"type": "overlay_reset"})
		game.apply({
			"type": "overlay_shown", 
			"coords": Utils.ability_target_tiles(
				game.selected_mech_position,
				game.selected_ability
			)
		})
	
	func handle(game, command):
		match command:
			{"type": "hover", "position": var position, ..}:
				# TODO AS: Ground tile hover
				# TODO AS: Enemy unit hover
				# TODO AS: Damage prediction
				pass
			{"type": "click", "position": var position, ..}:
				# TODO AS: Ability cast
				game.apply({"type": "overlay_reset"})
				game.apply({"type": "mech_ability_cast", "position": position})
			_:
				print("Unknown command")
				print(self)
				print(command)
class MechSelected:
	func on_enter(game):
		game.apply({"type": "overlay_reset"})
		game.apply({"type": "overlay_shown", "coords": Utils.tiles_in_distance(game.selected_mech_position, 1)})

	func handle(game, command):
		match command:
			{"type": "hover", "position": var position, ..}:
				var unit = Utils.unit_on(game.units, game.selected_mech_position)
				if unit and Utils.unit_can_move(unit):
					var path = Utils.shortest_path(
						null,
						game.selected_mech_position,
						position
					)
					
					game.apply({"type": "path_reset"})
					game.apply({"type": "path_shown", "coords": path})
			{"type": "click", "position": var position, ..}:
				var unit = Utils.unit_on(game.units, game.selected_mech_position)
				if unit and Utils.unit_can_move(unit):
					var path = Utils.shortest_path(
						null,
						game.selected_mech_position,
						position
					)
					game.apply({"type": "path_reset"})
					game.apply({"type": "overlay_reset"})
					game.apply({"type": "mech_moved", "path": path})
			{"type": "click", "ability": var ability, ..}:
				var unit = Utils.unit_on(game.units, game.selected_mech_position)
				if unit and Utils.unit_can_cast(unit):
					game.apply({"type": "mech_ability_selected", "ability": ability})
			_:
				print("Unknown command")
				print(self)
				print(command)
class Idle:
	func on_enter(game):
		pass
	
	func handle(game, command):
		match command:
			{"type": "start_battle", ..}:
				# generates map
				game.apply({"type": "combat_started"})
				game.apply({"type": "mech_deployed", "tile_position": Vector2(0, 0)})
				game.apply({"type": "vek_emerged", "tile_position": Vector2(3, 1)})
			{"type": "hover", "position": var position, ..}:
				game.apply({"type": "overlay_reset"})
				
				var unit = Utils.unit_on(game.units, position)
				# TODO AS: Hover on tile
				# TODO AS: Hover on enemy
				if unit and unit.type == "mech" and Utils.unit_can_move(unit):
					game.apply({
						"type": "overlay_shown",
						"coords": Utils.tiles_in_distance(position, 1)
					})
			{"type": "click", "position": var position, ..}:
				var unit = Utils.unit_on(game.units, position)
				if unit and unit.type == "mech" and (Utils.unit_can_move(unit) or Utils.unit_can_cast(unit)):
					game.apply({"type": "mech_selected", "position": position})
			_:
				print("Unknown command")
				print(self)
				print(command)

class Game:
	var pending_events = []
	var units = []
	var selected_mech_position = null
	var selected_ability = null
	var state = Idle.new()

	func change_state(new_state):
		state = new_state
		state.on_enter(self)

	func handle(command):
		state.handle(self, command)

	func apply(event):
		match event:
			{"type": "combat_started", ..}:
				pass
			{"type": "mech_deployed", ..}:
				units.append({"type": "mech", "position": event["tile_position"], "can_move": true, "can_cast": true})
			{"type": "vek_emerged", ..}:
				units.append({"type": "vek", "position": event["tile_position"]})
			{"type": "mech_selected", "position": var position, ..}:
				selected_mech_position = position
				change_state(MechSelected.new())
			{"type": "mech_moved", "path": var path, ..}:
				var unit = Utils.unit_on(units, path[0])
				unit["position"] = path[-1]
				unit["can_move"] = false
				selected_mech_position = path[-1]
			{"type": "mech_ability_selected", "ability": var ability, ..}:
				selected_ability = ability
				change_state(MechAbilitySelected.new())
			{"type": "mech_ability_cast", "position": var position, ..}:
				var unit = Utils.unit_on(units, selected_mech_position)
				unit["can_cast"] = false
				selected_ability = null
				selected_mech_position = null
				change_state(Idle.new())
			_:
				print("Unknown event")
				print(self)
				print(event)

		pending_events.append(event)

	func reset_pending_events():
		pending_events = []

class EventStore:
	var events = []
	
	func push(event):
		events.append(event)

func _ready():
	battlefield = get_tree().current_scene.get_node("Battlefield")
	handle({"type": "start_battle"})

func handle(command):
	var game = Game.new()
	for event in store.events: game.apply(event)
	game.reset_pending_events()
	
	game.handle(command)
	
	for event in game.pending_events: store.push(event)
	
	battlefield.handle_events(game.pending_events)