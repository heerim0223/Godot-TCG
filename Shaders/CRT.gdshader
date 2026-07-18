shader_type canvas_item;

// Reads the already-rendered screen so we can post-process it
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float scanline_count : hint_range(100.0, 800.0) = 360.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.18;
uniform float vignette_strength : hint_range(0.0, 3.0) = 0.4;
uniform float curvature : hint_range(0.0, 0.5) = 0.06;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.02;
uniform float chroma_aberration : hint_range(0.0, 0.01) = 0.0012;


float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}


// Bulges the UVs outward slightly to fake an old CRT tube's curved glass
vec2 curve_uv(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(6.0, 4.0);
	uv = uv + uv * offset * offset * curvature;
	uv = uv * 0.5 + 0.5;
	return uv;
}


void fragment() {
	vec2 uv = curve_uv(SCREEN_UV);

	// Godot's shader language doesn't allow an early "return" inside
	// fragment(), so instead we clamp the sample UV and mask the result
	// with a black-out factor at the very end.
	bool out_of_bounds = uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0;
	vec2 sample_uv = clamp(uv, 0.0, 1.0);

	// Slight per-channel offset for a cheap chromatic aberration look
	vec3 col;
	col.r = texture(screen_texture, sample_uv + vec2(chroma_aberration, 0.0)).r;
	col.g = texture(screen_texture, sample_uv).g;
	col.b = texture(screen_texture, sample_uv - vec2(chroma_aberration, 0.0)).b;

	// Horizontal scanlines
	float scanline = sin(sample_uv.y * scanline_count * PI) * 0.5 + 0.5;
	col *= 1.0 - scanline_opacity * scanline;

	// Soft vignette darkening the corners
	vec2 vign_uv = sample_uv * (1.0 - sample_uv.yx);
	float vign = vign_uv.x * vign_uv.y * 15.0;
	vign = pow(clamp(vign, 0.0, 1.0), vignette_strength);
	col *= mix(1.0, vign, 0.6);

	// Faint animated grain
	float n = (rand(sample_uv + fract(TIME)) - 0.5) * noise_strength;
	col += n;

	// Outside the curved screen bounds: crush to black, like a CRT bezel
	col = mix(col, vec3(0.0), float(out_of_bounds));

	COLOR = vec4(col, 1.0);
}
