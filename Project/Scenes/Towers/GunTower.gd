extends Tower
class_name GunTower

var tower_damage: float = -1
var tower_rof: float = -1
var tower_range: float = -1
var tower_proj_type: String
var ready_to_fire: bool = false

var enemy_array: Array = []

func _init(_tower_type: String = "").(_tower_type):
	pass

func initialize_default_values() -> void:
	.initialize_default_values()
	tower_rof = (get_default_attribute(GameData.ROF, -1) as float)
	tower_damage = (get_default_attribute(GameData.DAMAGE, -1) as float)
	tower_range = (get_default_attribute(GameData.RANGE, -1) as float)
	tower_proj_type = (get_default_attribute(GameData.PROJTYPE, "") as String)

func _ready():
	var rangeAreaShape: CollisionShape2D = get_node("RangeArea/CollisionShape2D") as CollisionShape2D
	if active:
		if rangeAreaShape:
			(rangeAreaShape.get_shape() as Shape2D).radius = tower_range
		yield(get_tree().create_timer(1.0/tower_rof), "timeout")
		ready_to_fire = true
	else:
		if rangeAreaShape:
			(rangeAreaShape.get_shape() as Shape2D).radius = 0

func _physics_process(_delta):
	if active && enemy_array.size() > 0:
		select_target(TARGETING_TYPE_ENUM.PROGRESS, enemy_array)
		turn()
		fire()
	else:
		target = null

func turn() -> void:
	if not get_node("AnimationPlayer").is_playing():
		if target:
			get_node("Turret").look_at(target.position)

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
