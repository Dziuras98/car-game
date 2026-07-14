from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one match, found {count}: {old[:100]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8", newline="\n")


baker = Path("scripts/tools/engine_audio_bank_baker.gd")
replace_once(
    baker,
    "\tvar absolute_output_directory: String = ProjectSettings.globalize_path(preset.output_directory)\n\tvar directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_output_directory)\n\tif directory_error != OK and directory_error != ERR_ALREADY_EXISTS:\n\t\tpush_error(\"Could not create engine-audio bake directory: %s\" % preset.output_directory)\n\t\treturn {}\n",
    "\tvar staging_directory: String = \"%s.__staging\" % preset.output_directory\n\tif not _prepare_empty_directory(staging_directory):\n\t\tpush_error(\"Could not prepare engine-audio staging directory: %s\" % staging_directory)\n\t\treturn {}\n",
)
replace_once(
    baker,
    "\tif synthesizer == null or not synthesizer.has_method(\"generate_test_frames\"):\n\t\tpush_error(\"The configured synthesizer must expose generate_test_frames().\")\n\t\t_dispose_synthesizer(synthesizer)\n\t\treturn {}\n",
    "\tif synthesizer == null or not synthesizer.has_method(\"generate_test_frames\"):\n\t\tpush_error(\"The configured synthesizer must expose generate_test_frames().\")\n\t\t_dispose_synthesizer(synthesizer)\n\t\t_discard_directory(staging_directory)\n\t\treturn {}\n",
)
replace_once(
    baker,
    "\tif not bool(preset.profile.call(\"apply_to\", synthesizer)):\n\t\t_dispose_synthesizer(synthesizer)\n\t\treturn {}\n\n\t_remove_previous_generated_files(preset.output_directory)\n",
    "\tif not bool(preset.profile.call(\"apply_to\", synthesizer)):\n\t\t_dispose_synthesizer(synthesizer)\n\t\t_discard_directory(staging_directory)\n\t\treturn {}\n\n",
)
replace_once(
    baker,
    "\t\t\tvar resource_path: String = preset.output_directory.path_join(file_name)\n",
    "\t\t\tvar resource_path: String = staging_directory.path_join(file_name)\n",
)
replace_once(
    baker,
    "\t\t\tif samples.is_empty() or not _write_pcm16_mono_wav(resource_path, samples, preset.sample_rate):\n\t\t\t\t_dispose_synthesizer(synthesizer)\n\t\t\t\treturn {}\n",
    "\t\t\tif samples.is_empty() or not _write_pcm16_mono_wav(resource_path, samples, preset.sample_rate):\n\t\t\t\t_dispose_synthesizer(synthesizer)\n\t\t\t\t_discard_directory(staging_directory)\n\t\t\t\treturn {}\n",
)
replace_once(
    baker,
    "\tvar success: bool = (\n\t\t_write_manifest(preset.output_directory.path_join(\"bank_manifest.json\"), manifest)\n\t\tand _write_bank_resource(preset, manifest)\n\t)\n\t_dispose_synthesizer(synthesizer)\n\treturn manifest if success else {}\n",
    "\tvar success: bool = (\n\t\t_write_manifest(staging_directory.path_join(\"bank_manifest.json\"), manifest)\n\t\tand _write_bank_resource(preset, manifest, staging_directory)\n\t)\n\t_dispose_synthesizer(synthesizer)\n\tif not success:\n\t\t_discard_directory(staging_directory)\n\t\treturn {}\n\tif not _commit_staged_bank(staging_directory, preset.output_directory):\n\t\tpush_error(\"Could not atomically publish engine-audio bank: %s\" % preset.output_directory)\n\t\treturn {}\n\treturn manifest\n",
)
replace_once(
    baker,
    "func _write_bank_resource(preset: EngineAudioBakePreset, manifest: Dictionary) -> bool:\n",
    "func _write_bank_resource(\n\tpreset: EngineAudioBakePreset,\n\tmanifest: Dictionary,\n\toutput_directory: String\n) -> bool:\n",
)
replace_once(
    baker,
    "\tvar path: String = preset.output_directory.path_join(\"bank.tres\")\n",
    "\tvar path: String = output_directory.path_join(\"bank.tres\")\n",
)

atomic_helpers = '''

func _prepare_empty_directory(directory_path: String) -> bool:
	_discard_directory(directory_path)
	var error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(directory_path)
	)
	return error == OK or error == ERR_ALREADY_EXISTS


func _commit_staged_bank(staging_directory: String, output_directory: String) -> bool:
	var output_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(output_directory)
	)
	if output_error != OK and output_error != ERR_ALREADY_EXISTS:
		return false
	var backup_directory: String = "%s.__backup" % output_directory
	if not _prepare_empty_directory(backup_directory):
		return false

	var backed_up_files: Array[String] = []
	var published_files: Array[String] = []
	var output: DirAccess = DirAccess.open(output_directory)
	if output != null:
		for file_name: String in output.get_files():
			if not _is_generated_bank_file(file_name):
				continue
			if not _move_file(
				output_directory.path_join(file_name),
				backup_directory.path_join(file_name)
			):
				_rollback_staged_bank(
					staging_directory,
					output_directory,
					backup_directory,
					backed_up_files,
					published_files
				)
				return false
			backed_up_files.append(file_name)

	var staging: DirAccess = DirAccess.open(staging_directory)
	if staging == null:
		_rollback_staged_bank(
			staging_directory,
			output_directory,
			backup_directory,
			backed_up_files,
			published_files
		)
		return false
	for file_name: String in staging.get_files():
		if not _move_file(
			staging_directory.path_join(file_name),
			output_directory.path_join(file_name)
		):
			_rollback_staged_bank(
				staging_directory,
				output_directory,
				backup_directory,
				backed_up_files,
				published_files
			)
			return false
		published_files.append(file_name)

	_discard_directory(backup_directory)
	_discard_directory(staging_directory)
	return true


func _rollback_staged_bank(
	staging_directory: String,
	output_directory: String,
	backup_directory: String,
	backed_up_files: Array[String],
	published_files: Array[String]
) -> void:
	for file_name: String in published_files:
		_move_file(
			output_directory.path_join(file_name),
			staging_directory.path_join(file_name)
		)
	for file_name: String in backed_up_files:
		_move_file(
			backup_directory.path_join(file_name),
			output_directory.path_join(file_name)
		)
	_remove_directory_if_empty(backup_directory)


func _move_file(source_path: String, destination_path: String) -> bool:
	var destination_directory: String = destination_path.get_base_dir()
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(destination_directory)
	)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return false
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(source_path),
		ProjectSettings.globalize_path(destination_path)
	) == OK


func _discard_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory != null:
		for file_name: String in directory.get_files():
			directory.remove(file_name)
	_remove_directory_if_empty(directory_path)


func _remove_directory_if_empty(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory != null and (not directory.get_files().is_empty() or not directory.get_directories().is_empty()):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory_path))
'''
replace_once(
    baker,
    "\n\nfunc _remove_previous_generated_files(output_directory: String) -> void:\n",
    atomic_helpers + "\n\nfunc _remove_previous_generated_files(output_directory: String) -> void:\n",
)

# Extend the baker regression with an unrelated file and staging cleanup checks.
test = Path("scripts/tests/engine_audio_bank_baker_test.gd")
replace_once(
    test,
    "\t_remove_output_directory()\n\tvar preset: EngineAudioBakePreset = EngineAudioBakePreset.new()\n",
    "\t_remove_output_directory()\n\t_create_unrelated_file()\n\tvar preset: EngineAudioBakePreset = EngineAudioBakePreset.new()\n",
)
replace_once(
    test,
    "\t_expect(FileAccess.file_exists(OUTPUT_DIRECTORY.path_join(\"bank.tres\")), \"the baker writes a runtime bank resource\")\n",
    "\t_expect(FileAccess.file_exists(OUTPUT_DIRECTORY.path_join(\"bank.tres\")), \"the baker writes a runtime bank resource\")\n\t_expect(FileAccess.file_exists(OUTPUT_DIRECTORY.path_join(\"unrelated.wav\")), \"atomic publishing preserves unrelated files\")\n\t_expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(\"%s.__staging\" % OUTPUT_DIRECTORY)), \"successful bake removes its staging directory\")\n\t_expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(\"%s.__backup\" % OUTPUT_DIRECTORY)), \"successful bake removes its backup directory\")\n",
)
replace_once(
    test,
    "\n\nfunc _has_pcm16_wav_header(path: String) -> bool:\n",
    '''

func _create_unrelated_file() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(absolute_path)
	var file: FileAccess = FileAccess.open(OUTPUT_DIRECTORY.path_join("unrelated.wav"), FileAccess.WRITE)
	if file != null:
		file.store_string("must survive bank publishing")
		file.close()


func _has_pcm16_wav_header(path: String) -> bool:
''',
)
replace_once(
    test,
    "func _remove_output_directory() -> void:\n\tvar absolute_path: String = ProjectSettings.globalize_path(OUTPUT_DIRECTORY)\n\tif not DirAccess.dir_exists_absolute(absolute_path):\n\t\treturn\n\tvar directory: DirAccess = DirAccess.open(OUTPUT_DIRECTORY)\n\tif directory != null:\n\t\tfor file_name: String in directory.get_files():\n\t\t\tdirectory.remove(file_name)\n\tDirAccess.remove_absolute(absolute_path)\n",
    '''func _remove_output_directory() -> void:
	for directory_path: String in [
		OUTPUT_DIRECTORY,
		"%s.__staging" % OUTPUT_DIRECTORY,
		"%s.__backup" % OUTPUT_DIRECTORY,
	]:
		var absolute_path: String = ProjectSettings.globalize_path(directory_path)
		if not DirAccess.dir_exists_absolute(absolute_path):
			continue
		var directory: DirAccess = DirAccess.open(directory_path)
		if directory != null:
			for file_name: String in directory.get_files():
				directory.remove(file_name)
		DirAccess.remove_absolute(absolute_path)
''',
)

Path("tools/apply_engine_audio_realism_patch.py").unlink()
print("Atomic engine-audio bank publishing applied.")
