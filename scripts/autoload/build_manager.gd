extends Node

signal build_mode_entered(mode: int)
signal build_mode_exited()
signal construction_completed(object)

enum BuildMode { NONE, SLOPE, LIFT, HUB }
enum SlopeDifficulty { GREEN, BLUE, RED, BLACK }
enum LiftType { TELESKI, TELESIEGES_4, TELESIEGES_6, TELECABINE_8, TELEPHERIQUE }

const TERRAIN_PHYSICS_LAYER := 1  # Physics layer 1 = terrain (defined in project.godot)

var current_mode: BuildMode = BuildMode.NONE
var selected_slope_difficulty: SlopeDifficulty = SlopeDifficulty.BLUE
var selected_lift_type: LiftType = LiftType.TELESIEGES_4

var _slope_points: Array = []
var _lift_start_hub = null
var _camera: Camera3D = null
var _game_world = null


func _ready() -> void:
	set_process_input(true)


func set_camera(cam: Camera3D) -> void:
	_camera = cam


func set_game_world(world) -> void:
	_game_world = world


func enter_build_mode(mode: BuildMode) -> void:
	current_mode = mode
	_slope_points.clear()
	_lift_start_hub = null
	emit_signal("build_mode_entered", mode)


func exit_build_mode() -> void:
	current_mode = BuildMode.NONE
	_slope_points.clear()
	_lift_start_hub = null
	emit_signal("build_mode_exited")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("build_cancel"):
		if current_mode != BuildMode.NONE:
			exit_build_mode()
		return

	if current_mode == BuildMode.NONE:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			match current_mode:
				BuildMode.SLOPE:
					if event.button_index == MOUSE_BUTTON_LEFT:
						_handle_slope_click(event.position)
					elif event.button_index == MOUSE_BUTTON_RIGHT:
						_finalize_slope()
				BuildMode.LIFT:
					if event.button_index == MOUSE_BUTTON_LEFT:
						_handle_lift_click(event.position)
				BuildMode.HUB:
					if event.button_index == MOUSE_BUTTON_LEFT:
						_handle_hub_click(event.position)


func _raycast_terrain(screen_pos: Vector2) -> Dictionary:
	if _camera == null:
		return {}
	var space_state := _camera.get_world_3d().direct_space_state
	var ray_origin := _camera.project_ray_origin(screen_pos)
	var ray_end := ray_origin + _camera.project_ray_normal(screen_pos) * 2000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, TERRAIN_PHYSICS_LAYER)
	var result := space_state.intersect_ray(query)
	return result


func _handle_slope_click(screen_pos: Vector2) -> void:
	var hit := _raycast_terrain(screen_pos)
	if hit.is_empty():
		return
	_slope_points.append(hit.position)


func _finalize_slope() -> void:
	if _slope_points.size() < 2:
		_slope_points.clear()
		return

	if not EconomyManager.can_afford(10000.0):
		push_warning("BuildManager: insufficient funds for slope")
		_slope_points.clear()
		return

	var slope_script := load("res://scenes/infrastructure/ski_slope.gd")
	var slope = slope_script.new()
	slope.difficulty = selected_slope_difficulty

	var path := Path3D.new()
	var curve := Curve3D.new()
	for pt in _slope_points:
		curve.add_point(pt)
	path.curve = curve
	slope.add_child(path)

	if _game_world:
		_game_world.add_child(slope)

	# Auto-connect nearest hubs
	if _slope_points.size() >= 2:
		var start_hub = NetworkGraph.find_nearest_hub(_slope_points[0], 80.0)
		var end_hub = NetworkGraph.find_nearest_hub(_slope_points[-1], 80.0)
		if start_hub:
			slope.departure_hub = start_hub
			start_hub.connected_slope_departures.append(slope)
		if end_hub:
			slope.arrival_hub = end_hub
			end_hub.connected_slope_arrivals.append(slope)

	slope._setup()
	var cost := slope.construction_cost
	EconomyManager.purchase(cost, "Construction piste " + slope.slope_name)

	emit_signal("construction_completed", slope)
	_slope_points.clear()


func _handle_lift_click(screen_pos: Vector2) -> void:
	var hit := _raycast_terrain(screen_pos)
	if hit.is_empty():
		return

	if _lift_start_hub == null:
		# First click: find or remember start hub
		_lift_start_hub = NetworkGraph.find_nearest_hub(hit.position, 80.0)
		if _lift_start_hub == null:
			# No hub nearby; create one automatically
			_place_hub_at(hit.position)
			_lift_start_hub = NetworkGraph.find_nearest_hub(hit.position, 80.0)
	else:
		# Second click: create lift from start to end
		var end_hub = NetworkGraph.find_nearest_hub(hit.position, 80.0)
		if end_hub == null:
			_place_hub_at(hit.position)
			end_hub = NetworkGraph.find_nearest_hub(hit.position, 80.0)

		if end_hub and _lift_start_hub and end_hub != _lift_start_hub:
			_create_lift(_lift_start_hub, end_hub)
		_lift_start_hub = null


func _create_lift(start_hub, end_hub) -> void:
	var lift_script := load("res://scenes/infrastructure/ski_lift.gd")
	var lift = lift_script.new()
	lift.lift_type = selected_lift_type
	lift.departure_hub = start_hub
	lift.arrival_hub = end_hub

	var path := Path3D.new()
	var curve := Curve3D.new()
	curve.add_point(start_hub.global_position)
	curve.add_point(end_hub.global_position)
	path.curve = curve
	lift.add_child(path)

	if _game_world:
		_game_world.add_child(lift)

	start_hub.connected_lift_departures.append(lift)
	end_hub.connected_lift_arrivals.append(lift)

	lift._setup()
	var length := start_hub.global_position.distance_to(end_hub.global_position)
	var cost_per_m: float = lift.LIFT_CONFIG[selected_lift_type]["cost_per_m"]
	var total_cost := length * cost_per_m

	if not EconomyManager.purchase(total_cost, "Construction remontée"):
		push_warning("BuildManager: insufficient funds for lift")
		lift.queue_free()
		return

	emit_signal("construction_completed", lift)


func _handle_hub_click(screen_pos: Vector2) -> void:
	var hit := _raycast_terrain(screen_pos)
	if hit.is_empty():
		return
	_place_hub_at(hit.position)


func _place_hub_at(world_pos: Vector3) -> void:
	var hub_cost := 5000.0
	if not EconomyManager.can_afford(hub_cost):
		push_warning("BuildManager: insufficient funds for hub")
		return

	var hub_script := load("res://scenes/infrastructure/hub.gd")
	var hub = hub_script.new()
	hub.hub_type = 2  # INTERMEDIATE

	if _game_world:
		_game_world.add_child(hub)
	hub.global_position = world_pos

	EconomyManager.purchase(hub_cost, "Construction hub")
	emit_signal("construction_completed", hub)
