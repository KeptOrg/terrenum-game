tool
extends Spatial

var RADIUS = 7.99
var X_DIR = Vector3(RADIUS * sqrt(3) / 2, 0, RADIUS * 1.5)
var Y_DIR = Vector3(- RADIUS * sqrt(3) / 2, 0, RADIUS * 1.5)

export(Vector3) var coordinates = Vector3(0, 0, 0) setget _set_coordinates

func _ready():
	pass

func _set_coordinates(new_coordinates):
	coordinates = Vector3(new_coordinates.x, new_coordinates.y, 0 - new_coordinates.x - new_coordinates.y)
	
	reposition()

func reposition():
	translation = coordinates.x * X_DIR + coordinates.y * Y_DIR
	rotation_degrees.y = 60 * (randi() % 6)