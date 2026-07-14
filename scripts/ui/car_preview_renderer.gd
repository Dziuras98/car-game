extends SubViewport
class_name CarPreviewRenderer

const DEFAULT_VIEWPORT_SIZE: Vector2i = Vector2i(960, 540)
const FALLBACK_BOUNDS: AABB = AABB(Vector3(-1.0, -0.45, -2.2), Vector3(2.0, 1.45, 4.4))
const MIN_MODEL_SIZE: float = 0.05

var _turntable: Node3D
var _camera: Camera3D
var _floor: MeshInstance3D
var _model_root: Node3D
var _animate_rotation: bool = false
var _rotation_speed: float = 0.22


func _init() -> void:
	own_world_3d = true
	transparent_bg = true
	size = DEFAULT_VIEWPORT_SIZE
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	msaa_3d = Viewport.MSAA_4X
	set_process(false)


func _ready() -> void:
	_ensure_preview_world()


func _process(delta: float) -> void:
	if _animate_rotation and is_instance_valid(_turntable):
		_turntable.rotate_y(delta * _rotation_speed)


func show_car(car_scene: PackedScene, specs: CarSpecs = null, animate_rotation: bool = false) -> bool:
	clear_car()
	_ensure_preview_world()
	_animate_rotation = animate_rotation
	set_process(animate_rotation)
	if car_scene == null or not car_scene.can_instantiate():
		return false

	var scene_root: Node = car_scene.instantiate()
	if scene_root == null:
		return false
	var preview_root: Node3D = _extract_preview_root(scene_root, specs)
	if preview_root == null:
		if is_instance_valid(scene_root):
			scene_root.free()
		return false

	_prepare_preview_tree(preview_root)
	_turntable.add_child(preview_root)
	_model_root = preview_root
	var model_bounds: AABB = _calculate_visible_bounds(preview_root)
	if model_bounds.size.length() <= MIN_MODEL_SIZE:
		model_bounds = FALLBACK_BOUNDS
	_fit_model_to_view(model_bounds)
	render_target_update_mode = SubViewport.UPDATE_ALWAYS if animate_rotation else SubViewport.UPDATE_ONCE
	return true


func clear_car() -> void:
	_animate_rotation = false
	set_process(false)
	if is_instance_valid(_model_root):
		_model_root.queue_free()
	_model_root = null
	if is_instance_valid(_turntable):
		_turntable.rotation = Vector3.ZERO
	if is_instance_valid(_floor):
		_floor.visible = false


func capture_image() -> Image:
	var viewport_texture: ViewportTexture = get_texture()
	if viewport_texture == null:
		return null
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		return null
	return image


func _ensure_preview_world() -> void:
	if is_instance_valid(_turntable):
		return

	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.045, 0.06, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.74, 0.78, 0.86, 1.0)
	environment.ambient_light_energy = 1.3
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	key_light.light_energy = 2.25
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.rotation_degrees = Vector3(-28.0, 142.0, 0.0)
	fill_light.light_energy = 1.05
	fill_light.shadow_enabled = false
	add_child(fill_light)

	_turntable = Node3D.new()
	_turntable.name = "Turntable"
	add_child(_turntable)

	_floor = MeshInstance3D.new()
	_floor.name = "Floor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(14.0, 14.0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.12, 0.135, 0.16, 1.0)
	floor_material.roughness = 0.9
	floor_material.metallic = 0.0
	plane.material = floor_material
	_floor.mesh = plane
	_floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_floor.visible = false
	add_child(_floor)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.current = true
	_camera.fov = 34.0
	_camera.near = 0.05
	_camera.far = 250.0
	add_child(_camera)


func _extract_preview_root(scene_root: Node, specs: CarSpecs) -> Node3D:
	if scene_root is PlayerCarController and specs != null:
		(scene_root as PlayerCarController).car_specs = specs
	if not scene_root is Node3D:
		return null

	var root_3d: Node3D = scene_root as Node3D
	var visual_root: Node3D = scene_root.get_node_or_null(^"VisualRoot") as Node3D
	if visual_root == null:
		root_3d.set_script(null)
		return root_3d

	var combined_transform: Transform3D = root_3d.transform * visual_root.transform
	root_3d.remove_child(visual_root)
	visual_root.transform = combined_transform
	root_3d.free()
	return visual_root


func _prepare_preview_tree(preview_root: Node3D) -> void:
	if preview_root.has_method(&"prepare_for_preview"):
		preview_root.call(&"prepare_for_preview")
	if preview_root is CarVisualController:
		var visual_controller: CarVisualController = preview_root as CarVisualController
		var detailed_root: Node3D = preview_root.get_node_or_null(visual_controller.detailed_root_path) as Node3D
		var low_detail_root: Node3D = preview_root.get_node_or_null(visual_controller.low_detail_root_path) as Node3D
		if detailed_root != null:
			detailed_root.visible = true
		if low_detail_root != null:
			low_detail_root.visible = false
		preview_root.set_script(null)
	_disable_runtime_nodes(preview_root)


func _disable_runtime_nodes(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CollisionObject3D:
		var collision_object: CollisionObject3D = node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	if node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).stream = null
	for child: Node in node.get_children():
		_disable_runtime_nodes(child)


func _calculate_visible_bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds: bool = false
	var root_inverse: Transform3D = root.global_transform.affine_inverse()
	for descendant: Node in root.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = descendant as VisualInstance3D
		if visual == null or not visual.is_visible_in_tree():
			continue
		var local_transform: Transform3D = root_inverse * visual.global_transform
		var visual_bounds: AABB = local_transform * visual.get_aabb()
		if visual_bounds.size.length() <= MIN_MODEL_SIZE:
			continue
		if not has_bounds:
			bounds = visual_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(visual_bounds)
	return bounds if has_bounds else FALLBACK_BOUNDS


func _fit_model_to_view(bounds: AABB) -> void:
	var center: Vector3 = bounds.get_center()
	_model_root.position -= center
	var width: float = maxf(bounds.size.x, 0.5)
	var height: float = maxf(bounds.size.y, 0.5)
	var length: float = maxf(bounds.size.z, 0.5)
	var horizontal_span: float = maxf(width, length)
	var distance: float = maxf(maxf(horizontal_span * 1.35, height * 2.4), 3.0)
	var target := Vector3(0.0, height * 0.04, 0.0)
	_camera.position = Vector3(distance * 0.72, maxf(height * 0.62, 1.0), -distance)
	_camera.look_at(target, Vector3.UP)
	_turntable.rotation.y = deg_to_rad(16.0)
	_floor.position = Vector3(0.0, bounds.position.y - center.y - 0.035, 0.0)
	_floor.visible = true
