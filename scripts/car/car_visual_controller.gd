extends Node3D
class_name CarVisualController


const VISIBILITY_NOTIFIER_NAME: StringName = &"VisibilityNotifier"

@export var detailed_root_path: NodePath = ^"SketchfabModel"
@export var low_detail_root_path: NodePath = ^"LowDetail"
@export var visibility_aabb: AABB = AABB(
	Vector3(-1.1, -0.15, -2.3),
	Vector3(2.2, 1.65, 4.6)
)
@export_range(0.1, 1.0, 0.01) var visual_wheel_radius: float = 0.34
@export var force_low_detail: bool = false

var _detailed_root: Node3D
var _low_detail_root: Node3D
var _visibility_notifier: VisibleOnScreenNotifier3D
var _wheel_nodes: Array[Node3D] = []
var _wheel_base_rotations: Array[Vector3] = []
var _front_wheel_flags: Array[bool] = []
var _wheel_spin: float = 0.0
var _using_low_detail: bool = false


func _ready() -> void:
	_resolve_visual_roots()
	_ensure_wheels_collected()
	_ensure_visibility_notifier()
	_set_low_detail_active(true)


func set_force_low_detail(enabled: bool) -> void:
	force_low_detail = enabled
	_resolve_visual_roots()
	if enabled:
		_set_low_detail_active(true)
		return
	if is_instance_valid(_visibility_notifier) and _visibility_notifier.is_on_screen():
		_set_low_detail_active(false)
	else:
		_set_low_detail_active(true)


func is_using_low_detail() -> bool:
	return _using_low_detail


func get_visibility_notifier() -> VisibleOnScreenNotifier3D:
	_ensure_visibility_notifier()
	return _visibility_notifier


func get_registered_wheel_count() -> int:
	_ensure_wheels_collected()
	return _wheel_nodes.size()


func update_vehicle_visuals(
	delta: float,
	forward_speed: float,
	steering_input: float,
	wheel_radius_override: float = -1.0
) -> void:
	_ensure_wheels_collected()
	var safe_delta: float = maxf(delta, 0.0)
	var radius: float = wheel_radius_override if wheel_radius_override > 0.0 else visual_wheel_radius
	_wheel_spin = fposmod(_wheel_spin + forward_speed / maxf(radius, 0.01) * safe_delta, TAU)
	var steering_angle: float = deg_to_rad(24.0) * clampf(steering_input, -1.0, 1.0)
	for index: int in range(_wheel_nodes.size()):
		var wheel: Node3D = _wheel_nodes[index]
		if not is_instance_valid(wheel) or not wheel.is_visible_in_tree():
			continue
		var rotation_value: Vector3 = _wheel_base_rotations[index]
		rotation_value.x += _wheel_spin
		if _front_wheel_flags[index]:
			rotation_value.y += steering_angle
		wheel.rotation = rotation_value


func _resolve_visual_roots() -> void:
	if _detailed_root == null:
		_detailed_root = get_node_or_null(detailed_root_path) as Node3D
	if _low_detail_root == null:
		_low_detail_root = get_node_or_null(low_detail_root_path) as Node3D


func _ensure_visibility_notifier() -> void:
	if is_instance_valid(_visibility_notifier):
		return
	var existing_node: Node = get_node_or_null(NodePath(str(VISIBILITY_NOTIFIER_NAME)))
	if existing_node != null:
		_visibility_notifier = existing_node as VisibleOnScreenNotifier3D
		if _visibility_notifier == null:
			push_error("CarVisualController VisibilityNotifier child must be VisibleOnScreenNotifier3D.")
			return
	else:
		_visibility_notifier = VisibleOnScreenNotifier3D.new()
		_visibility_notifier.name = VISIBILITY_NOTIFIER_NAME
		add_child(_visibility_notifier)
	_visibility_notifier.aabb = visibility_aabb
	var entered_callback: Callable = Callable(self, "_on_visibility_notifier_screen_entered")
	if not _visibility_notifier.screen_entered.is_connected(entered_callback):
		_visibility_notifier.screen_entered.connect(entered_callback)
	var exited_callback: Callable = Callable(self, "_on_visibility_notifier_screen_exited")
	if not _visibility_notifier.screen_exited.is_connected(exited_callback):
		_visibility_notifier.screen_exited.connect(exited_callback)


func _ensure_wheels_collected() -> void:
	if not _wheel_nodes.is_empty():
		return
	_collect_wheel_nodes(self)


func _set_low_detail_active(enabled: bool) -> void:
	_resolve_visual_roots()
	_using_low_detail = enabled and _low_detail_root != null
	if _detailed_root != null:
		_detailed_root.visible = not _using_low_detail
	if _low_detail_root != null:
		_low_detail_root.visible = _using_low_detail


func _collect_wheel_nodes(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Node3D:
			var child_3d: Node3D = child as Node3D
			var normalized_name: String = child_3d.name.to_lower()
			if (
				"wheel" in normalized_name
				or "tire" in normalized_name
				or "tyre" in normalized_name
				or "rim" in normalized_name
			):
				_register_wheel_node(child_3d, normalized_name)
		_collect_wheel_nodes(child)


func _register_wheel_node(wheel: Node3D, normalized_name: String) -> void:
	if _wheel_nodes.has(wheel):
		return
	_wheel_nodes.append(wheel)
	_wheel_base_rotations.append(wheel.rotation)
	var explicitly_front: bool = "front" in normalized_name or "fl" in normalized_name or "fr" in normalized_name
	_front_wheel_flags.append(explicitly_front or wheel.position.z < 0.0)


func _on_visibility_notifier_screen_entered() -> void:
	if force_low_detail:
		return
	_set_low_detail_active(false)


func _on_visibility_notifier_screen_exited() -> void:
	_set_low_detail_active(true)
