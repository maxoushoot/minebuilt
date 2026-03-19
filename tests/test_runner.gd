extends SceneTree

const TEST_ROOT := "res://tests/cases"

var _total_files := 0
var _total_assertions := 0
var _total_failures := 0

func _init() -> void:
	var cli := _parse_cli(OS.get_cmdline_args())
	var files := _resolve_files(cli)
	if files.is_empty():
		print("[TEST] Aucun fichier de test trouvé.")
		quit(1)
		return

	for path in files:
		if cli["filter"] != "" and path.to_lower().find(String(cli["filter"])) == -1:
			continue
		_run_file(path)

	if _total_files == 0:
		print("[TEST] Aucun test ne correspond au filtre demandé.")
		quit(1)
		return

	print("\n[TEST] Résumé: fichiers=%d assertions=%d échecs=%d" % [_total_files, _total_assertions, _total_failures])
	quit(0 if _total_failures == 0 else 1)

func _parse_cli(args: PackedStringArray) -> Dictionary:
	var parsed := {
		"file": "",
		"filter": "",
	}
	for arg in args:
		if arg.begins_with("--file="):
			parsed["file"] = arg.trim_prefix("--file=")
		elif arg.begins_with("--filter="):
			parsed["filter"] = arg.trim_prefix("--filter=").to_lower()
	return parsed

func _resolve_files(cli: Dictionary) -> Array[String]:
	var explicit_file := String(cli.get("file", "")).strip_edges()
	if explicit_file != "":
		return [explicit_file]

	var result: Array[String] = []
	var dir := DirAccess.open(TEST_ROOT)
	if dir == null:
		return result

	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if dir.current_is_dir():
			continue
		if not entry.ends_with("_test.gd"):
			continue
		result.append("%s/%s" % [TEST_ROOT, entry])
	dir.list_dir_end()
	result.sort()
	return result

func _run_file(path: String) -> void:
	var script := load(path)
	if script == null:
		_total_files += 1
		_total_failures += 1
		print("[TEST][FAIL] %s -> script introuvable" % path)
		return

	var test_case := script.new()
	if test_case == null:
		_total_files += 1
		_total_failures += 1
		print("[TEST][FAIL] %s -> instance impossible" % path)
		return

	_total_files += 1
	test_case.run()
	var summary := test_case.summarize()
	var passes := int(summary.get("passes", 0))
	var failures: Array = summary.get("failures", [])
	_total_assertions += passes + failures.size()
	if failures.is_empty():
		print("[TEST][PASS] %s (%d assertions)" % [path, passes])
		return

	_total_failures += failures.size()
	print("[TEST][FAIL] %s" % path)
	for failure in failures:
		print("  - %s" % String(failure))
