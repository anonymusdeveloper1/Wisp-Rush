extends SceneTree
## Joins QA captures side by side (same height, input order) into one contact-sheet PNG.
##
## Usage: Godot --headless --path . --script res://tools/godot/qa_contact_sheet.gd \
##          -- <out.png> <capture1.png> <capture2.png> ...

const TARGET_HEIGHT: int = 720
const GAP: int = 24
const BACKDROP := Color(0.16, 0.16, 0.18)


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("qa_contact_sheet: expected -- <out.png> <captures...>")
		quit(2)
		return
	var images: Array[Image] = []
	var total_width: int = GAP
	for path: String in args.slice(1):
		var image: Image = Image.load_from_file(path)
		if image == null or image.is_empty():
			continue
		image.convert(Image.FORMAT_RGBA8)
		var width: int = roundi(float(image.get_width()) * TARGET_HEIGHT / float(image.get_height()))
		image.resize(width, TARGET_HEIGHT, Image.INTERPOLATE_BILINEAR)
		images.append(image)
		total_width += width + GAP
	var sheet: Image = Image.create_empty(total_width, TARGET_HEIGHT + GAP * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(BACKDROP)
	var x: int = GAP
	for image: Image in images:
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(x, GAP))
		x += image.get_width() + GAP
	var error: Error = sheet.save_png(args[0])
	print("qa_contact_sheet: %d captures -> %s" % [images.size(), args[0]])
	quit(0 if error == OK else 1)
