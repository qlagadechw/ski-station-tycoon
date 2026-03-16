extends Node3D

## Village — procedural village placed in the main valley.

const VILLAGE_WORLD_X := 1024.0
const VILLAGE_WORLD_Z := 1024.0
const VILLAGE_FLOOR_HEIGHT := 482.0  # Slightly above valley floor


func _ready() -> void:
	_build_village()


func _build_village() -> void:
	position = Vector3(VILLAGE_WORLD_X, VILLAGE_FLOOR_HEIGHT, VILLAGE_WORLD_Z)

	_add_road()
	_add_church()
	_add_town_hall()
	_add_houses()
	_add_shop()
	_add_spawn_point()
	_add_default_hub()


func _make_csg_box(size: Vector3, pos: Vector3, color: Color) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.size = size
	box.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	box.material = mat
	return box


func _add_road() -> void:
	# Main road strip: east-west
	var road := _make_csg_box(
		Vector3(200.0, 0.3, 10.0),
		Vector3(0, 0.15, 0),
		Color(0.2, 0.2, 0.2)
	)
	road.name = "MainRoad"
	add_child(road)

	# Cross road: north-south
	var road2 := _make_csg_box(
		Vector3(10.0, 0.3, 150.0),
		Vector3(0, 0.15, 0),
		Color(0.2, 0.2, 0.2)
	)
	road2.name = "CrossRoad"
	add_child(road2)


func _add_church() -> void:
	# Church body
	var body := _make_csg_box(
		Vector3(8.0, 6.0, 12.0),
		Vector3(-30.0, 3.0, -25.0),
		Color(0.85, 0.82, 0.78)
	)
	body.name = "ChurchBody"
	add_child(body)

	# Church steeple
	var steeple := _make_csg_box(
		Vector3(3.0, 12.0, 3.0),
		Vector3(-30.0, 12.0, -22.0),
		Color(0.5, 0.3, 0.2)
	)
	steeple.name = "ChurchSteeple"
	add_child(steeple)


func _add_town_hall() -> void:
	var hall := _make_csg_box(
		Vector3(20.0, 7.0, 14.0),
		Vector3(25.0, 3.5, -20.0),
		Color(0.78, 0.72, 0.65)
	)
	hall.name = "TownHall"
	add_child(hall)


func _add_houses() -> void:
	var house_positions := [
		Vector3(-20.0, 0.0, 25.0),
		Vector3(10.0, 0.0, 30.0),
		Vector3(35.0, 0.0, 22.0),
		Vector3(-35.0, 0.0, 15.0),
		Vector3(50.0, 0.0, -10.0),
	]
	var house_colors := [
		Color(0.9, 0.85, 0.78),
		Color(0.85, 0.78, 0.72),
		Color(0.82, 0.88, 0.80),
		Color(0.88, 0.82, 0.75),
		Color(0.80, 0.85, 0.88),
	]
	for i in range(house_positions.size()):
		var house := _make_csg_box(
			Vector3(7.0, 5.0, 9.0),
			house_positions[i] + Vector3(0, 2.5, 0),
			house_colors[i]
		)
		house.name = "House%d" % (i + 1)
		add_child(house)
		# Roof (triangular approximation using box)
		var roof := _make_csg_box(
			Vector3(8.0, 2.0, 10.0),
			house_positions[i] + Vector3(0, 6.0, 0),
			Color(0.55, 0.25, 0.15)
		)
		roof.name = "HouseRoof%d" % (i + 1)
		add_child(roof)


func _add_shop() -> void:
	var shop := _make_csg_box(
		Vector3(12.0, 5.0, 10.0),
		Vector3(55.0, 2.5, 25.0),
		Color(0.3, 0.6, 0.8)
	)
	shop.name = "Shop"
	add_child(shop)

	var sign := _make_csg_box(
		Vector3(8.0, 1.0, 0.2),
		Vector3(55.0, 6.0, 20.1),
		Color(1.0, 0.9, 0.1)
	)
	sign.name = "ShopSign"
	add_child(sign)


func _add_spawn_point() -> void:
	var spawn := Marker3D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector3(0, 1.0, 0)
	add_child(spawn)


func _add_default_hub() -> void:
	var hub_script := load("res://scenes/infrastructure/hub.gd")
	if hub_script == null:
		push_error("Village: cannot load hub.gd")
		return

	var hub = hub_script.new()
	hub.name = "VillageHub"
	hub.hub_type = 0  # Hub.Type.VILLAGE_SPAWN
	hub.hub_name = "Village"
	hub.radius = 40.0
	hub.capacity = 100
	hub.position = Vector3(0, 1.0, 0)
	add_child(hub)
