extends RefCounted
class_name TrackCheckpointBuilder


func build(
	parent: Node3D,
	geometry: TrackGeometryData,
	layout: TrackLayoutResource,
	crossing_callback: Callable
) -> Array[TrackCheckpointGate]:
	var gates: Array[TrackCheckpointGate] = []
	if parent == null or geometry == null or layout == null:
		return gates
	if geometry.center_points.is_empty() or not layout.has_valid_checkpoint_sequence():
		return gates

	_append_gate(gates, parent, geometry, layout, 0, 0, crossing_callback)

	var point_count: int = geometry.center_points.size()
	for checkpoint_offset: int in layout.checkpoint_progresses.size():
		var progress: float = layout.checkpoint_progresses[checkpoint_offset]
		var sample_index: int = clampi(
			floori(progress * float(point_count)),
			0,
			point_count - 1
		)
		_append_gate(
			gates,
			parent,
			geometry,
			layout,
			checkpoint_offset + 1,
			sample_index,
			crossing_callback
		)

	return gates


func _append_gate(
	gates: Array[TrackCheckpointGate],
	parent: Node3D,
	geometry: TrackGeometryData,
	layout: TrackLayoutResource,
	sequence_index: int,
	sample_index: int,
	crossing_callback: Callable
) -> void:
	var forward: Vector3 = geometry.forward_vectors[sample_index].normalized()
	var right: Vector3 = geometry.right_vectors[sample_index].normalized()
	var z_axis: Vector3 = -forward
	var up: Vector3 = z_axis.cross(right)
	if up.length_squared() <= 0.000001:
		up = Vector3.UP
	else:
		up = up.normalized()

	var basis: Basis = Basis(right, up, z_axis).orthonormalized()
	var height: float = maxf(layout.checkpoint_height, 0.1)
	var width: float = (
		geometry.half_widths[sample_index] * 2.0
		+ maxf(layout.checkpoint_width_margin, 0.0) * 2.0
	)
	var gate_transform: Transform3D = Transform3D(
		basis,
		geometry.center_points[sample_index] + up * height * 0.5
	)

	var gate: TrackCheckpointGate = TrackCheckpointGate.new()
	gate.name = "FinishLine" if sequence_index == 0 else "Checkpoint%02d" % sequence_index
	gate.configure(
		sequence_index,
		gate_transform,
		Vector3(width, height, maxf(layout.checkpoint_depth, 0.1))
	)
	if crossing_callback.is_valid():
		gate.crossed.connect(crossing_callback)
	parent.add_child(gate)
	gates.append(gate)
