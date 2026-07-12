extends Node

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const OPPONENT_COUNT: int = 4

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_catalog_ai_eligibility()

	var world: Node3D = Node3D.new()
	add_child(world)
	var spawn_marker: Node3D = Node3D.new()
	spawn_marker.global_transform = Transform3D(Basis(Vector3.UP, 0.35), Vector3(4.0, 1.0, -7.0))
	world.add_child(spawn_marker)
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	world.add_child(track)
	await get_tree().process_frame

	var first_signature: Array[String] = await _capture_spawn_signature(world, spawn_marker, track, 20260710)
	var replay_signature: Array[String] = await _capture_spawn_signature(world, spawn_marker, track, 20260710)
	var alternate_signature: Array[String] = await _capture_spawn_signature(world, spawn_marker, track, 20260711)

	_expect(first_signature.size() == OPPONENT_COUNT, "seeded spawner commits the complete requested opponent set")
	_expect(first_signature == replay_signature, "same session seed reproduces opponent variants and AI profiles")
	_expect(first_signature != alternate_signature, "different session seed changes at least one opponent variant or profile")

	world.queue_free()
	await get_tree().process_frame
	_finish()


func _test_catalog_ai_eligibility() -> void:
	var ai_eligible_variants: Array[CarVariantDefinition] = []
	var eligible_ids: Dictionary = {}
	for variant: CarVariantDefinition in CATALOG.get_all_variants():
		if variant != null and variant.is_ai_eligible_for_race():
			ai_eligible_variants.append(variant)
			eligible_ids[str(variant.variant_id)] = true

	_expect(ai_eligible_variants.size() == 2, "catalog exposes the standard and NISMO automatic variants to AI")
	_expect(eligible_ids.has("nissan_370z_7at"), "standard 370Z automatic remains AI-eligible")
	_expect(eligible_ids.has("nissan_370z_nismo_7at_global"), "370Z NISMO automatic is explicitly AI-eligible")
	for variant: CarVariantDefinition in ai_eligible_variants:
		_expect(variant.ai_eligible, "AI eligibility is declared by variant metadata: %s" % str(variant.variant_id))
		_expect(
			variant.get_specs() != null and variant.get_specs().is_automatic_transmission(),
			"AI-eligible variant uses a supported automatic transmission: %s" % str(variant.variant_id)
		)


func _capture_spawn_signature(
	world: Node3D,
	spawn_marker: Node3D,
	track: GeneratedTrack,
	seed: int
) -> Array[String]:
	var spawner: CarSpawner = CarSpawner.new()
	var configured: bool = spawner.configure(
		world,
		spawn_marker,
		track,
		CATALOG.get_all_variants(),
		4.2,
		7.0,
		seed
	)
	_expect(configured and spawner.is_configured(), "CarSpawner accepts the complete valid runtime contract")
	_expect(spawner.has_ai_eligible_cars(), "CarSpawner retains explicit AI-eligible variants")
	_expect(spawner.get_session_seed() == seed, "CarSpawner retains the explicit session seed")
	var opponents: Array[PlayerCarController] = spawner.spawn_opponents(OPPONENT_COUNT)
	var drivers: Array[AiRaceDriver] = spawner.get_ai_drivers()
	_expect(opponents.size() == OPPONENT_COUNT, "opponent commit is all-or-nothing for the requested count")
	_expect(opponents.size() == drivers.size(), "each seeded opponent has exactly one typed AI driver")

	var all_automatic: bool = true
	for opponent: PlayerCarController in opponents:
		all_automatic = (
			all_automatic
			and opponent.car_specs != null
			and opponent.car_specs.is_automatic_transmission()
		)
	_expect(all_automatic, "opponent selection never falls back to an unsupported manual variant")

	spawner.set_ai_enabled(true)
	var all_enabled: bool = true
	for driver: AiRaceDriver in drivers:
		all_enabled = all_enabled and driver.is_configured() and driver.is_physics_processing()
	_expect(all_enabled, "typed AI enablement activates every configured driver")
	spawner.set_ai_enabled(false)
	var all_disabled: bool = true
	for driver: AiRaceDriver in drivers:
		all_disabled = all_disabled and not driver.is_physics_processing()
	_expect(all_disabled, "typed AI disablement stops every driver")

	var signature: Array[String] = []
	for opponent_index: int in range(mini(opponents.size(), drivers.size())):
		var car: PlayerCarController = opponents[opponent_index]
		var profile: AiDriverProfile = drivers[opponent_index].get_profile()
		var variant_name: String = car.car_specs.display_name if car.car_specs != null else "missing"
		signature.append(
			"%s|%.6f|%.6f|%.6f" % [
				variant_name,
				profile.target_speed_kmh,
				profile.corner_speed_kmh,
				profile.lane_offset,
			]
		)

	spawner.clear_opponents()
	await get_tree().process_frame
	return signature


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OPPONENT_DETERMINISM_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[OPPONENT_DETERMINISM_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[OPPONENT_DETERMINISM_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[OPPONENT_DETERMINISM_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[OPPONENT_DETERMINISM_TEST] - %s" % failure_message)
	get_tree().quit(1)
