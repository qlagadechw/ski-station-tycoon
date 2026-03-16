class_name SkiLift
extends Node3D

## SkiLift — a mechanical lift transporting skiers uphill between two hubs.

enum LiftType { TELESKI, TELESIEGES_4, TELESIEGES_6, TELECABINE_8, TELEPHERIQUE }

const LIFT_CONFIG := {
	LiftType.TELESKI: {
		"name": "Téléski",
		"capacity": 1,
		"speed": 3.0,
		"throughput": 900,
		"cost_per_m": 800.0,
		"maintenance_daily": 200.0,
		"revenue_per_skier": 0.5,
	},
	LiftType.TELESIEGES_4: {
		"name": "Télésiège 4 places",
		"capacity": 4,
		"speed": 5.0,
		"throughput": 2400,
		"cost_per_m": 2500.0,
		"maintenance_daily": 800.0,
		"revenue_per_skier": 1.5,
	},
	LiftType.TELESIEGES_6: {
		"name": "Télésiège 6 places",
		"capacity": 6,
		"speed": 5.5,
		"throughput": 3000,
		"cost_per_m": 3500.0,
		"maintenance_daily": 1200.0,
		"revenue_per_skier": 2.0,
	},
	LiftType.TELECABINE_8: {
		"name": "Télécabine 8 places",
		"capacity": 8,
		"speed": 6.0,
		"throughput": 3600,
		"cost_per_m": 5000.0,
		"maintenance_daily": 2000.0,
		"revenue_per_skier": 3.0,
	},
	LiftType.TELEPHERIQUE: {
		"name": "Téléphérique",
		"capacity": 80,
		"speed": 10.0,
		"throughput": 1500,
		"cost_per_m": 15000.0,
		"maintenance_daily": 5000.0,
		"revenue_per_skier": 5.0,
	},
}

@export var lift_type: LiftType = LiftType.TELESIEGES_4
@export var is_open: bool = true

var departure_hub: Hub = null
var arrival_hub: Hub = null
var lift_name: String = ""
var length_meters: float = 0.0

var _path: Path3D = null
var _queue: Array = []
var _riders: Array = []


func _ready() -> void:
	for child in get_children():
		if child is Path3D:
			_path = child
			break
	if _path == null:
		_path = Path3D.new()
		_path.curve = Curve3D.new()
		add_child(_path)
	_setup()


func _setup() -> void:
	var config := LIFT_CONFIG[lift_type]
	lift_name = config["name"] + " #%d" % (NetworkGraph.all_lifts.size() + 1)

	if _path != null and _path.curve != null and _path.curve.point_count >= 2:
		var start := _path.curve.get_point_position(0)
		var end := _path.curve.get_point_position(_path.curve.point_count - 1)
		length_meters = start.distance_to(end)

	_build_visual()
	NetworkGraph.register_lift(self)


func _build_visual() -> void:
	if _path == null or _path.curve == null or _path.curve.point_count < 2:
		return

	# Draw a simple line as cable using a box mesh stretched between points
	var start: Vector3 = _path.curve.get_point_position(0)
	var end_pt: Vector3 = _path.curve.get_point_position(_path.curve.point_count - 1)
	var mid: Vector3 = (start + end_pt) / 2.0
	var direction := (end_pt - start)
	var dist := direction.length()

	var cable := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, dist)
	cable.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3)
	cable.material_override = mat

	cable.position = mid - global_position
	cable.look_at_from_position(cable.position, end_pt, Vector3.UP)
	add_child(cable)


func board_skier(skier) -> void:
	if not is_open:
		return
	if not _queue.has(skier):
		_queue.append(skier)
	_try_depart()


func _try_depart() -> void:
	if _queue.is_empty():
		return
	var config := LIFT_CONFIG[lift_type]
	var cap: int = config["capacity"]
	var group := []
	for i in range(min(cap, _queue.size())):
		group.append(_queue.pop_front())

	for skier in group:
		_transport_skier(skier)


func _transport_skier(skier) -> void:
	if skier == null or not is_instance_valid(skier):
		return

	var config := LIFT_CONFIG[lift_type]
	var speed: float = config["speed"]
	var travel_time := length_meters / speed if speed > 0 else 10.0

	var rev: float = config["revenue_per_skier"]
	EconomyManager.add_revenue(rev, "lift_tickets", "Ticket remontée " + lift_name)

	skier.state = skier.State.ON_LIFT

	var tween := create_tween()
	if arrival_hub != null:
		tween.tween_property(skier, "global_position", arrival_hub.global_position + Vector3(0, 1, 0), travel_time)
	tween.tween_callback(func():
		if is_instance_valid(skier):
			skier.on_lift_arrived(arrival_hub)
	)


func get_daily_maintenance() -> float:
	return LIFT_CONFIG[lift_type]["maintenance_daily"]


func get_transport_time() -> float:
	var config := LIFT_CONFIG[lift_type]
	var speed: float = config["speed"]
	return length_meters / speed if speed > 0 else 10.0


func _exit_tree() -> void:
	NetworkGraph.unregister_lift(self)
