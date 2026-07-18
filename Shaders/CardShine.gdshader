shader_type canvas_item;

uniform float band_width : hint_range(0.05, 1.0) = 0.22;
uniform float highlight_strength : hint_range(0.0, 2.0) = 0.9;
uniform float angle : hint_range(-1.57, 1.57) = 0.6;
uniform float interval : hint_range(1.0, 10.0) = 3.5; // seconds between sweeps
// Set per-card from Card.gd so every card's shine is out of sync with the others
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;


void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	vec2 uv = UV - 0.5;
	float rotated = uv.x * cos(angle) - uv.y * sin(angle);

	float t = mod(TIME + time_offset, interval) / interval; // loops 0..1
	float sweep_pos = mix(-0.8, 0.8, smoothstep(0.0, 1.0, t));

	float dist = abs(rotated - sweep_pos);
	float highlight = smoothstep(band_width, 0.0, dist);

	vec3 shine_color = tex_color.rgb + highlight * highlight_strength;
	COLOR = vec4(shine_color, tex_color.a);
}
