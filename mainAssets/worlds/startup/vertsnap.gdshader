// created by zodiepupper and xlinka (https://github.com/xlinka)
shader_type spatial;
//render_mode unshaded;
uniform float res;
uniform vec4 albedo: source_color;
uniform sampler3D noise;

void vertex() {
    vec3 scale = vec3(length(MODEL_MATRIX[0]), length(MODEL_MATRIX[1]), length(MODEL_MATRIX[2]));
    mat4 rot_matrix = mat4(normalize(MODEL_MATRIX[0]), normalize(MODEL_MATRIX[1]), normalize(MODEL_MATRIX[2]), vec4(0.0, 0.0, 0.0, 1.0));
    mat4 scale_matrix = mat4(vec4(scale.x, 0.0, 0.0, 0.0),
                             vec4(0.0, scale.y, 0.0, 0.0),
                             vec4(0.0, 0.0, scale.z, 0.0),
                             vec4(0.0, 0.0, 0.0, 1.0));
    vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
    world_pos.xyz = (round(world_pos.xyz * res) / res);
    vec4 local_pos = inverse(MODEL_MATRIX) * world_pos;

    VERTEX = (rot_matrix * scale_matrix * local_pos).xyz;
}

void fragment() {
    ALBEDO = albedo.rgb;
}

//void light(){
//
//}