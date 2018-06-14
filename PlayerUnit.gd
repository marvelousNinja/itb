extends Area2D

func _ready():
	add_to_group("player_units")

func outline():
	$Sprite.set_material(ShaderMaterial.new())
	$Sprite.material.set_shader(preload("res://Outline.shader"))

func reset_outline():
	# TODO AS: Causes some stagger
	$Sprite.set_material(null)