shader_type spatial;
render_mode diffuse_toon, specular_schlick_ggx, cull_back;

uniform sampler2D albedo_texture;
uniform sampler2D ramp_texture;
uniform float rim_intensity: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float roughness: hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float specular_strength: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform vec3 specular_tint = vec3(1.0, 1.0, 1.0);

void light() {
    vec3 color = texture(albedo_texture, UV).rgb;
    float NdotL = max(dot(NORMAL, LIGHT), 0.0);
    
    // Toon-style shading using ramp texture
    float gradient = texture(ramp_texture, vec2(NdotL, 0.5)).r;
    DIFFUSE_LIGHT = color * gradient * LIGHT_COLOR.rgb;
    
    // Rim light
    float fresnel_effect = pow(1.0 - dot(VIEW, NORMAL), 3.0);
    DIFFUSE_LIGHT += vec3(1.0) * fresnel_effect * rim_intensity;
    
    // Specular
    vec3 H = normalize(VIEW + LIGHT);
    float NdotH = max(dot(NORMAL, H), 0.0);
    float spec = pow(NdotH, mix(4.0, 128.0, roughness)) * specular_strength;
    SPECULAR_LIGHT = LIGHT_COLOR.rgb * spec * specular_tint;
}
