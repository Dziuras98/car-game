@tool
extends Node3D

@export var track_width: float = 14.0:
	set(value):
		track_width = value
		_rebuild_track()
@export var grass_size: Vector2 = Vector2(260.0, 190.0):
	set(value):
		grass_size = value
		_rebuild_track()
@export var shoulder_width: float = 10.0:
	set(value):
		shoulder_width = value
		_rebuild_track()
@export var barrier_distance_from_road: float = 12.0:
	set(value):
		barrier_distance_from_road = value
		_rebuild_track()
@export var width_variation: float = 0.28:
	set(value):
		width_variation = clampf(value, 0.0, 0.45)
		_rebuild_track()
@export var has_stadium: bool = false:
	set(value):
		has_stadium = value
		_rebuild_track()
@export_range(4, 18, 1) var stadium_section_step: int = 8:
	set(value):
		stadium_section_step = maxi(value, 4)
		_rebuild_track()
@export var stadium_distance_from_barrier: float = 24.0:
	set(value):
		stadium_distance_from_barrier = maxf(value, 8.0)
		_rebuild_track()

var _content_root: TrackGeneratedContentRoot
var _layout_builder: TrackLayoutBuilder
var _material_factory: TrackMaterialFactory
var _surface_builder: TrackSurfaceMeshBuilder
var _collision_builder: TrackCollisionBuilder
var _marker_builder: TrackMarkerBuilder
var _barrier_builder: TrackBarrierBuilder
var _decoration_builder: TrackDecorationBuilder
var _geometry: TrackGeometryData


func _ready() -> void:
	_ensure_builders()
	_rebuild_track()


func _rebuild_track() -> void:
	if not is_inside_tree():
		return

	_ensure_builders()
	var config: Dictionary = _build_track_generation_config()
	_geometry = _layout_builder.build(config)
	var generated_content: Node3D = _content_root.clear(self)

	_surface_builder.build_surfaces(generated_content, _geometry, _material_factory, config)
	_collision_builder.build_collisions(generated_content, _geometry, config)
	_marker_builder.build_markers(generated_content, _geometry, _material_factory, config)
	_barrier_builder.build_barriers(generated_content, _geometry, _material_factory, config)
	_decoration_builder.build_decorations(generated_content, _geometry, _material_factory, config)


func get_racing_line_points() -> Array[Vector3]:
	if _geometry == null:
		_ensure_builders()
		_geometry = _layout_builder.build(_build_track_generation_config())
	return _geometry.get_racing_line_points_array()


func _ensure_builders() -> void:
	if _content_root == null:
		_content_root = TrackGeneratedContentRoot.new()
	if _layout_builder == null:
		_layout_builder = TrackLayoutBuilder.new()
	if _material_factory == null:
		_material_factory = TrackMaterialFactory.new()
	if _surface_builder == null:
		_surface_builder = TrackSurfaceMeshBuilder.new()
	if _collision_builder == null:
		_collision_builder = TrackCollisionBuilder.new()
	if _marker_builder == null:
		_marker_builder = TrackMarkerBuilder.new()
	if _barrier_builder == null:
		_barrier_builder = TrackBarrierBuilder.new()
	if _decoration_builder == null:
		_decoration_builder = TrackDecorationBuilder.new()


func _build_track_generation_config() -> Dictionary:
	return {
		"track_width": track_width,
		"grass_size": grass_size,
		"shoulder_width": shoulder_width,
		"barrier_distance_from_road": barrier_distance_from_road,
		"width_variation": width_variation,
		"has_stadium": has_stadium,
		"stadium_section_step": stadium_section_step,
		"stadium_distance_from_barrier": stadium_distance_from_barrier,
	}
