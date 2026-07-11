extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_immutable_telemetry_snapshot()
	_test_pinned_supply_chain_contract()
	_test_source_derived_export_versions()
	_finish()


func _test_immutable_telemetry_snapshot() -> void:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.forward_speed = 12.5
	state.engine_rpm = 4200.0
	state.ground_contact_count = 3
	state.surface_grip_multiplier = 0.75
	var snapshot: CarTelemetrySnapshot = CarTelemetrySnapshot.capture(state)
	state.forward_speed = 1.0
	state.engine_rpm = 900.0
	state.ground_contact_count = 0
	state.surface_grip_multiplier = 1.0
	_expect(is_equal_approx(snapshot.get_forward_speed(), 12.5), "telemetry snapshot preserves captured speed after runtime mutation")
	_expect(is_equal_approx(snapshot.get_engine_rpm(), 4200.0), "telemetry snapshot preserves captured RPM after runtime mutation")
	_expect(snapshot.get_ground_contact_count() == 3, "telemetry snapshot preserves captured contact count")
	_expect(is_equal_approx(snapshot.get_surface_grip_multiplier(), 0.75), "telemetry snapshot preserves captured surface grip")
	var snapshot_source: String = FileAccess.get_file_as_string("res://scripts/car/car_telemetry_snapshot.gd")
	_expect(not snapshot_source.contains("func set_"), "telemetry snapshot exposes no mutating setter API")
	var physics_test_source: String = FileAccess.get_file_as_string("res://scripts/tests/vehicle_physics_pipeline_test.gd")
	_expect(physics_test_source.contains("get_telemetry_snapshot()"), "vehicle integration test consumes public telemetry")
	_expect(physics_test_source.contains("await get_tree().physics_frame"), "vehicle integration test includes actual SceneTree physics scheduling")


func _test_pinned_supply_chain_contract() -> void:
	var workflow_source: String = FileAccess.get_file_as_string("res://.github/workflows/windows-tests.yml")
	var manifest_source: String = FileAccess.get_file_as_string("res://scripts/ci/godot_4_7_sha512.txt")
	_expect(workflow_source.contains("GODOT_CHECKSUMS_FILE: scripts/ci/godot_4_7_sha512.txt"), "workflow selects the repository-owned checksum manifest")
	_expect(not workflow_source.contains("SHA512-SUMS.txt"), "workflow does not trust checksums downloaded with the release archives")
	_expect(manifest_source.contains("Godot_v4.7-stable_win64.exe.zip"), "checksum manifest pins the Windows editor archive")
	_expect(manifest_source.contains("Godot_v4.7-stable_export_templates.tpz"), "checksum manifest pins the Windows export templates")


func _test_source_derived_export_versions() -> void:
	var export_source: String = FileAccess.get_file_as_string("res://scripts/ci/export_windows.ps1")
	var version_source: String = FileAccess.get_file_as_string("res://scripts/ci/export_version.ps1")
	_expect(export_source.contains("Get-WindowsExportVersionInfo"), "Windows export derives version metadata before packaging")
	_expect(export_source.contains("Set-WindowsExportPresetVersions"), "Windows export injects derived metadata into both presets")
	_expect(export_source.contains("$originalPresetContent"), "Windows export preserves the committed preset content")
	_expect(export_source.contains("[System.IO.File]::WriteAllText"), "Windows export restores preset content in a finally block")
	_expect(version_source.contains("GITHUB_REF_TYPE -eq \"tag\""), "tagged builds derive semantic product versions")
	_expect(version_source.contains("ShortRevision"), "non-tagged builds retain source revision identity")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AUDIT_LOW_PRIORITY_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AUDIT_LOW_PRIORITY_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AUDIT_LOW_PRIORITY_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[AUDIT_LOW_PRIORITY_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[AUDIT_LOW_PRIORITY_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
