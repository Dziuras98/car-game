extends Node3D
class_name CarVisualController


class RuntimeWheelBinding:
	var wheel_id: StringName
	var steering_pivot: Node3D
	var spin_pivot: Node3D
	var steers: bool = false
	var steering_direction: float = 1.0
	var spin_direction: float = 1.0


const VISIBILITY_NOTIFIER_NAME: StringName = &"VisibilityNotifier"
const LOW_DETAIL_WHEEL_NAMES: Array[StringName] = [
	&"WheelFrontLeft",
	&"WheelFrontRight",
	&"WheelRearLeft",
	&"WheelRearRight",
]

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
var _detailed_wheel_bindings: Array[RuntimeWheelBinding] = []
var _detailed_wheel_bindings_by_id: Dictionary = {}
var _wheel_visuals_configured: bool = false
var _low_detail_wheel_nodes: Array[Node3D] = []
var _low_detail_base_rotations: Array[Vector3] = []
var _low_detail_front_flags: Array[bool] = []
var _wheel_spin: float = 0.0
var _using_low_detail: bool = false
var _is_screen_visible: bool = false


func _ready() -> void:
	_resolve_visual_roots()
	_configure_wheel_visuals()
	_ensure_visibility_notifier()
	_set_low_detail_active(true)


func set_force_low_detail(enabled: bool) -> void:
	force_low_detail = enabled
	_resolve_visual_roots()
	if enabled:
		_set_low_detail_active(true)
		return
	_is_screen_visible = is_instance_valid(_visibility_notifier) and _visibility_notifier.is_on_screen()
	_set_low_detail_active(not _is_screen_visible)


func is_using_low_detail() -> bool:
	return _using_low_detail


func is_screen_visible() -> bool:
	return _is_screen_visible


func get_visibility_notifier() -> VisibleOnScreenNotifier3D:
	_ensure_visibility_notifier()
	return _visibility_notifier


func get_registered_wheel_count() -> int:
	_configure_wheel_visuals()
	return maxi(_detailed_wheel_bindings.size(), _low_detail_wheel_nodes.size())


func get_detailed_wheel_binding_count() -> int:
	_configure_wheel_visuals()
	return _detailed_wheel_bindings.size()


func get_low_detail_wheel_binding_count() -> int:
	_configure_wheel_visuals()
	return _low_detail_wheel_nodes.size()


func get_detailed_wheel_steering_pivot(wheel_id: StringName) -> Node3D:
	_configure_wheel_visuals()
	var binding: RuntimeWheelBinding = _detailed_wheel_bindings_by_id.get(wheel_id) as RuntimeWheelBinding
	return binding.steering_pivot if binding != null else null


func get_detailed_wheel_spin_pivot(wheel_id: StringName) -> Node3D:
	_configure_wheel_visuals()
	var binding: RuntimeWheelBinding = _detailed_wheel_bindings_by_id.get(wheel_id) as RuntimeWheelBinding
	return binding.spin_pivot if binding != null else null


func update_vehicle_visuals(
	delta: float,
	forward_speed: float,
	steering_input: float,
	wheel_radius_override: float = -1.0
) -> void:
	_configure_wheel_visuals()
	var safe_delta: float = maxf(delta, 0.0)
	var radius: float = wheel_radius_override if wheel_radius_override > 0.0 else visual_wheel_radius
	_wheel_spin = fposmod(_wheel_spin + forward_speed / maxf(radius, 0.01) * safe_delta, TAU)
	if not _is_screen_visible:
		return
	var steering_angle: float = deg_to_rad(24.0) * clampf(steering_input, -1.0, 1.0)
	if _using_low_detail:
		_apply_low_detail_wheels(steering_angle)
	elif not _detailed_wheel_bindings.is_empty():
		_apply_runtime_wheel_bindings(_detailed_wheel_bindings, steering_angle)


func _get_explicit_detailed_wheel_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	return specs


func _resolve_visual_roots() -> void:
	if _detailed_root == null:
		_detailed_root = get_node_or_null(detailed_root_path) as Node3D
	if _low_detail_root == null:
		_low_detail_root = get_node_or_null(low_detail_root_path) as Node3D


func _ensure_visibility_notifier() -> void:
	if is_instance_valid(_visibility_notifier):
		return
	var existing_node: Node = get_node_or_null(^"VisibilityNotifier")
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


func _configure_wheel_visuals() -> void:
	if _wheel_visuals_configured or not is_inside_tree():
		return
	_resolve_visual_roots()
	if _detailed_root == null and _low_detail_root == null:
		return
	var explicit_specs: Array[Dictionary] = _get_explicit_detailed_wheel_specs()
	if _detailed_root != null and explicit_specs.is_empty():
		push_error("CarVisualController detailed models require explicit wheel bindings.")
		return
	for spec: Dictionary in explicit_specs:
		if not _is_binding_spec_resolvable(spec):
			push_error("CarVisualController could not resolve an explicit detailed wheel binding.")
			return

	_collect_low_detail_wheel_nodes()
	for spec: Dictionary in explicit_specs:
		var binding: RuntimeWheelBinding = _create_binding_from_spec(spec)
		if binding == null:
			push_error("CarVisualController could not configure an explicit detailed wheel binding.")
			return
		_detailed_wheel_bindings.append(binding)
		_detailed_wheel_bindings_by_id[binding.wheel_id] = binding
	_wheel_visuals_configured = true


func _collect_low_detail_wheel_nodes() -> void:
	_low_detail_wheel_nodes.clear()
	_low_detail_base_rotations.clear()
	_low_detail_front_flags.clear()
	if _low_detail_root == null:
		return
	for wheel_name: StringName in LOW_DETAIL_WHEEL_NAMES:
		var wheel: Node3D = _low_detail_root.get_node_or_null(NodePath(str(wheel_name))) as Node3D
		if wheel == null:
			continue
		_low_detail_wheel_nodes.append(wheel)
		_low_detail_base_rotations.append(wheel.rotation)
		_low_detail_front_flags.append(wheel_name == &"WheelFrontLeft" or wheel_name == &"WheelFrontRight")


func _is_binding_spec_resolvable(spec: Dictionary) -> bool:
	var wheel_id: StringName = spec.get("wheel_id", &"")
	var pivot_parent_path: NodePath = spec.get("pivot_parent_path", NodePath())
	var pivot_parent: Node3D = get_node_or_null(pivot_parent_path) as Node3D
	if wheel_id.is_empty() or pivot_parent == null:
		return false
	var spin_paths: Array = spec.get("spin_node_paths", [])
	if spin_paths.is_empty():
		return false
	for path_value: Variant in spin_paths:
		var spin_path: NodePath = path_value
		var spin_node: Node3D = get_node_or_null(spin_path) as Node3D
		if spin_node == null:
			return false
	for path_value: Variant in spec.get("steering_only_node_paths", []):
		var steering_path: NodePath = path_value
		var steering_node: Node3D = get_node_or_null(steering_path) as Node3D
		if steering_node == null:
			return false
	return true


func _create_binding_from_spec(spec: Dictionary) -> RuntimeWheelBinding:
	var wheel_id: StringName = spec.get("wheel_id", &"")
	var pivot_parent_path: NodePath = spec.get("pivot_parent_path", NodePath())
	var pivot_parent: Node3D = get_node_or_null(pivot_parent_path) as Node3D
	if wheel_id.is_empty() or pivot_parent == null:
		return null
	var spin_nodes: Array[Node3D] = _resolve_node_paths(spec.get("spin_node_paths", []))
	var steering_only_nodes: Array[Node3D] = _resolve_node_paths(spec.get("steering_only_node_paths", []))
	if spin_nodes.is_empty():
		return null
	return _create_runtime_binding(
		wheel_id,
		pivot_parent,
		spec.get("pivot_position", Vector3.ZERO),
		spec.get("steers", false),
		float(spec.get("steering_direction", 1.0)),
		float(spec.get("spin_direction", 1.0)),
		spin_nodes,
		steering_only_nodes
	)


func _resolve_node_paths(path_values: Array) -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	for path_value: Variant in path_values:
		var node_path: NodePath = path_value
		var node: Node3D = get_node_or_null(node_path) as Node3D
		if node == null or nodes.has(node):
			continue
		nodes.append(node)
	return nodes


func _create_runtime_binding(
	wheel_id: StringName,
	pivot_parent: Node3D,
	pivot_position: Vector3,
	steers: bool,
	steering_direction: float,
	spin_direction: float,
	spin_nodes: Array[Node3D],
	steering_only_nodes: Array[Node3D]
) -> RuntimeWheelBinding:
	if pivot_parent == null or spin_nodes.is_empty():
		return null
	var steering_pivot: Node3D = Node3D.new()
	steering_pivot.name = "%sSteeringPivot" % String(wheel_id).to_pascal_case()
	steering_pivot.position = pivot_position
	pivot_parent.add_child(steering_pivot)
	_assign_runtime_owner(steering_pivot, pivot_parent.owner)

	var spin_pivot: Node3D = Node3D.new()
	spin_pivot.name = "%sSpinPivot" % String(wheel_id).to_pascal_case()
	steering_pivot.add_child(spin_pivot)
	_assign_runtime_owner(spin_pivot, pivot_parent.owner)

	for steering_node: Node3D in steering_only_nodes:
		if is_instance_valid(steering_node):
			_reparent_preserving_ancestor_transform(steering_node, steering_pivot, pivot_parent)
	for spin_node: Node3D in spin_nodes:
		if is_instance_valid(spin_node):
			_reparent_preserving_ancestor_transform(spin_node, spin_pivot, pivot_parent)

	var binding: RuntimeWheelBinding = RuntimeWheelBinding.new()
	binding.wheel_id = wheel_id
	binding.steering_pivot = steering_pivot
	binding.spin_pivot = spin_pivot
	binding.steers = steers
	binding.steering_direction = steering_direction
	binding.spin_direction = spin_direction
	return binding


func _assign_runtime_owner(node: Node, runtime_owner: Node) -> void:
	if runtime_owner != null and runtime_owner.is_ancestor_of(node):
		node.owner = runtime_owner


func _reparent_preserving_ancestor_transform(
	node: Node3D,
	target_parent: Node3D,
	common_ancestor: Node3D
) -> void:
	var source_transform: Transform3D = _get_transform_relative_to_ancestor(node, common_ancestor)
	var target_transform: Transform3D = _get_transform_relative_to_ancestor(target_parent, common_ancestor)
	var original_owner: Node = node.owner
	if original_owner != null:
		node.owner = null
	node.reparent(target_parent, false)
	node.transform = target_transform.affine_inverse() * source_transform
	if original_owner != null and original_owner.is_ancestor_of(node):
		node.owner = original_owner


func _get_transform_relative_to_ancestor(node: Node3D, ancestor: Node3D) -> Transform3D:
	if node == ancestor:
		return Transform3D.IDENTITY
	var relative_transform: Transform3D = node.transform
	var current_parent: Node = node.get_parent()
	while current_parent != null and current_parent != ancestor:
		if current_parent is Node3D:
			relative_transform = (current_parent as Node3D).transform * relative_transform
		current_parent = current_parent.get_parent()
	if current_parent != ancestor:
		push_error("CarVisualController wheel node is not below its configured pivot parent.")
		return Transform3D.IDENTITY
	return relative_transform


func _apply_runtime_wheel_bindings(bindings: Array[RuntimeWheelBinding], steering_angle: float) -> void:
	for binding: RuntimeWheelBinding in bindings:
		if binding == null or not is_instance_valid(binding.spin_pivot):
			continue
		var applied_steering: float = steering_angle * binding.steering_direction if binding.steers else 0.0
		binding.steering_pivot.quaternion = Quaternion(Vector3.UP, applied_steering)
		binding.spin_pivot.quaternion = Quaternion(Vector3.RIGHT, _wheel_spin * binding.spin_direction)


func _apply_low_detail_wheels(steering_angle: float) -> void:
	for index: int in range(_low_detail_wheel_nodes.size()):
		var wheel: Node3D = _low_detail_wheel_nodes[index]
		if not is_instance_valid(wheel) or not wheel.is_visible_in_tree():
			continue
		var rotation_value: Vector3 = _low_detail_base_rotations[index]
		rotation_value.x += _wheel_spin
		if _low_detail_front_flags[index]:
			rotation_value.y -= steering_angle
		wheel.rotation = rotation_value


func _set_low_detail_active(enabled: bool) -> void:
	_resolve_visual_roots()
	_using_low_detail = enabled and _low_detail_root != null
	if _detailed_root != null:
		_detailed_root.visible = not _using_low_detail
	if _low_detail_root != null:
		_low_detail_root.visible = _using_low_detail


func _on_visibility_notifier_screen_entered() -> void:
	_is_screen_visible = true
	if force_low_detail:
		return
	_set_low_detail_active(false)


func _on_visibility_notifier_screen_exited() -> void:
	_is_screen_visible = false
	_set_low_detail_active(true)
