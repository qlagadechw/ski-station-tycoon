extends Node

# SkierSpawner — spawns skiers at the village hub during snow season

const MAX_SKIERS := 500
const SPAWN_RATE_PEAK := 5.0      # skiers per minute in peak winter
const SPAWN_RATE_SHOULDER := 3.0  # skiers per minute in shoulder season

var _spawn_timer: float = 0.0
var _spawn_interval: float = 60.0 / SPAWN_RATE_PEAK
var _skier_scene: PackedScene = null
var _is_active: bool = false


func _ready() -> void:
	TimeManager.snow_started.connect(_on_snow_started)
	TimeManager.snow_ended.connect(_on_snow_ended)
	# If snow is already active when scene loads
	if TimeManager.is_snow_season:
		_is_active = true
		_update_spawn_interval()


func _process(delta: float) -> void:
	if not _is_active:
		return

	var skiers := get_tree().get_nodes_in_group("skiers")
	if skiers.size() >= MAX_SKIERS:
		return

	_spawn_timer += delta * TimeManager.time_scale
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_skier()


func _spawn_skier() -> void:
	if NetworkGraph.village_hub == null:
		return

	var skier_script := load("res://scenes/entities/skier.gd")
	if skier_script == null:
		return

	var skier = skier_script.new()
	get_tree().root.add_child(skier)
	skier.global_position = NetworkGraph.village_hub.global_position + Vector3(
		randf_range(-5.0, 5.0), 1.0, randf_range(-5.0, 5.0)
	)
	skier.current_hub = NetworkGraph.village_hub
	skier.add_to_group("skiers")
	NetworkGraph.village_hub.add_skier(skier)


func _update_spawn_interval() -> void:
	var month := TimeManager.current_month
	var rate: float
	# Peak winter: December, January, February
	if month == 12 or month == 1 or month == 2:
		rate = SPAWN_RATE_PEAK
	else:
		rate = SPAWN_RATE_SHOULDER
	_spawn_interval = _interval_for_rate(rate)


func _interval_for_rate(rate: float) -> float:
	return 60.0 / (rate * max(TimeManager.time_scale, 1.0))


func _on_snow_started() -> void:
	_is_active = true
	_update_spawn_interval()


func _on_snow_ended() -> void:
	_is_active = false
