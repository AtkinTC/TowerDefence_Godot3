extends Node2D
class_name GameMap

var navigation_map: NavigationMap
var tower_exclusion_map: TileMap
var enemy_spawner: EnemySpawner
var target_area: EnemyTarget
var enemies_node: Node2D
var towers_node: Node2D

var debug: bool = false;

#func _init() -> void:
#	pass

func _ready() -> void:
	navigation_map = get_node("NavigationMap") as NavigationMap
	tower_exclusion_map = get_node("TowerExclusion") as TileMap
	target_area = get_node("EnemyTarget") as EnemyTarget
	enemies_node = get_node("Enemies") as Node2D
	towers_node = get_node("Towers") as Node2D
	enemy_spawner = get_node("EnemySpawner") as EnemySpawner
	enemy_spawner.set_enemies_parent_node(enemies_node)
	enemy_spawner.set_navigation_map(navigation_map)
	enemy_spawner.set_map_name("STREAM")
	
	navigation_map.set_debug(debug)
	navigation_map.initialize_navigation(target_area.global_position)

#func _process(delta) -> void:
#	pass

#func _physics_process(delta) -> void:
#	pass

func get_navigation_map() -> NavigationMap:
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
	
func set_debug(_debug: bool) -> void:
	debug = _debug
	for child in self.get_children():
		if(child.has_method("set_debug")):
			child.set_debug(debug)
