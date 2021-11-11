extends Tower
class_name GunTower

var tower_damage: float = -1
var tower_rof: float = -1
var tower_proj_type: String
var ready_to_fire: bool = false

var enemy_array: Array = []
var target: Node2D

func _init(_tower_type: String = "").(_tower_type):
	if(tower_type.length() > 0):
		initialize_default_values()

func initialize_default_values() -> void:
	if (tower_type != null && tower_type.length() > 0):
		var tower_data : Dictionary = (GameData.tower_data as Dictionary).get(tower_type)
		if tower_data != null:
			tower_range = (tower_data.get(GameData.RANGE, -1) as float)
			tower_rof = (tower_data.get(GameData.ROF, -1) as float)
			tower_damage = (tower_data.get(GameData.DAMAGE, -1) as float)
			tower_proj_type = (tower_data.get(GameData.PROJTYPE, "") as String)

func _ready():
	var rangeAreaShape: CollisionShape2D = get_node("RangeArea/CollisionShape2D") as CollisionShape2D
	if active:
		if rangeAreaShape:
			(rangeAreaShape.get_shape() as Shape2D).radius = 0.5 * tower_range
		yield(get_tree().create_timer(1.0/tower_rof), "timeout")
		ready_to_fire = true
	else:
		if rangeAreaShape:
			(rangeAreaShape.get_shape() as Shape2D).radius = 0

func _physics_process(_delta):
	if active && enemy_array.size() > 0:
		select_target()
		turn()
		fire()
	else:
		target = null

func turn() -> void:
	if not get_node("AnimationPlayer").is_playing():
		if target:
			get_node("Turret").look_at(target.position)
	
func select_target() -> void:
	# farthest ahead targetting
	target = get_target_by_progress()

func get_target_by_progress() -> Node2D:
	var lead_target: Node2D = null
	var max_progress: float = -1.0
	for i in enemy_array:
		var distance: float = -1.0
		var className = i.get_class()
		if(i is Enemy):
			distance = (i as Enemy).get_pathed_distance_to_target();
		if(distance >= 0 && (distance < max_progress || max_progress == -1)):
			max_progress = distance
			lead_target = (i as Node2D)
	return lead_target
	
func get_target_by_closest() -> Node2D:
	var closest_target: Node2D = null
	var closest_distance: float = -1
	for i in enemy_array:
		var distance: float = self.position.distance_squared_to((i as Node2D).position)
		if(closest_distance == -1 || distance < closest_distance):
			closest_distance = distance
			closest_target = (i as Node2D)
	return closest_target

func fire() -> void:
	if ready_to_fire && target:
		ready_to_fire = false
		if tower_proj_type == "Instant":
			fire_instant()
		elif tower_proj_type == "Missile":
			fire_missile()
		target.on_hit(tower_damage)
		yield(get_tree().create_timer(1.0/tower_rof), "timeout")
		ready_to_fire = true

func fire_instant() -> void:
	get_node("AnimationPlayer").play("Fire")

func fire_missile() -> void:
	pass

func _on_RangeArea_body_entered(body: Node) -> void:
	if(body is Enemy):
		enemy_array.append(body)

func _on_RangeArea_body_exited(body: Node) -> void:
	if(body is Enemy):
		enemy_array.erase(body)
