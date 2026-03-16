class_name Skier
extends CharacterBody3D

## Skier — AI agent navigating the ski resort.

const SKIER_COLLISION_LAYER := 2   # Physics layer 2 = skiers (defined in project.godot)
const TERRAIN_COLLISION_MASK := 1  # Physics layer 1 = terrain (defined in project.godot)

enum State { SPAWNING, IN_HUB, QUEUING_LIFT, ON_LIFT, SKIING_DOWN, LEAVING }

var skill_level: float = 1.0
var max_runs: int = 5
var runs_completed: int = 0
var preferred_difficulty: int = 1  # SkiSlope.Difficulty.BLUE
var satisfaction: float = 1.0
var state: State = State.SPAWNING
var current_hub: Hub = null

var _color: Color
var _visual: MeshInstance3D = null
var _tween: Tween = null


func _ready() -> void:
	skill_level = randf_range(0.5, 1.5)
	max_runs = randi_range(3, 15)
	preferred_difficulty = randi_range(0, 3)
	_color = Color(randf(), randf(), randf())

	_create_visual()
	add_to_group("skiers")

	# Small delay before starting AI
	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
	state = State.IN_HUB
	_think()


func _create_visual() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.8

	_visual = MeshInstance3D.new()
	_visual.mesh = capsule

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color
	_visual.material_override = mat
	add_child(_visual)

	# Simple collision for CharacterBody3D
	var coll := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	coll.shape = shape
	add_child(coll)

	# Physics layer 2 = skiers; interacts with terrain (layer 1)
	collision_layer = SKIER_COLLISION_LAYER
	collision_mask = TERRAIN_COLLISION_MASK


func _think() -> void:
	if state == State.LEAVING:
		_leave()
		return

	if runs_completed >= max_runs or satisfaction < 0.2:
		state = State.LEAVING
		_leave()
		return

	if current_hub == null:
		return

	var available := current_hub.get_available_departures()
	if available.is_empty():
		# Nothing to do; wait and try again
		await get_tree().create_timer(5.0).timeout
		_think()
		return

	choose_next_destination(available)


func choose_next_destination(options: Array) -> void:
	# Filter to preferred options first, then anything available
	var preferred := []
	var others := []
	for option in options:
		if option is SkiSlope:
			if int(option.difficulty) == preferred_difficulty:
				preferred.append(option)
			else:
				others.append(option)
		elif option is SkiLift:
			preferred.append(option)

	var chosen = null
	if preferred.size() > 0:
		chosen = preferred[randi() % preferred.size()]
	elif others.size() > 0:
		chosen = others[randi() % others.size()]
	else:
		return

	if chosen is SkiSlope:
		_ski_slope(chosen)
	elif chosen is SkiLift:
		_ride_lift(chosen)


func _ski_slope(slope: SkiSlope) -> void:
	if slope == null or not slope.is_open:
		await get_tree().create_timer(2.0).timeout
		_think()
		return

	state = State.SKIING_DOWN
	current_hub.remove_skier(self)

	var descent_time := slope.get_descent_time(self)
	var target_pos: Vector3 = slope.arrival_hub.global_position + Vector3(
		randf_range(-3, 3), 1.0, randf_range(-3, 3)
	) if slope.arrival_hub else global_position

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", target_pos, descent_time)
	_tween.tween_callback(func():
		runs_completed += 1
		EconomyManager.add_revenue(EconomyManager.daily_pass_price / max_runs, "ski_passes", "Forfait skieur")
		GameManager.register_skier_served()
		if slope.arrival_hub != null:
			current_hub = slope.arrival_hub
			current_hub.add_skier(self)
		state = State.IN_HUB
		_think()
	)


func _ride_lift(lift: SkiLift) -> void:
	if lift == null or not lift.is_open:
		await get_tree().create_timer(2.0).timeout
		_think()
		return

	state = State.QUEUING_LIFT
	current_hub.remove_skier(self)
	lift.board_skier(self)


func on_lift_arrived(hub: Hub) -> void:
	state = State.IN_HUB
	current_hub = hub
	if hub != null:
		hub.add_skier(self)
	_think()


func _leave() -> void:
	state = State.LEAVING
	if current_hub:
		current_hub.remove_skier(self)
	# Walk toward village hub
	var target := NetworkGraph.village_hub.global_position + Vector3(
		randf_range(-10, 10), 1.0, randf_range(-10, 10)
	) if NetworkGraph.village_hub else global_position

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", target, 5.0)
	_tween.tween_callback(queue_free)
