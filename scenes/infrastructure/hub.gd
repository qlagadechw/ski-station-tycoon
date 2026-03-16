class_name Hub
extends Node3D

## Hub — connection point linking slopes and lifts on the mountain.

enum Type { VILLAGE_SPAWN, MOUNTAIN_TOP, INTERMEDIATE, CUSTOM }

@export var hub_type: Type = Type.INTERMEDIATE
@export var hub_name: String = "Hub"
@export var radius: float = 30.0
@export var capacity: int = 50

var connected_lift_departures: Array = []
var connected_lift_arrivals: Array = []
var connected_slope_departures: Array = []
var connected_slope_arrivals: Array = []
var skiers_in_hub: Array = []

var _debug_mesh: MeshInstance3D = null


func _ready() -> void:
	_create_debug_visual()
	NetworkGraph.register_hub(self)


func _exit_tree() -> void:
	NetworkGraph.unregister_hub(self)


func _create_debug_visual() -> void:
	_debug_mesh = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.85
	torus.outer_radius = radius
	torus.rings = 16
	torus.ring_segments = 12
	_debug_mesh.mesh = torus

	var mat := StandardMaterial3D.new()
	match hub_type:
		Type.VILLAGE_SPAWN:
			mat.albedo_color = Color(0.2, 0.5, 1.0, 0.5)
		Type.MOUNTAIN_TOP:
			mat.albedo_color = Color(1.0, 0.5, 0.2, 0.5)
		_:
			mat.albedo_color = Color(0.3, 0.7, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_debug_mesh.material_override = mat

	add_child(_debug_mesh)

	# Label above hub
	var label := Label3D.new()
	label.text = hub_name
	label.position = Vector3(0, 3, 0)
	label.font_size = 24
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func get_available_departures() -> Array:
	var result: Array = []
	for slope in connected_slope_departures:
		if slope.is_open and slope.arrival_hub != null:
			result.append(slope)
	for lift in connected_lift_departures:
		if lift.is_open:
			result.append(lift)
	return result


func add_skier(skier) -> void:
	if not skiers_in_hub.has(skier):
		skiers_in_hub.append(skier)


func remove_skier(skier) -> void:
	skiers_in_hub.erase(skier)


func is_full() -> bool:
	return skiers_in_hub.size() >= capacity
