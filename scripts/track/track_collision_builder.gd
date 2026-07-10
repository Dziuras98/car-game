extends RefCounted
class_name TrackCollisionBuilder


func build_collisions(
	parent: Node3D,
	geometry: TrackGeometryData,
	config: TrackGenerationConfig,
	surface_meshes: TrackGeneratedMeshes
) -> void:
	_add_grass_collision(parent, config)
	var shoulder_mesh: ArrayMesh = surface_meshes.shoulder_mesh if surface_meshes != null else null
	var track_mesh: ArrayMesh = surface_meshes.track_mesh if surface_meshes != null else null
	_add_shoulder_collision(parent, geometry, shoulder_mesh)
	_add_track_collision(parent, geometry, track_mesh)


func _add_grass_collision(parent: Node3D, config: TrackGenerationConfig) -> void:
	var grass_body: StaticBody3D = parent.get_node_or_null("Grass") as StaticBody3D
	if grass_body == null:
		return
	var grass_size: Vector2 = config.grass_size if config != null else Vector2(260.0, 190.0)
	var grass_shape: BoxShape3D = BoxShape3D.new()
	grass_shape.size = Vector3(grass_size.x, 0.4, grass_size.y)

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = grass_shape
	grass_body.add_child(collision)
	grass_body.move_child(collision, 0)
	collision.owner = parent.owner


func _add_shoulder_collision(
	parent: Node3D,
	geometry: TrackGeometryData,
	provided_mesh: ArrayMesh
) -> void:
	var shoulder_body: StaticBody3D = parent.get_node_or_null("RoadsideTerrain") as StaticBody3D
	if shoulder_body == null:
		return
	var collision_mesh: ArrayMesh = provided_mesh
	if collision_mesh == null:
		collision_mesh = TrackSurfaceMeshBuilder.create_shoulder_mesh(geometry)

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = collision_mesh.create_trimesh_shape()
	shoulder_body.add_child(collision)
	shoulder_body.move_child(collision, 0)
	collision.owner = parent.owner


func _add_track_collision(
	parent: Node3D,
	geometry: TrackGeometryData,
	provided_mesh: ArrayMesh
) -> void:
	var track_body: StaticBody3D = parent.get_node_or_null("TrackSurface") as StaticBody3D
	if track_body == null:
		return
	var collision_mesh: ArrayMesh = provided_mesh
	if collision_mesh == null:
		collision_mesh = TrackSurfaceMeshBuilder.create_track_mesh(geometry)

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = collision_mesh.create_trimesh_shape()
	track_body.add_child(collision)
	track_body.move_child(collision, 0)
	collision.owner = parent.owner
