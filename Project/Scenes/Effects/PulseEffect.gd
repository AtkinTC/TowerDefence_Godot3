extends Effect

var duration_timer: Timer
var source: Node2D
var final_radius: float
var current_radius: float
var duration: float

onready var tween: Tween = $Tween

func setup_from_attribute_dictionary(_attribute_dict: Dictionary):
	.setup_from_attribute_dictionary(_attribute_dict)
	source = _attribute_dict.get("source")
	current_radius = 0
	final_radius = _attribute_dict.get("radius", 0)
	duration = _attribute_dict.get("duration", -1)

func _ready() -> void:
	tween.interpolate_property(self, "current_radius", current_radius, final_radius,
		duration/2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
	
	if(duration >= 0):
		duration_timer = Timer.new()
		duration_timer.set_one_shot(true)
		duration_timer.connect("timeout", self, "_on_duration_timeout")
		add_child(duration_timer)
		duration_timer.start(duration)
		

func _process(delta) -> void:
	update()
	
#func _physics_process(delta) -> void:
	#current_radius += 1

func _draw():
	draw_circle_custom(current_radius)

func draw_circle_custom(radius, maxerror = 0.25):
	if radius <= 0.0:
		return

	var maxpoints = 1024 # I think this is renderer limit

	var numpoints = ceil(PI / acos(1.0 - maxerror / radius))
	numpoints = clamp(numpoints, 3, maxpoints)

	var points = PoolVector2Array([])

	for i in numpoints:
		var phi = i * PI * 2.0 / numpoints
		var v = Vector2(sin(phi), cos(phi))
		points.push_back(v * radius)

	draw_colored_polygon(points, Color(1.0, 0, 0, 0.5)) 	

func _on_duration_timeout() -> void:
	self.visible = false
	self.queue_free()
