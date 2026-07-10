extends RefCounted
class_name TrackGeneratedContentRoot

const GENERATED_CONTENT_NAME: String = "GeneratedContent"
const STAGED_CONTENT_NAME: String = "GeneratedContentPending"


func get_or_create(owner: Node) -> Node3D:
	var existing: Node = owner.get_node_or_null(GENERATED_CONTENT_NAME)
	if existing is Node3D:
		return existing as Node3D

	var container: Node3D = create_staging_container()
	owner.add_child(container)
	container.name = GENERATED_CONTENT_NAME
	_assign_owner_recursive(container, owner.owner)
	return container


func create_staging_container() -> Node3D:
	var container: Node3D = Node3D.new()
	container.name = STAGED_CONTENT_NAME
	return container


func commit(owner: Node, staged_container: Node3D) -> Node3D:
	if owner == null or staged_container == null:
		return null
	if staged_container.get_parent() != null:
		push_warning("Staged generated content already has a parent and cannot be committed.")
		return null

	var existing: Node = owner.get_node_or_null(GENERATED_CONTENT_NAME)
	owner.add_child(staged_container)
	if staged_container.get_parent() != owner:
		return null

	if existing != null:
		owner.remove_child(existing)
	staged_container.name = GENERATED_CONTENT_NAME
	_assign_owner_recursive(staged_container, owner.owner)

	if existing != null:
		existing.queue_free()
	return staged_container


func _assign_owner_recursive(node: Node, scene_owner: Node) -> void:
	node.owner = scene_owner
	for child: Node in node.get_children():
		_assign_owner_recursive(child, scene_owner)
