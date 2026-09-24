// Draws the lawn from its cell mask: red channel 0 = long grass, 0.5 = cut light
// stripe, 1.0 = cut dark stripe. Grass textures tile in world pixels.
shader_type canvas_item;

uniform sampler2D long_tex : filter_nearest, repeat_enable;
uniform sampler2D light_tex : filter_nearest, repeat_enable;
uniform sampler2D dark_tex : filter_nearest, repeat_enable;
uniform vec2 lawn_px = vec2(1280.0, 720.0);

void fragment() {
	float m = texture(TEXTURE, UV).r;
	vec2 p = UV * lawn_px / 32.0;
	vec4 c = texture(long_tex, p);
	if (m > 0.75) {
		c = texture(dark_tex, p);
	} else if (m > 0.25) {
		c = texture(light_tex, p);
	}
	COLOR = c;
}
