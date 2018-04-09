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
uniform bool ffm;
uniform bool paused;
uniform bool reset;
uniform bool rot;

out vec4 glFragColor;
uniform float iTimeDelta;

#define iTime u_time
#define iResolution u_resolution
#define iChannel0 u_texture1
#define iChannel1 u_texture2
#define iMouse u_mouse


#define BALL_RADIUS 0.051
#define SUB_STEPS 16

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec2 screenToWorld(vec2 v) {
    v = v / iResolution.xy * 2.0 - 1.0;
    v.x *= iResolution.x / iResolution.y;
    return v;
}

vec2 worldToUV(vec2 v) {
    v.x /= iResolution.x / iResolution.y;
    v = (v + 1.0) * 0.5;
    return v;
}

float sdf(vec2 p) {
    return texture(iChannel0, worldToUV(p)).x;
}

vec2 normal(vec2 uv) {
	vec2 eps = vec2( 0.0005, 0.0 );
	return normalize(
		vec2(sdf(uv+eps.xy) - sdf(uv-eps.xy),
		     sdf(uv+eps.yx) - sdf(uv-eps.yx)));
}

vec4 mainImage(in vec2 fragCoord) {
    vec2 uv = screenToWorld(fragCoord);
    vec2 ballPos = texelFetch(iChannel1, ivec2(0), 0).xy;
    vec2 ballVel = texelFetch(iChannel1, ivec2(0), 0).zw;
    if(reset){
		ballPos = vec2(-1.,-.2);
		ballVel = vec2(0.,0.);
		}
	else
    if(!paused){
    /*if(ffm) {
        ballPos = screenToWorld(vec2(iMouse.x,iResolution.y-iMouse.y));
        ballVel = vec2(0.0);
    } else */{
    float x;
    x=step(1./10.,worldToUV(ballPos).x)*(1.-step(1.-1./8.,worldToUV(ballPos).y))*(1.-step(1./8.,worldToUV(ballPos).x))*(step(1.-1./4.,worldToUV(ballPos).y));
    
    if(x<0.5)
		{
        float xx=iTimeDelta;
        if(ffm)xx=iTimeDelta/5.; 
        float dt = xx / float(SUB_STEPS);
        if(rot)ballVel=-1.*vec2(0.0,0.025) *rotate2d(-atan(ballVel.x,ballVel.y));
        for(int i = 0; i < SUB_STEPS; i++) {
            // Collisions
            if(sdf(ballPos) < BALL_RADIUS) {
				if(abs(ballVel.x)<0.0005&&abs(ballVel.y)<0.0005){
                    continue;};
                vec2 fb=ballVel;
                ballVel = length(ballVel) * reflect(normalize(ballVel), -normal(ballPos)) * 0.999;
                //its fix little bit ...
                if(abs(length(ballVel))<0.99*abs(length(fb))){ballVel-=fb;
                ballVel.x=max(-0.005,min(0.005,ballVel.x));
                ballVel.y=max(-0.005,min(0.005,ballVel.y));}

            } else

            // Gravity
            ballVel.y -= 0.05 * dt;
            // Add velocity
            ballPos += ballVel * dt * 50.0;
        }
    }}}
    return  vec4(ballPos, ballVel);
}


void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
