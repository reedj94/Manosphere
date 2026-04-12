shader_type spatial;

// Flat shading shader for the "Chunky Crackdown" art style.
// Forces hard-edged flat shading on any mesh regardless of normals.
// Supports per-region colour grading via a tint uniform.

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color;
uniform vec4 region_tint : source_color = vec4(1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.5;
uniform vec4 shadow_color : source_color = vec4(0.2, 0.2, 0.25, 1.0);

void vertex() {
	// Flat shading: compute face normal from screen-space derivatives in fragment
}

void fragment() {
	// Reconstruct flat face normal from screen-space position derivatives
	vec3 view_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 flat_normal = normalize(cross(dFdx(view_pos), dFdy(view_pos)));

	vec4 tex_color = texture(albedo_texture, UV);
	vec3 base_color = albedo_color.rgb * tex_color.rgb * region_tint.rgb;

	// Simple two-tone shading (lit / shadow)
	float ndotl = dot(flat_normal, normalize(vec3(0.5, 1.0, 0.3)));
	vec3 final_color = ndotl > shadow_threshold ? base_color : mix(shadow_color.rgb, base_color, 0.5);

	ALBEDO = final_color;
}
