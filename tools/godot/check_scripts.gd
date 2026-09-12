extends SceneTree
## Loads every GDScript in the project so parse/compile errors surface in one headless pass.
##
## Usage (from the repo root):
##   Godot --headless --path . --script res://tools/godot/check_scripts.gd
## Prints "CHECK FAILED: <path>" per broken script and exits 1 if any failed.
## Skips addons/, tools/, docs/, build dirs, hidden folders and folders containing .gdignore.

const SKIP_DIRS: Array[String] = [
	"res://addons",
	"res://tools",
	"res://docs",
	"res://build",
	"res://export",
	"res://logs",
]


func _initialize() -> void:
	var scripts: Array[String] = []
	_collect("res://", scripts)
	var failed: Array[String] = []
	for path in scripts:
		var script: Script = ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
		if script == null or not (script.can_instantiate() or script.is_abstract()):
			failed.append(path)
	for path in failed:
		printerr("CHECK FAILED: %s" % path)
	print("check_scripts: %d scripts checked, %d failed" % [scripts.size(), failed.size()])
	quit(1 if not failed.is_empty() else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	if dir_path in SKIP_DIRS:
		return
	var dir := DirAccess.open(dir_path)
	if dir == null or dir.file_exists(".gdignore"):
		return
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file in dir.get_files():
		if file.get_extension() == "gd":
			out.append(dir_path.path_join(file))
