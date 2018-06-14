extends Node2D

func _ready():
	for n in get_tree().get_nodes_in_group("player_units"):
		n.connect("input_event", self, "_on_player_unit_input_event", [n])
	
	for n in get_tree().get_nodes_in_group("background"):
		n.connect("input_event", self, "_on_background_input_event")

func _on_player_unit_input_event(viewport, event, flag, node):
	if is_left_click(event):
		node.outline()
		var scene = preload("res://OverlayCell.tscn")
		var instance = scene.instance()
		instance.set_position(Vector2(40, 40))
		add_child(instance)
	

func _on_background_input_event(viewport, event, flag):
	if is_right_click(event):
		for n in get_tree().get_nodes_in_group("player_units"):
			n.reset_outline()
	
func is_left_click(event):
	return event is InputEventMouseButton \
		and event.button_index == BUTTON_LEFT \
		and event.pressed

func is_right_click(event):
	return event is InputEventMouseButton \
		and event.button_index == BUTTON_RIGHT \
		and event.pressed