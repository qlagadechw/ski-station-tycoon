extends Node3D

## CameraController — RTS-style camera for the game world.

const MOVE_SPEED := 50.0
const ZOOM_MIN := 20.0
const ZOOM_MAX := 300.0
const TERRAIN_MIN := 0.0
const TERRAIN_MAX := 2048.0

@export var initial_zoom: float = 100.0
@export var initial_tilt_deg: float = -45.0

var _pivot: Node3D
var _camera: Camera3D
var _zoom: float = 100.0
var _is_rotating: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.position = Vector3(0, 0, initial_zoom)
	_camera.current = true
	_pivot.add_child(_camera)

	_pivot.rotation_degrees.x = initial_tilt_deg
	_zoom = initial_zoom


func _input(event: InputEvent) -> void:
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom = clampf(_zoom - 10.0, ZOOM_MIN, ZOOM_MAX)
				_camera.position.z = _zoom
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom = clampf(_zoom + 10.0, ZOOM_MIN, ZOOM_MAX)
				_camera.position.z = _zoom
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				_is_rotating = true
				_last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_rotating = false

	# Rotation and tilt with middle mouse drag
	if event is InputEventMouseMotion and _is_rotating:
		var delta := event.position - _last_mouse_pos
		_last_mouse_pos = event.position
		# Horizontal drag: Y rotation
		rotation_degrees.y -= delta.x * 0.3
		# Vertical drag: pivot X rotation (tilt)
		_pivot.rotation_degrees.x = clampf(
			_pivot.rotation_degrees.x - delta.y * 0.2,
			-80.0, -20.0
		)


func _process(delta: float) -> void:
	var move := Vector3.ZERO

	# Movement relative to camera Y rotation
	if Input.is_action_pressed("camera_forward"):
		move.z -= 1.0
	if Input.is_action_pressed("camera_back"):
		move.z += 1.0
	if Input.is_action_pressed("camera_left"):
		move.x -= 1.0
	if Input.is_action_pressed("camera_right"):
		move.x += 1.0

	if move.length_squared() > 0.0:
		move = move.normalized()
		# Rotate direction by camera Y rotation
		var y_rotation := Transform3D().rotated(Vector3.UP, rotation.y)
		move = y_rotation.basis * move
		position += move * MOVE_SPEED * delta

	# Clamp to terrain bounds
	position.x = clampf(position.x, TERRAIN_MIN, TERRAIN_MAX)
	position.z = clampf(position.z, TERRAIN_MIN, TERRAIN_MAX)
	# Keep camera from going below terrain
	position.y = maxf(position.y, 0.0)


func get_camera() -> Camera3D:
	return _camera
