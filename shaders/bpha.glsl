#version 300 es
#ifdef GL_ES
precision highp float;
precision highp sampler2D;
#endif

uniform vec2 u_resolution;
uniform float u_color;
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

float noise( vec2 p )
{
	return texture(iChannel0,p).x; 
}

float fnoise(vec2 uv, vec4 sc) {
	float f  = sc.x*noise( uv ); uv = 2.*uv+.11532185;
		  f += sc.y*noise( uv ); uv = 2.*uv+.23548563;
		  f += sc.z*noise( uv ); uv = 2.*uv+.12589452;
		  f += sc.w*noise( uv ); uv = 2.*uv+.26489542;
	return f;
}

float noise2( vec2 p )
{
	return texture(iChannel1,p).x; 
}

float fnoise2(vec2 uv, vec4 sc) {
	float f  = sc.x*noise2( uv ); uv = 2.*uv+.11532185;
		  f += sc.y*noise2( uv ); uv = 2.*uv+.23548563;
		  f += sc.z*noise2( uv ); uv = 2.*uv+.12589452;
		  f += sc.w*noise2( uv ); uv = 2.*uv+.26489542;
	return f;
}


float terrain(float x) {
	float w=0.;
	float a=1.;
	x*=20.;
	w+=sin(x*.3521)*4.;
	for (int i=0; i<5; i++) {
		x*=1.53562;
		x+=7.56248;
		w+=sin(x)*a;		
		a*=.5;
	}
	return .2+w*.015;	
}



float scenex(vec2 p) {
	float t=terrain(p.x);
	float s=step(0.,p.y+t);
	return s;
}


float mi( in vec2 fragCoord , bool idx)
{
	vec2 uv = fragCoord.xy; // / iResolution.xy-.5;
	uv.x*=iResolution.x/iResolution.y;
	float v=0., l;
	float t=iTime*.505;
    t=0.;
	vec2 c=vec2(-t,0.);
	vec2 p;
	float sc=clamp(t*t*.5,.05,.15);
	uv.y-=.25;
	uv.x-=.2;
	for (int i=0; i<1; i++) {
		p=uv*sc;
		l=pow(max(0.,1.-length(p)*2.),15.);
		l=.02+l*.8;
		v+=scenex(p+c)*pow(float(i+1)/30.,2.)*l;			
		sc+=.006;
	}
	float clo;
    if(idx)clo=fnoise2((uv-vec2(t,0.))*vec2(.03,.15),vec4(.8,.6,.3,.1))*max(0.,1.-uv.y*3.);
    else clo=fnoise((uv-vec2(t,0.))*vec2(.03,.15),vec4(.8,.6,.3,.1))*max(0.,1.-uv.y*3.);
	float tx=uv.x-t*.5;
	float ter;
    if(idx) ter=(uv.y-fnoise2(vec2(tx)*.015,vec4(1.5,1.5,0.3,.1))*(.23*(01.+sin(tx*3.2342)*.25))+.5);
    else ter=(uv.y-fnoise(vec2(tx)*.015,vec4(1.5,1.5,0.3,.1))*(.23*(01.+sin(tx*3.2342)*.25))+.5);
			  
	float col=ter;
	return col;
}


float sdfCircle(vec2 p) {
    return length(p) - 1.0;
}

float sdfBox(vec2 p) {
  vec2 d = abs(p) - vec2(1.0);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float scene(vec2 uv) {
    return min(sdfCircle(uv / .1505 + vec2(03.60, -04.5092995)) * .1505,min(sdfBox((uv / 0.155 + vec2(-08.20, -2.5))*rotate2d(0.15)) * 0.155,min(min(sdfBox((uv / 0.215 + vec2(-02.0950, -1.7995))*rotate2d(-0.15)) * 0.215,max(sdfCircle(uv / 8.75 + vec2(0.230, -0.995)) * 8.75,mi((uv-vec2(01.195,0.2))*1.5*rotate2d(0.15),true)/1.55)),min(mi((uv-vec2(01.195,0.))*1.5*rotate2d(-0.35),false)/1.55,max(max(sdfBox(uv/0.75 + vec2(0.9, .0)) *-.75,sdfBox(uv/0.75 + vec2(-0.9, .0)) *-.75),sdfBox(uv/0.75 + vec2(-0., .0)) *-.75)))));
}

float mainImage(in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    return scene(uv);
}

void main() {
    glFragColor=vec4(mainImage(gl_FragCoord.xy));
}
