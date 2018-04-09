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


// TAA Pass borrowed from Enscaoe Cube (https://www.shadertoy.com/view/4dSBDt)
// Use Firefox to view it!!

//#define NO_AA
#define NO_YCOCG

ivec2 offsets[8] = ivec2[8]( ivec2(-1,-1), ivec2(-1, 1), 
	ivec2(1, -1), ivec2(1, 1), 
	ivec2(1, 0), ivec2(0, -1), 
	ivec2(0, 1), ivec2(-1, 0));

vec3 RGBToYCoCg( vec3 RGB )
{
#ifndef NO_YCOCG
	float Y = dot(RGB, vec3(  1, 2,  1 )) * 0.25;
	float Co= dot(RGB, vec3(  2, 0, -2 )) * 0.25 + ( 0.5 * 256.0/255.0 );
	float Cg= dot(RGB, vec3( -1, 2, -1 )) * 0.25 + ( 0.5 * 256.0/255.0 );
	return vec3(Y, Co, Cg);
#else
    return RGB;
#endif
}

vec3 YCoCgToRGB( vec3 YCoCg )
{
#ifndef NO_YCOCG
	float Y= YCoCg.x;
	float Co= YCoCg.y - ( 0.5 * 256.0 / 255.0 );
	float Cg= YCoCg.z - ( 0.5 * 256.0 / 255.0 );
	float R= Y + Co-Cg;
	float G= Y + Cg;
	float B= Y - Co-Cg;
	return vec3(R,G,B);
#else
    return YCoCg;
#endif
}


vec4 mainImage( in vec2 fragCoord )
{
	vec4 fragColor;
	vec2 q = fragCoord.xy / iResolution.xy;    
    vec3 new = RGBToYCoCg(textureLod(iChannel0, q, 0.0).xyz);
    vec3 history = RGBToYCoCg(textureLod(iChannel1, q, 0.0).xyz);
    
    vec3 colorAvg = new;
    vec3 colorVar = new*new;
    
    // Marco Salvi's Implementation (by Chris Wyman)
    for(int i = 0; i < 8; i++)
    {
        vec3 fetch = RGBToYCoCg(texelFetch(iChannel0, ivec2(fragCoord.xy)+offsets[i], 0).xyz);
        colorAvg += fetch;
        colorVar += fetch*fetch;
    }
    colorAvg /= 9.0;
    colorVar /= 9.0;
    float gColorBoxSigma = 0.75;
	vec3 sigma = sqrt(max(vec3(0.0), colorVar - colorAvg*colorAvg));
	vec3 colorMin = colorAvg - gColorBoxSigma * sigma;
	vec3 colorMax = colorAvg + gColorBoxSigma * sigma;
    
    history = clamp(history, colorMin, colorMax);
  
	fragColor = vec4(YCoCgToRGB(mix(new, history, 0.95)), 1.0);
#ifdef NO_AA
    fragColor = vec4(YCoCgToRGB(new), 1.0);
#endif
	return fragColor;
	
}


void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
