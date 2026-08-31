shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	vec2 p = abs(UV - vec2(0.5)) - (vec2(0.5) - vec2(radius));
	float dist = length(max(p, vec2(0.0))) - radius;

	float mask = 1.0 - smoothstep(0.0, 0.005, dist);

	COLOR = vec4(tex.rgb, tex.a * mask);
}