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


vec4 mainImage( in vec2 fragCoord )
{
    return texelFetch(iChannel0, ivec2(0), 0);
}

void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
