class_name SkiSlope
extends Node3D

## SkiSlope — a downhill ski run connecting two hubs.

enum Difficulty { GREEN, BLUE, RED, BLACK }

@export var slope_name: String = "Piste"
@export var difficulty: Difficulty = Difficulty.BLUE
@export var snow_quality: float = 1.0  # 0.0 – 1.0
@export var is_open: bool = true
@export var max_skiers: int = 80

const maintenance_cost_per_day: float = 500.0

var departure_hub: Hub = null
var arrival_hub: Hub = null

var length_meters: float = 0.0
var altitude_drop: float = 0.0
var average_gradient: float = 0.0
var construction_cost: float = 0.0

var _path: Path3D = null
var _mesh_instance: MeshInstance3D = null

const DIFFICULTY_COLORS := {
	Difficulty.GREEN: Color(0.1, 0.7, 0.1, 0.6),
	Difficulty.BLUE:  Color(0.1, 0.3, 0.9, 0.6),
	Difficulty.RED:   Color(0.9, 0.1, 0.1, 0.6),
	Difficulty.BLACK: Color(0.05, 0.05, 0.05, 0.8),
}

const DIFFICULTY_NAMES := {
	Difficulty.GREEN: "Verte",
	Difficulty.BLUE:  "Bleue",
	Difficulty.RED:   "Rouge",
	Difficulty.BLACK: "Noire",
}

const DIFFICULTY_FACTORS := {
	Difficulty.GREEN: 0.6,
	Difficulty.BLUE:  0.8,
	Difficulty.RED:   1.0,
	Difficulty.BLACK: 1.4,
}


func _ready() -> void:
	# Find the Path3D child created by BuildManager
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
	if _path == null or _path.curve == null or _path.curve.point_count < 2:
		return

	_calculate_metrics()
	_build_visual()

	var difficulty_index := int(difficulty)
	slope_name = "Piste %s #%d" % [DIFFICULTY_NAMES[difficulty], NetworkGraph.all_slopes.size() + 1]
	construction_cost = length_meters * 50.0 * (difficulty_index + 1)

	NetworkGraph.register_slope(self)


func _calculate_metrics() -> void:
	if _path == null or _path.curve == null:
		return

	length_meters = _path.curve.get_baked_length()
	if _path.curve.point_count >= 2:
		var start_pos: Vector3 = _path.curve.get_point_position(0)
		var end_pos: Vector3 = _path.curve.get_point_position(_path.curve.point_count - 1)
		altitude_drop = start_pos.y - end_pos.y
		if length_meters > 0:
			average_gradient = altitude_drop / length_meters


func _build_visual() -> void:
	if _mesh_instance != null:
		_mesh_instance.queue_free()

	_mesh_instance = MeshInstance3D.new()
	var arr_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = DIFFICULTY_COLORS[difficulty]
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var width := 8.0
	var baked_pts := _path.curve.get_baked_points()
	if baked_pts.size() < 2:
		return

	for i in range(baked_pts.size() - 1):
		var a: Vector3 = baked_pts[i]
		var b: Vector3 = baked_pts[i + 1]
		var dir := (b - a).normalized()
		var side := dir.cross(Vector3.UP).normalized() * (width * 0.5)
		st.set_color(DIFFICULTY_COLORS[difficulty])
		st.add_vertex(a - side + Vector3(0, 0.1, 0))
		st.add_vertex(a + side + Vector3(0, 0.1, 0))

	var idx := baked_pts.size() - 1
	var last_a: Vector3 = baked_pts[idx - 1]
	var last_b: Vector3 = baked_pts[idx]
	var last_dir := (last_b - last_a).normalized()
	var last_side := last_dir.cross(Vector3.UP).normalized() * (width * 0.5)
	st.set_color(DIFFICULTY_COLORS[difficulty])
	st.add_vertex(last_b - last_side + Vector3(0, 0.1, 0))
	st.add_vertex(last_b + last_side + Vector3(0, 0.1, 0))

	st.commit(arr_mesh)
	_mesh_instance.mesh = arr_mesh
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)


func get_descent_time(skier) -> float:
	if length_meters <= 0.0:
		return 30.0
	var skill: float = skier.skill_level if skier != null else 1.0
	var diff_factor: float = DIFFICULTY_FACTORS[difficulty]
	return length_meters / (8.0 * skill * diff_factor)


func _exit_tree() -> void:
	NetworkGraph.unregister_slope(self)
