shader_type spatial;
render_mode cull_disabled;  // Disable backface culling to show both sides

uniform sampler2D swirl_texture;   // Black & white swirl texture
uniform sampler2D purple_texture;  // Noisy purple texture
uniform float rotation_speed = 1.0;  // Rotation speed
uniform float blend_factor = 4.0;  // Control blending between swirl and purple noise
uniform float fresnel_power = 3.0;  // Strength of Fresnel transparency

// Function to rotate UVs around a pivot
vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
    float sine = sin(rotation);
    float cosine = cos(rotation);
    
    uv -= pivot;
    float x = uv.x;
    float y = uv.y;
    
    uv.x = x * cosine - y * sine;
    uv.y = x * sine + y * cosine;
    
    uv += pivot;

    return uv;
}

void fragment() {
    vec2 uv = UV;

    // Rotate the swirl texture
    float rotation = TIME * rotation_speed;
    vec2 swirl_uv = rotateUV(uv, vec2(0.5), rotation);
	
    float rotation2 = TIME * -rotation_speed;
    vec2 swirl_uv2 = rotateUV(uv, vec2(0.5), rotation2);

    // Sample both textures
    vec4 swirl_color = texture(swirl_texture, swirl_uv);
    vec4 purple_color = texture(purple_texture, swirl_uv2);

    // Extract grayscale swirl from red channel
    float swirl_grayscale = swirl_color.r;

    // Blend the swirl with the purple noise
    vec3 final_color = mix(vec3(swirl_grayscale), purple_color.rgb, blend_factor);

    // Fresnel Effect Calculation
    float fresnel = pow( dot(NORMAL, VIEW), fresnel_power);

    // Assign color and apply fresnel alpha
    ALBEDO = final_color * vec3(0.2, 0.2, 0.2);
    ALPHA = fresnel;  // Apply fresnel-based transparency
}
