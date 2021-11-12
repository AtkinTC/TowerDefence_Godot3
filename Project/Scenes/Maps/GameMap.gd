extends Node2D
class_name GameMap

onready var navigation_map: TileMap = get_node("NavigationMap")
onready var tower_exclusion_map: TileMap = get_node("TowerExclusion")
onready var enemy_spawner: EnemySpawner =  get_node("EnemySpawner")
onready var target_area: EnemyTarget = get_node("EnemyTarget")
onready var enemies_node: Node2D = get_node("Enemies")
onready var towers_node: Node2D = get_node("Towers")
onready var effects_node: Node2D = get_node("Effects")

var debug: bool = false;

func _ready() -> void:
	enemy_spawner.set_map_name("STREAM")

func get_navigation_map() -> TileMap:
	return navigation_map

func get_tower_exclusion_map() -> TileMap:
	return tower_exclusion_map

func get_enemy_spawner() -> EnemySpawner:
	return enemy_spawner

func get_target_area() -> EnemyTarget:
	return target_area

func get_enemies_node() -> Node2D:
	return enemies_node

func get_towers_node() -> Node2D:
	return towers_node
	
func get_effects_node() -> Node2D:
	return effects_node
	
func set_debug(_debug: bool) -> void:
	debug = _debug
	for child in self.get_children():
		if(child.has_method("set_debug")):
			child.set_debug(debug)
