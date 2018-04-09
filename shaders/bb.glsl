#version 300 es
#ifdef GL_ES
precision highp float;
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

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}


#define PI 3.14159265359
#define NUM_STRIPES 32.0
#define STRIPE_WIDTH .9
#define ANGLE_STRIPES PI * .25
#define CLAMP_TOP .5315
#define CLAMP_BOTTOM .155
#define SMOOTH_WIDTH .04


float easeInExpo(float t) {
	return t == 0.0 ? t : pow(2.0, 10.0 * (t - 1.0));
}


vec4 mi(in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 vUv = fragCoord*8.-3.5;
    vec2 rotatedUv = vUv;
  	
    // rotate context
    rotatedUv -= vec2(0.5);
    if ( rotatedUv.x < 0.0 ) {
    	rotatedUv *= rotate2d( ANGLE_STRIPES );
    } else {
        rotatedUv *= rotate2d( -ANGLE_STRIPES );
    }
    rotatedUv += vec2(0.5);
    
    
    vec2 stripeUv = rotatedUv;
    float gradient = 1.0 - fract( floor( ( rotatedUv.y ) * NUM_STRIPES ) / NUM_STRIPES + iTime );

    
    if ( stripeUv.y < CLAMP_BOTTOM || stripeUv.y > 1.0 - CLAMP_TOP ) { return vec4( 0. );}
    stripeUv.y = 1.0 - fract( stripeUv.y * NUM_STRIPES );
    // vUv.y = fract( vUv.y + iTime );
	float stripeWidth = STRIPE_WIDTH * gradient;
    
    float stripes = smoothstep( ( 1. - stripeWidth ) - SMOOTH_WIDTH, ( 1. - stripeWidth ) + SMOOTH_WIDTH, stripeUv.y);
    stripes -= 1.0 - smoothstep( 1.0, 1.0 - SMOOTH_WIDTH * 2.0, stripeUv.y);
    
    
    float col = stripes * gradient;


    // Output to screen
    return vec4( col )*step(0.4,vUv.x)*(1.-step(0.6,vUv.x));
}



vec4 mainImage( in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    uv*= vec2(iResolution.x / iResolution.y, 1.0);
    vec2 ballPos = texelFetch(iChannel0, ivec2(0), 0).xy;
    vec2 ballVel = texelFetch(iChannel0, ivec2(0), 0).zw;

    return mi(0.5+(uv-0.5)*rotate2d(atan(ballVel.x,ballVel.y)));
}

void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
