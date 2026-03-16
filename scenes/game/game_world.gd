extends Node3D

## GameWorld — main game scene, initializes all systems and nodes.


func _ready() -> void:
	_setup_lighting()
	_setup_environment()
	_setup_terrain()
	_setup_village()
	_setup_camera()
	_setup_hud()
	_setup_spawner()
	_start_game()


func _setup_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)


func _setup_environment() -> void:
	var env := Environment.new()

	# Sky
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.2, 0.4, 0.8)
	sky_mat.sky_horizon_color = Color(0.7, 0.85, 1.0)
	sky_mat.ground_bottom_color = Color(0.3, 0.5, 0.3)
	sky_mat.ground_horizon_color = Color(0.6, 0.7, 0.5)
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY

	# Ambient
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5

	# Fog
	env.fog_enabled = true
	env.fog_density = 0.0005
	env.fog_light_color = Color(0.8, 0.9, 1.0)

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)


func _setup_terrain() -> void:
	var terrain_script := load("res://scenes/terrain/terrain_generator.gd")
	if terrain_script == null:
		push_error("GameWorld: cannot load terrain_generator.gd")
		return
	var terrain = terrain_script.new()
	terrain.name = "TerrainGenerator"
	add_child(terrain)


func _setup_village() -> void:
	var village_script := load("res://scenes/terrain/village.gd")
	if village_script == null:
		push_error("GameWorld: cannot load village.gd")
		return
	var village = village_script.new()
	village.name = "Village"
	add_child(village)


func _setup_camera() -> void:
	var cam_script := load("res://scenes/game/camera_controller.gd")
	if cam_script == null:
		push_error("GameWorld: cannot load camera_controller.gd")
		return
	var cam = cam_script.new()
	cam.name = "CameraController"
	# Start camera above the village
	cam.position = Vector3(1024, 600, 1024)
	add_child(cam)
	# Give BuildManager a reference to the camera
	await get_tree().process_frame
	BuildManager.set_camera(cam.get_camera())
	BuildManager.set_game_world(self)


func _setup_hud() -> void:
	var hud_scene := load("res://scenes/game/hud/hud.tscn")
	if hud_scene == null:
		push_error("GameWorld: cannot load hud.tscn")
		return
	var hud = hud_scene.instantiate()
	hud.name = "HUD"
	add_child(hud)


func _setup_spawner() -> void:
	var spawner_script := load("res://scripts/systems/skier_spawner.gd")
	if spawner_script == null:
		push_error("GameWorld: cannot load skier_spawner.gd")
		return
	var spawner = spawner_script.new()
	spawner.name = "SkierSpawner"
	add_child(spawner)


func _start_game() -> void:
	GameManager.start_game()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if TimeManager.current_speed == TimeManager.SpeedMode.PAUSED:
			TimeManager.set_speed(TimeManager.SpeedMode.NORMAL)
		else:
			TimeManager.set_speed(TimeManager.SpeedMode.PAUSED)
	elif event.is_action_pressed("speed_1"):
		TimeManager.set_speed(TimeManager.SpeedMode.NORMAL)
	elif event.is_action_pressed("speed_2"):
		TimeManager.set_speed(TimeManager.SpeedMode.FAST)
	elif event.is_action_pressed("speed_3"):
		TimeManager.set_speed(TimeManager.SpeedMode.ULTRA)
