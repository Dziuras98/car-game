extends RefCounted
class_name TrackGeneratedContentRoot

const GENERATED_CONTENT_NAME: String = "GeneratedContent"


func get_or_create(owner: Node) -> Node3D:
	var existing: Node = owner.get_node_or_null(GENERATED_CONTENT_NAME)
	if existing is Node3D:
		return existing as Node3D

	var container: Node3D = create_staging_container()
	owner.add_child(container)
	container.owner = owner.owner
	return container


func create_staging_container() -> Node3D:
	var container: Node3D = Node3D.new()
	container.name = GENERATED_CONTENT_NAME
	return container


func commit(owner: Node, staged_container: Node3D) -> Node3D:
	if owner == null or staged_container == null:
		return null
	if staged_container.get_parent() != null:
		push_error("Staged generated content must not already have a parent.")
		return null

	var existing: Node = owner.get_node_or_null(GENERATED_CONTENT_NAME)
	if existing != null:
		owner.remove_child(existing)

	owner.add_child(staged_container)
	staged_container.owner = owner.owner

	if existing != null:
		existing.queue_free()
	return staged_container
