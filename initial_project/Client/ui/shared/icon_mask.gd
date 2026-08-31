class_name UiIconMask
extends RefCounted

## Converts monochrome source art into a colored icon.
## Black pixels become transparent and white pixels use the supplied color.
static func tint(source: Texture2D, color: Color, max_size := 0) -> ImageTexture:
	var image := source.get_image()
	if max_size > 0:
		image.resize(max_size, max_size, Image.INTERPOLATE_LANCZOS)

	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var mask := pixel.get_luminance() * pixel.a
			image.set_pixel(x, y, Color(color.r, color.g, color.b, mask))

	return ImageTexture.create_from_image(image)
