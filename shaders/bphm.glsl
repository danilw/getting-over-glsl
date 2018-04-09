#version 300 es
#ifdef GL_ES
precision highp float;
precision highp sampler2D;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture1;
uniform sampler2D u_texture2;
out vec4 glFragColor;
uniform bool antxtstate;

#define iTime u_time
#define iResolution u_resolution
#define iChannel0 u_texture1
#define iChannel1 u_texture2
#define iMouse u_mouse


#define BALL_RADIUS 0.051

vec2 uvToWorld(vec2 v) {
    v = v * 2.0 - 1.0;
    v.x *= iResolution.x / iResolution.y;
    return v;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}


float sdfCircle(vec2 p) {
    return length(p) - 1.0;
}

float sdfBox(vec2 p) {
  vec2 d = abs(p) - vec2(1.0);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}



float sdfBall(vec2 ball, vec2 p) {
    return distance(ball, uvToWorld(p)) - BALL_RADIUS;
}

vec4 mainImage(in vec2 fragCoord) {
	vec2 uv = fragCoord.xy / iResolution.xy;
    //vec2 uv2 = uv * vec2(iResolution.x / iResolution.y, 1.0);
    
    vec2 ballPos = texelFetch(iChannel1, ivec2(0), 0).xy;
    
    float sdf = min(texture(iChannel0, uv).x, (antxtstate)?1.:abs(sdfBall(ballPos, uv)));
    if(antxtstate){
	uv = fragCoord / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
	sdf=max(sdf,-0.01+sdfCircle(uv / .1505 + vec2(03.60, -04.5092995)) * -.1505);
    sdf=max(sdf,0.01+sdfBox((uv / 0.155 + vec2(-08.20, -2.5))*rotate2d(0.15)) * -0.155);
    sdf=max(sdf,0.01+sdfBox((uv / 0.215 + vec2(-02.0950, -1.7995))*rotate2d(-0.15)) * -0.215);
    return vec4(smoothstep(-0.0010, 3./ iResolution.y, sdf));
    }
	return vec4(smoothstep(0.0, 3.0 / iResolution.y, sdf));
    //return vec4(vec3(sin(sdf * 100.0 + iTime * 10.0) * 0.5 + 0.5),1.);
}

void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
