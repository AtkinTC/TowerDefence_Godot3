extends PathFollow2D
class_name BlueTank

signal base_damage(damage)

var active = true
var speed: float = 150
var max_hp: float = 50
var current_hp: float = max_hp

var base_damage: float = 20

onready var health_bar: TextureProgress = get_node("HealthBar")
onready var health_bar_offset: Vector2 = health_bar.get_position()

onready var impact_area := (get_node("ImpactArea") as RectExtents)
var projectile_impact = preload("res://Scenes/SupportScenes/ProjectileImpact.tscn")

var mapNav: Navigation2D = null
var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO

#func _init() -> void:
#	pass

func _ready() -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_bar.set_as_toplevel(true)
	
	yield(get_tree(), "idle_frame")
	var tree = get_tree()
	if tree.has_group("MapNavigation"):
		mapNav = tree.get_nodes_in_group("MapNavigation")[0]
	if tree.has_group("EnemyTarget"):
		target = tree.get_nodes_in_group("EnemyTarget")[0]

#func _process(delta) -> void:
#	pass

func _physics_process(delta) -> void:
	if active:
		move(delta)
		if(unit_offset == 1.0):
			## unit has reached end of path
			emit_signal("base_damage", base_damage)
			queue_free()
	health_bar.set_position(position + health_bar_offset)

func move(delta):
	set_offset(get_offset() + speed * delta)

func on_hit(damage: float) -> void:
	#print(self.get_name() + " hit for " + (damage as String) + " damage")
	impact()
	set_current_hp(current_hp-damage)
	if(current_hp <= 0):
		on_destroy()

func impact() -> void:
	randomize()
	var x_pos = randf() * (impact_area.size as Vector2).x
	randomize()
	var y_pos = randf() * (impact_area.size as Vector2).y
	var impact_location = Vector2(x_pos, y_pos) + (impact_area.offset as Vector2)
	var new_impact = projectile_impact.instance()
	new_impact.position = impact_location
	impact_area.add_child(new_impact)

func on_destroy() -> void:
	get_node("KinematicBody2D").queue_free()
	health_bar.visible = false
	active = false
	yield(get_tree().create_timer(0.5), "timeout")
	self.queue_free()
	
func set_current_hp(hp: float) -> void:
	current_hp = max(hp, 0)
	health_bar.value = current_hp
	
func get_pathed_distance_to_target() -> float:
	var path := (get_parent() as Path2D)
	var curve_length : float = (path.get_curve() as Curve2D).get_baked_length()
	
	return curve_length * (1.0 - unit_offset)
