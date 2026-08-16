#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;
out vec4 finalColor;

const vec3 water_color = vec3(220, 242, 242) / vec3(255);
const vec3 water_edge_color = vec3(128, 198, 228) / vec3(255);
const vec3 grass_color = vec3(217, 231, 157) / vec3(255);
const vec3 grass_color_steep = vec3(178, 189, 115) / vec3(255);
const vec3 mountain_color = vec3(218, 218, 200) / vec3(255);
const vec3 mountain_color_steep = vec3(147, 125, 95) / vec3(255);
const vec3 contour_lines_color = vec3(181, 139, 97) / vec3(255);

float height(vec2 uv)
{
    return texture(texture0, uv).r;
}

float discrete_height(vec2 uv, float steps)
{
    return floor(height(uv) * steps) / steps;
}

vec2 unit_vec_rad(float rad)
{
    return vec2(cos(rad), sin(rad));
}
vec2 unit_vec_deg(float deg)
{
    return unit_vec_rad(radians(deg));
}

float contour_lines(vec2 uv, float steps, float thickness, int n)
{
    float discrete_height_0 = discrete_height(uv, steps);
    float dh = 0;
    for (int i = 0; i < n; ++i){
        float angle = 360 * float(i) / float(n);
        vec2 uv_n = uv + thickness * unit_vec_deg(angle);
        float discrete_height_n = discrete_height(uv_n, steps);
        dh += abs(discrete_height_n - discrete_height_0);
    }
    return step(0.5 / steps, dh);
}

float water_edge(vec2 uv, float thickness, int n)
{
    float water_0 = float(height(uv) == 0.0);
    float dh = 0;
    for (int i = 0; i < n; ++i){
        float angle = 360 * float(i) / float(n);
        vec2 uv_n = uv + thickness * unit_vec_deg(angle);
        float water_n = float(height(uv_n) == 0.0);
        dh += abs(water_n - water_0);
    }
    return step(0.5, dh);
}

float slope(vec2 uv, vec2 step_vec)
{
    return max(0.0, height(uv - step_vec) - height(uv)) / length(step_vec);
}

void main()
{
    vec2 uv = fragTexCoord;
    float l0 = contour_lines(uv, 5.0, 0.0012, 8);
    float l1 = contour_lines(uv, 20.0, 0.0006, 8);
    float w_e = water_edge(uv, 0.0016, 8);
    
    float dh = 0.0;
    dh += 0.120 * slope(uv, vec2(0.00250));
    dh = min(1.0, dh);

    vec3 color = water_color;
    color = mix(color, water_edge_color, w_e);
    color = mix(color, mix(grass_color, grass_color_steep, dh), float(height(uv) > 0.0));
    color = mix(color, mix(mountain_color, mountain_color_steep, dh), float(height(uv) > 0.32));
    color = mix(color, contour_lines_color, l0);
    color = mix(color, contour_lines_color, l1);

    finalColor = vec4(color, 1.0);
}
