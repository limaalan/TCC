shader_type spatial;

render_mode unshaded, cull_disabled, blend_add, depth_draw_never, fog_disabled;

varying vec3 local_pos;

uniform vec4 grid_color : source_color = vec4(0.0, 0.75, 1.0, 1.0);

uniform float grid_scale : hint_range(0.1, 40.0) = 4.0;
uniform float hex_radius : hint_range(0.05, 2.0) = 0.45;
uniform float line_width : hint_range(0.001, 0.3) = 0.06;

uniform float fill_alpha : hint_range(0.0, 1.0) = 0.04;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float rim_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;

const float SQRT3 = 1.7320508;
const float HEX_AXIS = 0.8660254;

void vertex() {
	local_pos = VERTEX;
}

float snap_to_center(float coord, float radius) {
	return floor((coord + radius) / (2.0 * radius)) * 2.0 * radius;
}

vec2 nearest_hex_center(vec2 p, float radius) {
	float y1 = snap_to_center(p.y, radius);
	float x1 = snap_to_center(p.x, radius * SQRT3);
	vec2 c1 = vec2(x1, y1);

	float x2 = snap_to_center(p.x - radius * SQRT3, radius * SQRT3);
	float y2 = snap_to_center(p.y - radius, radius);
	vec2 c2 = vec2(x2 + radius * SQRT3, y2 + radius);

	if (length(p - c1) < length(p - c2)) {
		return c1;
	}

	return c2;
}

float hex_distance(vec2 p, float radius) {
	float denom = HEX_AXIS * radius;

	float d0 = abs(dot(p, vec2(HEX_AXIS, 0.5))) / denom;
	float d1 = abs(dot(p, vec2(0.0, 1.0))) / denom;
	float d2 = abs(dot(p, vec2(-HEX_AXIS, 0.5))) / denom;

	return max(max(d0, d1), d2);
}

void fragment() {
	// Projeção no plano XZ da malha.
	// Isso evita o "polo" do UV no topo da SphereMesh.
	vec2 p = local_pos.xz * grid_scale;

	vec2 center = nearest_hex_center(p, hex_radius);
	float d = hex_distance(p - center, hex_radius);

	float line = smoothstep(1.0 - line_width, 1.0, d);

	// Fresnel simples para destacar bordas do domo.
	float fresnel = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim_power);

	float alpha = fill_alpha;
	alpha += line * line_alpha;
	alpha += fresnel * rim_alpha;

	ALBEDO = grid_color.rgb;
	EMISSION = grid_color.rgb * 1.5;
	ALPHA = clamp(alpha * grid_color.a, 0.0, 1.0);
}