shader_type spatial;

uniform sampler2D[5] card_textures;
uniform bool[5] textures_used;

const vec2 card_dimensions = vec2(0.49462, 0.79277);

const vec2 suit_dist_from_center = vec2(0.0, 0.25);
const vec2 suit_size = vec2(0.2, 0.2);
const vec2 tier_rank_size = vec2(0.15, 0.15);
const vec2 tier_rank_center_offset = vec2(0.15, 0.07);

const int PIXEL_EFFECT = 1 << 0;
const int TIER_EFFECT = 1 << 1;
const int RANK_EFFECT = 1 << 2;
const int SUIT_EFFECT = 1 << 3;


struct CardComponent{
	vec2 pos;
	vec2 size;
	bool rotate;
	int tex_index;
	int vfx;
	float vfx_magnitude;
};

struct EffectOutput{
	vec4 color;
	vec3 emission;	
};

void vertex() {
	// Called for every vertex the material is visible on.
	/*float s = 100.0;
	VERTEX.x += sin(TIME * 1.0 + VERTEX.z * 5.0) * 0.01;
	VERTEX.z += sin(TIME * 1.0 + VERTEX.x * 5.0) * 0.01;
	VERTEX = round(VERTEX * s) / s;*/
}

bool is_in_area(vec2 cur_pos, vec2 area_start, vec2 area_size){
	return cur_pos.x > area_start.x && cur_pos.x < (area_start.x + area_size.x) &&
	cur_pos.y > area_start.y && cur_pos.y < (area_start.y + area_size.y);
}

vec2 rotate_pos(vec2 cur_pos, vec2 center, float rads){
	mat2 rot = mat2(vec2(cos(rads), -sin(rads)), vec2(sin(rads), cos(rads)));
	cur_pos -= center;
	cur_pos *= rot;
	cur_pos += center;
	return cur_pos;
}

vec2 get_card_face_center(){
	vec2 center = card_dimensions / 2.0;
	center.x += card_dimensions.x;
	return center;
}

vec2 get_pos_start_from_center(vec2 center, vec2 size){
	return center - (size / 2.0);
}

//-1 = left/top
// 1 = right/bottom
vec2 apply_offset_to_pos(vec2 pos, vec2 offset, int left_right, int top_down){ 
	return vec2(
		pos.x + (offset.x * float(left_right)),
		pos.y + (offset.y * float(top_down))
	);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 apply_suit_vfx(vec2 uv, CardComponent c, vec4 col){
vec2 center = vec2(0.5, 0.5);
    float radius = distance(uv, center);
	float pixelation = 10.0;
	float noise = rand(uv) * 0.4;
	
	float edge_distance = 0.5;
	float diminishing_factor = max(0.0, 1.0 - radius / edge_distance);
	
    float wave = tan(TIME * 0.5 + radius * -4.0) * 0.01 * diminishing_factor;
	
    return vec2(wave, wave);
}

vec2 pixelize(vec2 uv, float apply){
	float s = pow(25.0, apply); 
	return mix(uv, round(uv * s) / s, apply);
}

float simple_wave_effect(vec2 uv, float dir){
	dir = clamp(ceil(dir), -1.0, 1.0);
	return sin(TIME * 1.0 + uv.y * 1.5 * dir) * 0.1;
}

EffectOutput apply_texture(vec2 uv, EffectOutput effect, CardComponent c){
		vec2 local_uv = (uv - c.pos) / c.size;
		
		// first pass
		local_uv = rotate_pos(local_uv, vec2(0.5, 0.5), PI * float(c.rotate));
		local_uv = pixelize(local_uv, float((c.vfx & PIXEL_EFFECT) > 0) * c.vfx_magnitude);
		
		local_uv = clamp(local_uv, vec2(0.0,0.0), vec2(1.0,1.0));
		vec4 local_tex = textureLod(card_textures[c.tex_index], local_uv, 0.0);
		
		//second pass
		local_uv += apply_suit_vfx(local_uv, c, local_tex) * float((c.vfx & SUIT_EFFECT) > 0) * c.vfx_magnitude;
		local_uv.x += simple_wave_effect(local_uv, 1.0) * c.vfx_magnitude * float((c.vfx & TIER_EFFECT) > 0);
		local_uv.x += simple_wave_effect(local_uv, -1.0) * c.vfx_magnitude * float((c.vfx & RANK_EFFECT) > 0);
		
		local_uv = clamp(local_uv, vec2(0.0,0.0), vec2(1.0,1.0));
		local_tex = textureLod(card_textures[c.tex_index], local_uv, 0.0);
		
		effect.color = mix(effect.color, local_tex, local_tex.a * float(textures_used[c.tex_index]));
		return effect;
}		

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV;

	vec2 card_face_center = get_card_face_center();
	
	vec2 suit_pos = get_pos_start_from_center(card_face_center - suit_dist_from_center, suit_size);
	vec2 mirrored_suit_pos = rotate_pos(suit_pos, card_face_center, PI) - suit_size;
	
	vec2 tier_pos = apply_offset_to_pos(get_pos_start_from_center(card_face_center, tier_rank_size), tier_rank_center_offset, -1, -1);
	vec2 mirrored_tier_pos = apply_offset_to_pos(get_pos_start_from_center(card_face_center, tier_rank_size), tier_rank_center_offset, -1, 1);
	
	vec2 rank_pos = apply_offset_to_pos(get_pos_start_from_center(card_face_center, tier_rank_size), tier_rank_center_offset, 1, -1);
	vec2 mirrored_rank_pos = apply_offset_to_pos(get_pos_start_from_center(card_face_center, tier_rank_size), tier_rank_center_offset, 1, 1);

	CardComponent components[] = {
		CardComponent(vec2(card_dimensions.x, 0.0), card_dimensions, false, 0, PIXEL_EFFECT, 1.5),
		CardComponent(vec2(0.0, 0.0), card_dimensions, false, 1, PIXEL_EFFECT, 1.3),
		CardComponent(suit_pos, suit_size, false, 2, SUIT_EFFECT | PIXEL_EFFECT, 1.0),
		CardComponent(mirrored_suit_pos, suit_size, true, 2, SUIT_EFFECT | PIXEL_EFFECT, 1.0),
		CardComponent(tier_pos, tier_rank_size, false, 3, TIER_EFFECT | PIXEL_EFFECT, 1.0),
		CardComponent(mirrored_tier_pos, tier_rank_size, true, 3, TIER_EFFECT | PIXEL_EFFECT, 1.0),
		CardComponent(rank_pos, tier_rank_size, false, 4, RANK_EFFECT | PIXEL_EFFECT, 1.0),
		CardComponent(mirrored_rank_pos, tier_rank_size, true, 4, RANK_EFFECT | PIXEL_EFFECT, 1.0)
	};
	
	EffectOutput o;
	o.color = vec4(0.007, 0.007, 0.007, 1.0);
	o.emission = EMISSION;
	
	for(int i = 0; i < components.length(); i++){
		CardComponent c = components[i];
		if(is_in_area(uv, c.pos, c.size)){
			o = apply_texture(uv, o, c);
		}
	}
	
	ALBEDO = o.color.rgb;
	ALPHA = o.color.a;
	EMISSION = o.emission;
}

void light() {
	// Called for every pixel for every light affecting the material.
	DIFFUSE_LIGHT *= 0.5;
}
