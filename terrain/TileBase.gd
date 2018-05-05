tool
extends Spatial

var EPS = 0.01
var height = 1.0
var path_width = 1.0
var radius = 8

export(Vector3) var coordinates = Vector3(0, 0, 0) setget set_coordinates

func _ready():
	pass

func set_coordinates(new_coordinates):
	coordinates = Vector3(new_coordinates.x, new_coordinates.y, 0 - new_coordinates.x - new_coordinates.y)
	
	reposition()

func reposition():
	var x_dir = Vector3((radius - EPS) * sqrt(3) / 2, 0, (radius - EPS) * 1.5)
	var y_dir = Vector3(- (radius - EPS) * sqrt(3) / 2, 0, (radius - EPS) * 1.5)
	translation = coordinates.x * x_dir + coordinates.y * y_dir
