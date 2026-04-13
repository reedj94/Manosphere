shader_type canvas_item;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_count : hint_range(50.0, 800.0) = 300.0;
uniform float curvature : hint_range(0.0, 0.1) = 0.03;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float flicker_strength : hint_range(0.0, 0.1) = 0.02;
uniform float chromatic_aberration : hint_range(0.0, 5.0) = 1.2;
uniform float brightness : hint_range(0.5, 1.5) = 1.05;
uniform float noise_strength : hint_range(0.0, 0.1) = 0.03;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 curve_uv(vec2 uv) {
	vec2 centered = uv * 2.0 - 1.0;
	vec2 offset = centered * centered * curvature;
	centered += centered * offset;
	return centered * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(UV);

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	float pixel_offset = chromatic_aberration / float(textureSize(TEXTURE, 0).x);
	float r = texture(TEXTURE, vec2(uv.x + pixel_offset, uv.y)).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, vec2(uv.x - pixel_offset, uv.y)).b;
	vec3 col = vec3(r, g, b);

	float scanline = sin(uv.y * scanline_count * PI) * 0.5 + 0.5;
	col *= 1.0 - scanline_strength * (1.0 - scanline);

	float flicker = 1.0 + flicker_strength * sin(TIME * 8.0) * sin(TIME * 13.0 + 0.7);
	col *= flicker;

	float noise = rand(uv + vec2(TIME * 0.1, TIME * 0.2)) * noise_strength;
	col += vec3(noise);

	vec2 vig_uv = uv * (1.0 - uv);
	float vignette = vig_uv.x * vig_uv.y * 16.0;
	vignette = pow(vignette, vignette_strength);
	col *= vignette;

	col *= brightness;

	COLOR = vec4(col, 1.0);
}
