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




vec3 saturate(vec3 a){return clamp(a,0.,1.);}
float opS( float d2, float d1 ){return max(-d1,d2);}
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
float rand(float n){
 	return fract(cos(n*89.42)*343.42);
}
float dtoa(float d, float amount)
{
    return clamp(1.0 / (clamp(d, 1.0/amount, 1.0)*amount), 0.,1.);
}

vec4 mainImage( in vec2 fragCoord )
{
	vec2 uv = (fragCoord / iResolution.y * 2.0) - 1.;
    
    vec3 col = vec3(1.,1.,0.86);
    float dist=1.;
    float amt = 90. + (rand(uv.y) * 100.) + (rand(uv.x / 4.) * 90.);
    float vary = sin(uv.x*uv.y*50.)*0.0047;
    dist = opS(dist-0.028+vary, dist-0.019-vary);
    col = mix(col, vec3(0.99,.4, 0.0), dtoa(dist, amt) * 0.7);
    col = mix(col, vec3(0.85,0.,0.), dtoa(dist, 700.));

    col.rgb += (rand(uv)-.5)*.08;
    col.rgb = saturate(col.rgb);

    uv -= 1.0;
	float vignetteAmt = 1.-dot(uv*0.5,uv* 0.12);
    col *= vignetteAmt*2.;
    
    
    return vec4(col, 1.);
}


void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
