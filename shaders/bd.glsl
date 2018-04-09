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

#define iTime u_time
#define iResolution u_resolution
#define iChannel0 u_texture1
#define iChannel1 u_texture2
#define iMouse u_mouse

vec2 worldToUV(vec2 v) {
    v.x /= iResolution.x / iResolution.y;
    v = (v + 1.0) * 0.5;
    return v;
}

vec4 mainImage( in vec2 fragCoord )
{
    float x;
    vec4 fragColor;
    vec2 ballPos = texelFetch(iChannel0, ivec2(0), 0).xy;
    vec4 ofc = texelFetch(iChannel1, ivec2(0), 0);
    x=step(1./10.,worldToUV(ballPos).x)*(1.-step(1.-1./8.,worldToUV(ballPos).y))*(1.-step(1./8.,worldToUV(ballPos).x))*(step(1.-1./4.,worldToUV(ballPos).y));
    
    if(x<0.5)
    fragColor = vec4((floor(iTime*10.)/100.),0.0,1.0,1.0);
    //else discard;
    else fragColor =ofc;
    return fragColor;
}

void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
