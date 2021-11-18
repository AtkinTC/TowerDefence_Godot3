extends Node2D
class_name SpawnPointsNode

var spawn_points: Dictionary = {}
var spawn_points_array: Array = []
var recalculate: bool = false


func _ready() -> void:
	var index = 0
	for child in get_children():
		if(child is SpawnPoint):
			if(spawn_points.has(child.index)):
				while(spawn_points.has(index)):
					index += 1	
				child.index = index
				index += 1
			spawn_points[child.index] = child
			child.connect("tree_exiting", self, "_on_spawn_point_removed", [child.index])
			recalculate = true

func has_spawn_point(_index: int) -> bool:
	return spawn_points.has(_index)

func get_spawn_points_dict() -> Dictionary:
	return spawn_points

func get_spawn_points() -> Array:
	if(recalculate):
		var keys = spawn_points.keys()
		keys.sort()
		for key in keys:
			spawn_points_array.append(spawn_points[key])
	return spawn_points_array

func get_spawn_point(_index: int) -> SpawnPoint:
	return spawn_points.get(_index)
	
func _on_spawn_point_removed(_index) -> void:
	if(spawn_points.has(_index)):
		spawn_points.erase(_index)
		recalculate = true
