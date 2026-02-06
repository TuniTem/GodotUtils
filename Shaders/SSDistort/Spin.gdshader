shader_type canvas_item;

uniform vec2 u_mouse;
uniform float u_time;
uniform vec2 u_resolution;

#define TAU 6.2831853071
#define dt mod(TIME / 7.0, TAU)

vec2 rot(float a, vec2 v) {
    return vec2(
        v.x * cos(a) - v.y * sin(a),
        v.x * sin(a) + v.y * cos(a)
    );
}

void moda(inout vec2 p, float rep) {
    float per = TAU / rep;
    float a = mod(atan(p.y, p.x), per) - per * 0.5;
    p = vec2(cos(a), sin(a)) * length(p);
}

void mo(inout vec2 p, vec2 d) {
    p = abs(p) - d;
    if (p.y > p.x) p = p.yx;
}

float cyl(vec3 p, float r, float h) {
    return max(length(p.xy) - r, abs(p.z) - h);
}

float prim1(vec3 p) {
    float width = 0.05;
    p.xz = rot(p.y * 8.0, p.xz);
    mo(p.xz, vec2(0.1));
    moda(p.xz, 5.0);
    p.x -= width * 2.5;
    return cyl(p.xzy, width, 6.0);
}

float SDF(vec3 p) {
    p.yz = rot(TAU / 4.0, p.yz);
    p.xz = rot(sin(p.y * 1.5 + dt), p.xz);
    mo(p.xz, vec2(0.7));
    moda(p.xz, 6.0);
    p.x -= 0.1 + (p.y + 3.0);
    return prim1(p);
}

void fragment() {
    vec2 uv = (2.0 * FRAGCOORD.xy - u_resolution.xy) / u_resolution.y;

    vec3 ro = vec3(uv * 4.0, -20.0);
    vec3 rd = vec3(0.0, 0.0, 1.0);
    vec3 p = ro;
    vec3 col = vec3(0.0);

    float shad, d = 0.0;
    bool hit = false;

    for (float i = 0.0; i < 18.0; i++) {
        d = SDF(p);
        if (d < 0.01) {
            hit = true;
            shad = i / 64.0;
            break;
        }
        p += d * rd * 0.3;
    }

    if (hit) {
        col = vec3(smoothstep(0.7, 0.8, 1.0 - shad));
    }

    vec4 fragColor = vec4(sqrt(col), 1.0);
    float avg = (fragColor.r + fragColor.g + fragColor.b) / 3.0;

    vec4 milkBlack = vec4(vec3(0.0), 1.0);
    vec4 milkGrey = vec4(vec3(0.5), 1.0);
    vec4 milkWhite = vec4(vec3(1.0), 1.0);

    avg = floor(avg * 2.0 + 0.5);
    COLOR = mix(mix(milkBlack, milkGrey, avg), milkWhite, floor(avg / 2.0));
}
