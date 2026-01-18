shader_type canvas_item;

uniform float strength = 0.0;      // 0..1
uniform float speed = 1.5;
uniform float wave_amp = 0.008;
uniform float wave_freq = 10.0;
uniform float hue_speed = 0.15;

vec3 rgb2hsv(vec3 c){
	vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0*d + e)), d/(q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c){
	vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	float t = TIME * speed;

	// distorção ondulada
	float w1 = sin((uv.y + t) * wave_freq) * wave_amp * strength;
	float w2 = cos((uv.x * 1.3 + t) * (wave_freq * 0.9)) * wave_amp * strength;
	uv += vec2(w1, w2);

	vec4 col = texture(SCREEN_TEXTURE, uv);

	// --- hue shift estável: calcula a cor shiftada e mistura ---
	vec3 hsv = rgb2hsv(col.rgb);
	
	float shifted_h = fract(hsv.x + TIME * hue_speed); // ou use seno, se preferir
	vec3 shifted_rgb = hsv2rgb(vec3(shifted_h, hsv.y, hsv.z));
	
	col.rgb = mix(col.rgb, shifted_rgb, strength);
	
	// leve vignette
	vec2 p = uv - 0.5;
	float vig = smoothstep(0.8, 0.2, dot(p, p));
	col.rgb *= mix(1.0, vig, 0.25 * strength);
	
	COLOR = col;
}
