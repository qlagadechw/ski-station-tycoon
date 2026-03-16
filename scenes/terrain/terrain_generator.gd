extends Node3D

## TerrainGenerator — Procedural "Massif du Jura" terrain.
## Generates a 2048×2048 m terrain mesh with realistic mountain topology.

const TERRAIN_SIZE := 2048
const TERRAIN_RESOLUTION := 256  # grid vertices per side (256×256 = ~65k verts)
const MAX_HEIGHT := 1800.0
const MIN_HEIGHT := 300.0
const TERRAIN_COLLISION_LAYER := 1  # Physics layer 1 = terrain (defined in project.godot)

# Summit definitions: [x_grid, z_grid, height_m]
const SUMMITS := [
	[100, 100, 1720.0],   # Mont A — northwest
	[400,  75, 1680.0],   # Mont B — northeast
	[ 50, 250, 1550.0],   # Mont C — west
	[250, 425,  1450.0],  # Mont D — south
	[425, 350, 1400.0],   # Mont E — southeast
]

# Main valley center (world coords): U-shape, east-west at z ≈ 1024
const VALLEY_CENTER_Z := 1024.0
const VALLEY_WIDTH := 180.0
const VALLEY_FLOOR_HEIGHT := 480.0

var heightmap: PackedFloat32Array
var _mesh_instance: MeshInstance3D
var _static_body: StaticBody3D
var _collision_shape: CollisionShape3D
var _material: ShaderMaterial

signal terrain_ready()


func _ready() -> void:
	_generate()
	emit_signal("terrain_ready")


func _generate() -> void:
	var res := TERRAIN_RESOLUTION
	heightmap = PackedFloat32Array()
	heightmap.resize(res * res)

	# --- Base noise ---
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = 42
	noise.fractal_octaves = 6
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	noise.frequency = 0.003

	# --- Fill base heightmap ---
	for z in range(res):
		for x in range(res):
			var n: float = (noise.get_noise_2d(float(x), float(z)) + 1.0) * 0.5  # 0..1
			# Base terrain in range [400, 1200]
			var h: float = lerp(400.0, 1200.0, n)
			heightmap[z * res + x] = h

	# --- Carve main U-shaped valley ---
	var valley_z_norm := VALLEY_CENTER_Z / TERRAIN_SIZE * res
	for z in range(res):
		for x in range(res):
			var z_world: float = float(z) / res * TERRAIN_SIZE
			var dist_to_valley: float = abs(z_world - VALLEY_CENTER_Z)
			if dist_to_valley < VALLEY_WIDTH * 2.5:
				var t := clampf(1.0 - dist_to_valley / (VALLEY_WIDTH * 2.5), 0.0, 1.0)
				t = t * t  # smooth
				var idx := z * res + x
				heightmap[idx] = lerp(heightmap[idx], VALLEY_FLOOR_HEIGHT, t)

	# --- Carve secondary valley (northeast-southwest diagonal) ---
	for z in range(res):
		for x in range(res):
			var xw := float(x) / res * TERRAIN_SIZE
			var zw := float(z) / res * TERRAIN_SIZE
			# Valley diagonal from (200, 400) to (900, 1100)
			var valley_dist := _dist_to_line(
				Vector2(xw, zw),
				Vector2(200.0, 400.0),
				Vector2(900.0, 1100.0)
			)
			if valley_dist < 120.0:
				var t := clampf(1.0 - valley_dist / 120.0, 0.0, 1.0)
				t = t * t
				var idx := z * res + x
				heightmap[idx] = lerp(heightmap[idx], 750.0, t * 0.5)

	# --- Add summit gaussian bumps ---
	for summit in SUMMITS:
		var sx: float = float(summit[0])
		var sz: float = float(summit[1])
		var sh: float = float(summit[2])
		var sigma := 60.0  # grid units
		for z in range(res):
			for x in range(res):
				var dx := float(x) - sx
				var dz := float(z) - sz
				var g := exp(-(dx * dx + dz * dz) / (2.0 * sigma * sigma))
				var idx := z * res + x
				heightmap[idx] = max(heightmap[idx], lerp(heightmap[idx], sh, g * 0.9))

	# --- Add col passes between summits ---
	_add_col(SUMMITS[0], SUMMITS[1], 1150.0, res)  # A-B
	_add_col(SUMMITS[0], SUMMITS[2], 1100.0, res)  # A-C
	_add_col(SUMMITS[1], SUMMITS[4], 1200.0, res)  # B-E
	_add_col(SUMMITS[2], SUMMITS[3], 1100.0, res)  # C-D
	_add_col(SUMMITS[3], SUMMITS[4], 1250.0, res)  # D-E

	# --- Clamp heights ---
	for i in range(heightmap.size()):
		heightmap[i] = clampf(heightmap[i], MIN_HEIGHT, MAX_HEIGHT)

	# --- Build mesh ---
	_build_mesh(res)
	_build_collision(res)
	_apply_shader()
	_place_vegetation(res)


func _add_col(s1: Array, s2: Array, col_height: float, res: int) -> void:
	var mx: float = (float(s1[0]) + float(s2[0])) / 2.0
	var mz: float = (float(s1[1]) + float(s2[1])) / 2.0
	var sigma := 30.0
	for z in range(res):
		for x in range(res):
			var dx: float = float(x) - mx
			var dz: float = float(z) - mz
			var g := exp(-(dx * dx + dz * dz) / (2.0 * sigma * sigma))
			var idx := z * res + x
			if g > 0.05:
				var current := heightmap[idx]
				heightmap[idx] = lerp(current, col_height, g * 0.7)


func _dist_to_line(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return (ap - ab * t).length()


func _build_mesh(res: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_size := float(TERRAIN_SIZE) / float(res - 1)

	for z in range(res - 1):
		for x in range(res - 1):
			var h00 := heightmap[z * res + x]
			var h10 := heightmap[z * res + (x + 1)]
			var h01 := heightmap[(z + 1) * res + x]
			var h11 := heightmap[(z + 1) * res + (x + 1)]

			var v00 := Vector3(x * cell_size, h00, z * cell_size)
			var v10 := Vector3((x + 1) * cell_size, h10, z * cell_size)
			var v01 := Vector3(x * cell_size, h01, (z + 1) * cell_size)
			var v11 := Vector3((x + 1) * cell_size, h11, (z + 1) * cell_size)

			var uv00 := Vector2(float(x) / res, float(z) / res)
			var uv10 := Vector2(float(x + 1) / res, float(z) / res)
			var uv01 := Vector2(float(x) / res, float(z + 1) / res)
			var uv11 := Vector2(float(x + 1) / res, float(z + 1) / res)

			# Triangle 1
			var n1 := (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n1)
			st.set_uv(uv00); st.add_vertex(v00)
			st.set_uv(uv10); st.add_vertex(v10)
			st.set_uv(uv01); st.add_vertex(v01)

			# Triangle 2
			var n2 := (v01 - v10).cross(v11 - v10).normalized()
			st.set_normal(n2)
			st.set_uv(uv10); st.add_vertex(v10)
			st.set_uv(uv11); st.add_vertex(v11)
			st.set_uv(uv01); st.add_vertex(v01)

	var arr_mesh := st.commit()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = arr_mesh
	_mesh_instance.name = "TerrainMesh"
	add_child(_mesh_instance)


func _build_collision(res: int) -> void:
	_static_body = StaticBody3D.new()
	_static_body.name = "TerrainCollision"
	_static_body.collision_layer = TERRAIN_COLLISION_LAYER
	_static_body.collision_mask = 0

	_collision_shape = CollisionShape3D.new()
	var hmap_shape := HeightMapShape3D.new()
	hmap_shape.map_width = res
	hmap_shape.map_depth = res
	hmap_shape.map_data = heightmap

	_collision_shape.shape = hmap_shape
	_static_body.add_child(_collision_shape)

	# HeightMapShape3D is centered; offset to align with mesh
	var half := float(TERRAIN_SIZE) * 0.5
	var cell_size := float(TERRAIN_SIZE) / float(res - 1)
	_static_body.position = Vector3(half, 0.0, half)
	_collision_shape.scale = Vector3(cell_size, 1.0, cell_size)

	add_child(_static_body)


func _apply_shader() -> void:
	var shader_code := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float snow_coverage : hint_range(0.0, 1.0) = 0.0;
uniform float terrain_max_height : hint_range(500.0, 2000.0) = 1800.0;
uniform float terrain_min_height : hint_range(0.0, 1000.0) = 300.0;

void fragment() {
	float world_y = (VERTEX.y - terrain_min_height) / (terrain_max_height - terrain_min_height);
	world_y = clamp(world_y, 0.0, 1.0);
	float altitude = mix(terrain_min_height, terrain_max_height, world_y);

	vec3 grass_low   = vec3(0.3, 0.6, 0.2);
	vec3 forest_dark = vec3(0.15, 0.3, 0.1);
	vec3 alpine_grass= vec3(0.5, 0.6, 0.3);
	vec3 rock_grey   = vec3(0.5, 0.5, 0.45);
	vec3 snow_white  = vec3(0.95, 0.97, 1.0);

	vec3 base_color;
	if (altitude < 600.0) {
		base_color = grass_low;
	} else if (altitude < 1400.0) {
		float t = (altitude - 600.0) / 800.0;
		base_color = mix(grass_low, forest_dark, clamp(t * 2.0, 0.0, 1.0));
		if (t > 0.5) base_color = mix(forest_dark, alpine_grass, (t - 0.5) * 2.0);
	} else if (altitude < 1600.0) {
		float t = (altitude - 1400.0) / 200.0;
		base_color = mix(alpine_grass, rock_grey, t);
	} else {
		base_color = rock_grey;
	}

	// Snow overlay — starts at high altitudes first
	float snow_threshold = mix(0.9, 0.0, snow_coverage);
	float snow_factor = clamp((world_y - snow_threshold) / 0.15, 0.0, 1.0);
	snow_factor *= snow_coverage;

	ALBEDO = mix(base_color, snow_white, snow_factor);
	ROUGHNESS = mix(0.9, 0.3, snow_factor);
	SPECULAR = mix(0.0, 0.5, snow_factor);
}
"""

	var shader := Shader.new()
	shader.code = shader_code

	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("snow_coverage", 0.0)
	_material.set_shader_parameter("terrain_max_height", float(MAX_HEIGHT))
	_material.set_shader_parameter("terrain_min_height", float(MIN_HEIGHT))

	if _mesh_instance:
		_mesh_instance.material_override = _material

	# Connect to TimeManager for snow updates
	if TimeManager != null:
		TimeManager.day_changed.connect(_on_day_changed)


func _on_day_changed(_d: int, _m: int, _y: int) -> void:
	if _material:
		_material.set_shader_parameter("snow_coverage", TimeManager.snow_coverage)


func _place_vegetation(res: int) -> void:
	var tree_count := 4000
	var positions := PackedVector3Array()
	var rotations := PackedFloat32Array()
	var scales := PackedFloat32Array()

	var cell_size := float(TERRAIN_SIZE) / float(res - 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 123

	var village_center := Vector2(1024.0, 1024.0)
	var village_exclusion_radius := 150.0

	for _i in range(tree_count * 10):  # over-sample, accept if valid
		if positions.size() >= tree_count:
			break
		var wx := rng.randf_range(0.0, float(TERRAIN_SIZE))
		var wz := rng.randf_range(0.0, float(TERRAIN_SIZE))

		# Get height at this position
		var gx := int(wx / cell_size)
		var gz := int(wz / cell_size)
		gx = clampi(gx, 0, res - 1)
		gz = clampi(gz, 0, res - 1)
		var h := heightmap[gz * res + gx]

		if h < 600.0 or h > 1400.0:
			continue

		# Skip village area
		var dist_village := Vector2(wx, wz).distance_to(village_center)
		if dist_village < village_exclusion_radius:
			continue

		# Density decreases with altitude
		var density := clampf(1.0 - (h - 600.0) / 800.0, 0.1, 1.0)
		if rng.randf() > density:
			continue

		positions.append(Vector3(wx, h, wz))
		rotations.append(rng.randf() * TAU)
		scales.append(rng.randf_range(0.7, 1.5))

	if positions.size() == 0:
		return

	# Create tree MultiMesh
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = positions.size()
	multi_mesh.mesh = _create_tree_mesh()

	for i in range(positions.size()):
		var xform := Transform3D()
		xform.origin = positions[i]
		xform = xform.rotated(Vector3.UP, rotations[i])
		xform = xform.scaled(Vector3.ONE * scales[i])
		multi_mesh.set_instance_transform(i, xform)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = multi_mesh
	mmi.name = "Vegetation"
	add_child(mmi)


func _create_tree_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Trunk: brown cylinder (approximated as thin box)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.25, 0.1)
	st.set_material(trunk_mat)

	var tw := 0.15
	var th := 1.5
	# Simple quad trunk
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(-tw, 0, 0)); st.add_vertex(Vector3(tw, 0, 0)); st.add_vertex(Vector3(-tw, th, 0))
	st.add_vertex(Vector3(tw, 0, 0)); st.add_vertex(Vector3(tw, th, 0)); st.add_vertex(Vector3(-tw, th, 0))

	st.set_normal(Vector3(0, 0, -1))
	st.add_vertex(Vector3(tw, 0, 0)); st.add_vertex(Vector3(-tw, 0, 0)); st.add_vertex(Vector3(tw, th, 0))
	st.add_vertex(Vector3(-tw, 0, 0)); st.add_vertex(Vector3(-tw, th, 0)); st.add_vertex(Vector3(tw, th, 0))

	# Cone (foliage): green tapered cylinder
	var foliage_mat := StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.1, 0.45, 0.1)
	st.set_material(foliage_mat)

	var segments := 6
	var cone_radius := 1.0
	var cone_height := 4.0
	var base_y := th

	for i in range(segments):
		var angle_a := TAU * float(i) / segments
		var angle_b := TAU * float(i + 1) / segments
		var ax := cos(angle_a) * cone_radius
		var az := sin(angle_a) * cone_radius
		var bx := cos(angle_b) * cone_radius
		var bz := sin(angle_b) * cone_radius

		var va := Vector3(ax, base_y, az)
		var vb := Vector3(bx, base_y, bz)
		var vtop := Vector3(0, base_y + cone_height, 0)

		var n := (vb - va).cross(vtop - va).normalized()
		st.set_normal(n)
		st.add_vertex(va); st.add_vertex(vb); st.add_vertex(vtop)

	return st.commit()


func get_height_at(world_x: float, world_z: float) -> float:
	var res := TERRAIN_RESOLUTION
	var cell_size := float(TERRAIN_SIZE) / float(res - 1)
	var gx := int(world_x / cell_size)
	var gz := int(world_z / cell_size)
	gx = clampi(gx, 0, res - 1)
	gz = clampi(gz, 0, res - 1)
	return heightmap[gz * res + gx]
