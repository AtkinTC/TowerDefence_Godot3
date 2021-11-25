extends DestructableStructure
class_name SpawnerStructure

func get_class() -> String:
	return "SpawnerStructure"

export(PackedScene) var spawn_unit_scene: PackedScene

export(int) var spawn_delay_time: int = -1
var spawn_delay_remaining: int

var spawn_position_set: bool = false
var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	if(spawn_delay_time <= 0):
		spawn_delay_time = (get_default_attribute(GameData.SPAWN_DELAY, 1) as float)
	spawn_delay_remaining = spawn_delay_time

func _physics_process(delta: float) -> void:
	process_turn(delta)

func process_turn(delta: float) -> void:
	if(taking_turn):
		#spawn unit
		spawn_unit()
		end_spawn_action()

func advance_time_units(units: int = 1):
	spawn_delay_remaining = max(0, spawn_delay_remaining - units)
	
func get_time_until_spawn() -> int:
	return spawn_delay_remaining
	
func start_spawn_action(_spawn_position: Vector2):
	spawn_position = _spawn_position
	spawn_position_set = true
	start_turn()
	
func end_spawn_action():
	spawn_position_set = false
	spawn_delay_remaining = spawn_delay_time
	end_turn()
	
func spawn_unit():
	if(spawn_unit_scene != null && spawn_position_set):
		var unit_instance := (spawn_unit_scene.instance() as Unit)
		unit_instance.set_global_position(spawn_position)
		unit_instance.setup_from_attribute_dictionary({"faction": faction})
		var unit_controller := (ControllersRef.get_controller_reference("units_node") as UnitsNode)
		unit_controller.add_unit(unit_instance)
