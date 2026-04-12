shader_type spatial;
render_mode unshaded, cull_front;

// Inverted-hull outline shader for the "Chunky Crackdown" art style.
// Apply as a second material pass on character/prop meshes.
// Cull front faces and expand vertices along normals to create bold outlines.

uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);

void vertex() {
	// Expand vertices along normals in clip space for consistent-width outlines
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
	vec2 offset = normalize(clip_normal.xy) * outline_width * clip_pos.w;
	clip_pos.xy += offset;
	POSITION = clip_pos;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
