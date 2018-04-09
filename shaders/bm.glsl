#version 300 es
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture1;
uniform sampler2D u_texture2;
uniform sampler2D u_texture3;
uniform sampler2D u_texture4;
uniform sampler2D u_texture5;
uniform sampler2D u_texture6;
uniform sampler2D u_texture7;
uniform sampler2D u_texture8;
uniform sampler2D u_texture9;
uniform sampler2D u_texture10;
uniform sampler2D u_texture11;
uniform sampler2D u_texture12;
uniform sampler2D u_texture13;
out vec4 glFragColor;
uniform bool ffm;
uniform bool antxtstate;

#define iTime u_time
#define iResolution u_resolution
#define iChannel0 u_texture1
#define iChannel1 u_texture2
#define iChannel2 u_texture3
#define iChannel3 u_texture4
#define iChannel4 u_texture5
#define iChannel5 u_texture6
#define iChannel6 u_texture7
#define iChannel7 u_texture8
#define iChannel8 u_texture9
#define iChannel9 u_texture10
#define iChannel10 u_texture11
#define iChannel11 u_texture12
#define iChannel12 u_texture13
#define iMouse u_mouse






// Man has demonstrated that he is master of everything except his own nature
//---------------------------------------------------------------------------

// One morning we woke up when the sky was still dark.
// We walked half an hour through the forest,
// to reach the other side of the island,
// where the beach is facing the rising sun.
// The sun was already there, one half over the horizon.
// The sky was on fire.
// We swum in the sea, staring at the rising sun.

// visual parameters -------------------
vec3 sunColor = vec3(1.5,.9,.7);
const vec3 lightColor = vec3(1.,.8,.7);
vec3 darkColor = vec3(.2,.2,.3);
const vec3 baseSkyColor = vec3(.6,.7,.8);
const vec3 seaColor = vec3(.1,.03,.05);
const vec3 seaLight = vec3(.1,.045,.055);
//---------------------------------------

vec3 gamma( vec3 col, float g){
    return pow(col,vec3(g));
}
    
    
// clouds layered noise
float noiseLayer(vec2 uv){    
    float t = (iTime+iMouse.x)/5.;
    uv.y -= t/60.; // clouds pass by
    float e = 0.;
    for(float j=1.; j<9.; j++){
        // shift each layer in different directions
        float timeOffset = t*mod(j,2.989)*.02 - t*.015;
        e += 1.-texture(iChannel11, uv * (j*1.789) + j*159.45 + timeOffset).r / j ;
    }
    e /= 3.5;
    return e;
}

// waves layered noise
float waterHeight(vec2 uv){
    float t = (iTime+iMouse.x);
    float e = 0.;
    for(float j=1.; j<6.; j++){
        // shift each layer in different directions
        float timeOffset = t*mod(j,.789)*.1 - t*.05;
        e += texture(iChannel6, uv * (j*1.789) + j*159.45 + timeOffset).r / j ;
    }
    e /= 6.;
    return e;
}

vec3 waterNormals(vec2 uv){
    uv.x *= .25;
    float eps = 0.008;    
    vec3 n=vec3( waterHeight(uv) - waterHeight(uv+vec2(eps,0.)),
                 1.,
                 waterHeight(uv) - waterHeight(uv+vec2(0.,eps)));
   return normalize(n);
}	


vec3 drawSky( vec2 uv, vec2 uvInit){ 
        
	float clouds = noiseLayer(uv);
    
    // clouds normals
    float eps = 0.1;
    vec3 n = vec3(	clouds - noiseLayer(uv+vec2(eps,0.)),
            		-.3,
             		clouds - noiseLayer(uv+vec2(0.,eps)));
    n = normalize(n);
    
    // fake lighting
    float l = dot(n, normalize(vec3(uv.x,-.2,uv.y+.5)));
    l = clamp(l,0.,1.);
    
    // clouds color	(color gradient from light)
    vec3 cloudColor = mix(baseSkyColor, darkColor, length(uvInit)*1.7);
    cloudColor = mix( cloudColor,sunColor, l );
    
    // sky color (color gradient on Y)
    vec3 skyColor = mix(lightColor , baseSkyColor, clamp(uvInit.y*2.,0.,1.) );
    skyColor = mix ( skyColor, darkColor, clamp(uvInit.y*3.-.8,0.,1.) );
    skyColor = mix ( skyColor, sunColor, clamp(-uvInit.y*10.+1.1,0.,1.) );
    
	// draw sun
    if(length(uvInit-vec2(0.,.04) )<.03){
     	skyColor += vec3(2.,1.,.8);
    }
       
   	// mix clouds and sky
    float cloudMix = clamp(0.,1.,clouds*4.-8.);
    vec3 color = mix( cloudColor, skyColor, clamp(cloudMix,0.,1.) );
    
    // draw islands on horizon
    /*uvInit.y = abs(uvInit.y);
    float islandHeight = texture(iChannel6, uvInit.xx/2.+.867).r/15. - uvInit.y + .978;
    islandHeight += texture(iChannel6, uvInit.xx*2.).r/60.;
    islandHeight = clamp(floor(islandHeight),0.,1.);    
    vec3 landColor = mix(baseSkyColor, darkColor, length(uvInit)*1.5);
    color = mix(color, landColor, islandHeight);*/

    return color;
}

vec4 micld( in vec2 fragCoord )
{
    fragCoord*=8.;
    // center uv around horizon and manage ratio
	vec2 uvInit = fragCoord.xy / iResolution.xy;
    uvInit.x -= 2.782975;
    uvInit.x *= iResolution.x/iResolution.y;	
    uvInit.y -= 06.42835;
    
    // perspective deform 
    vec2 uv = uvInit;
    uv.y -=.01;
	uv.y = abs(uv.y);
    uv.y = log(uv.y)/2.;
    uv.x *= 1.-uv.y;
    uv *= .2;
    
    vec3 col = vec3(1.,1.,1.);
    
    // draw water
    if(uvInit.y < 0.){       
       
        vec3 n = waterNormals(uv);
        
        // draw reflection of sky into water
        vec3 waterReflections = drawSky(uv+n.xz, uvInit+n.xz);

        // mask for fore-ground green light effect in water
        float transparency = dot(n, vec3(0.,.2,1.5));        
        transparency -= length ( (uvInit - vec2(0.,-.35)) * vec2(.2,1.) );
		transparency = (transparency*12.+1.5);
        
        // add foreground water effect
        waterReflections = mix( waterReflections, seaColor, clamp(transparency,0.,1.) );
        waterReflections = mix( waterReflections, seaLight, max(0.,transparency-1.5) );

       	col = waterReflections;
        
        // darken sea near horizon
       	col = mix(col, col*vec3(.6,.8,1.), -uv.y);
        
        //sun specular
        col += max(0.,.02-abs(uv.x+n.x))* 8000. * vec3(1.,.7,.3) * -uv.y * max(0.,-n.z);
        
    }else{      
        
        // sky
        col = drawSky(uv, uvInit);
    }
    
    // sun flare & vignette
    col += vec3(1.,.8,.6) * (0.55-length(uvInit)) ;
    
    // "exposure" adjust
    col *= .75;
    col = gamma(col,1.3);
    
    return vec4(col,1.);
}

//--------------------------------------------------------------------
//There is no salvation in becoming adapted to a world which is crazy.




mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}


float snow(vec2 uv,float scale)
{
	float w=smoothstep(1.,0.,-uv.y*(scale/10.));if(w<.1)return 0.;
	uv+=iTime/2./scale;uv.y+=iTime/2.*2./scale;uv.x+=sin(uv.y+iTime/2.*.5)/scale;
	uv*=scale;vec2 s=floor(uv),f=fract(uv),p;float k=3.,d;
	p=.5+.35*sin(11.*fract(sin((s+p+scale)*mat2(7,3,6,5))*5.))-f;d=length(p);k=min(d,k);
	k=smoothstep(-0.0151,k,sin(f.x+f.y)*0.01);
    	return k*w;
}

vec4 misn( in vec2 fragCoord )
{
    
    fragCoord*=4.5;
    
    vec2 uv=(fragCoord.xy*2.-iResolution.xy)/min(iResolution.x,iResolution.y)-6.5; 
    uv*=rotate2d(.15);
	vec3 finalColor=vec3(0);
	float c=smoothstep(1.,0.3,clamp(uv.y*.3+.8,0.,.75));
	//c+=snow(uv,30.)*.3;
	//c+=snow(uv,20.)*.5;
	//c+=snow(uv,15.)*.8;
	c+=snow(uv,10.);
	c+=snow(uv,8.);
	c+=snow(uv,6.);
	c+=snow(uv,5.);
	finalColor=(vec3(c));
	return vec4(vec3(c),1);
    
  
}


vec4 stext(sampler2D txtx, vec2 fragCoord ,vec2 texres,vec2 shiftx,float valx)
{
	fragCoord.y=iResolution.y-fragCoord.y;
	vec2 tmpresxx=iResolution.xy;
    vec2 margin = vec2(0.,0.);//vec2(tmpresxx.y/tmpresxx.x>texres.y/texres.x?(-tmpresxx.y+tmpresxx.x*texres.y/texres.x):1.),
    vec2 Sres =tmpresxx.xy  -2.*margin,
         Tres = texres,
         ratio = Sres/Tres;
    vec2 U = fragCoord;
    U -= margin;
    
    U -= .5*Tres*max(vec2(ratio.x-ratio.y,ratio.y-ratio.x),0.);
    U /= Tres*min(ratio.x,ratio.y);  
    U+=shiftx;
    U*=valx;
    //U *= 2.;   
    //U -= 0.5;    
    //U.y -= 0.2;            
    
    vec4 bg2=fract(U)==U 
        ? texture(txtx,U)
        : vec4(0.);
    return bg2;
}



float sdfCircle(vec2 p) {
    return length(p) - 1.0;
}

float sdfBox(vec2 p) {
  vec2 d = abs(p) - vec2(1.0);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

vec4 sbldr(vec2 fragCoord){
	
	return stext(iChannel9,fragCoord,vec2(344,344),vec2(-01.0491,-0.22052),5.65);
	
	}
	
	
vec4 sbldr2(vec2 fragCoord){
	
	return stext(iChannel10,fragCoord,vec2(344,344),vec2(-0.60050491,-0.1822),4.05);
	
	}

float gbxx(vec2 fragCoord){
	float sdf=0.;
	vec2 uvbg = fragCoord / iResolution.xy ;
	vec2 uv = fragCoord / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
	sdf=max(sdf,(0.01+sdfCircle(uv / .1505 + vec2(03.60, -04.5092995)) * -.1505)*(1.-step(1.-1./8.,uvbg.y)));
	//float fxx=1.-2.*sbldr(fragCoord).r*(1.-step(1.-1./10.,uvbg.x));
	//sdf=max(sdf,min(fxx,(-0.01+0.8*sdfBox((uv / 0.155 + vec2(-08.20, -2.5))*rotate2d(0.15)) * -0.155)*(1.-step(1.-1./10.,uvbg.x))));
	
	//if(fxx>0.1) return smoothstep(-0.1, (iResolution.y/88.)/ iResolution.y, fxx);
	//sdf=max(sdf,fxx);
    //sdf=max(sdf,(0.01+sdfBox((uv / 0.215 + vec2(-02.0950, -1.7995))*rotate2d(-0.15)) * -0.215));
    
	return smoothstep(0.0, (iResolution.y/44.)/ iResolution.y, sdf);
}

float gbxx2(vec2 fragCoord){
	float sdf=0.;
	vec2 uvbg = fragCoord / iResolution.xy ;
	vec2 uv = fragCoord / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
	float fxx=1.-sbldr(fragCoord).a*(1.-step(1.-1./10.,uvbg.x));
	//sdf=max(sdf,min(fxx,(0.021+01.5*sdfBox((uv / 0.1355 + vec2(-09.3904920, -2.8))*rotate2d(0.15)) * -0.1355)*(1.-step(1.-1./10.,uvbg.x))));
	sdf=max(sdf,(0.01+sdfBox((uv / 0.1355 + vec2(-09.3904920, -2.8))*rotate2d(0.15)) * -0.1355)*(1.-step(1.-1./10.,uvbg.x)));
	
    
	return smoothstep(0.0, 3./ iResolution.y, sdf)*fxx;
}

float gbxx3(vec2 fragCoord){
	float sdf=0.;
	vec2 uvbg = fragCoord / iResolution.xy ;
	vec2 uv = fragCoord / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
	sdf=max(sdf,(-0.0251+sdfCircle(uv / .1505 + vec2(03.60, -04.5092995)) * -.1505)*(1.-step(1.-1./8.,uvbg.y)));
    
	return smoothstep(0.0, (iResolution.y/24.)/ iResolution.y, sdf);
}


float gbxx4(vec2 fragCoord){
	float sdf=0.;
	vec2 uvbg = fragCoord / iResolution.xy ;
	vec2 uv = fragCoord / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
	float fxx=1.-sbldr2(fragCoord).a*(1.-step(1.-1./10.,uvbg.x));
    //sdf=max(sdf,min(fxx,(0.01+sdfBox((uv / 0.215 + vec2(-02.0950, -1.7995))*rotate2d(-0.15)) * -0.215)));
    sdf=max(sdf,(-0.015+sdfBox((uv / 0.215 + vec2(-02.0950, -1.7995))*rotate2d(-0.15)) * -0.215));
    
	return smoothstep(0.0, (iResolution.y/44.)/ iResolution.y, sdf)*fxx;
}


float aspect_ratio;

vec3 rotateZ(vec3 _vector, float _a){
    return mat3(cos(_a), -sin(_a), 0.0, sin(_a), cos(_a), 0.0, 0.0, 0.0, 1.0) * _vector;
}

vec2 gfp;

vec4 get3dc(vec2 uvy){
	float sdf=0.;
	vec2 uvbg = gfp / iResolution.xy ;
	vec2 uv = gfp / iResolution.xy * 2.0 - 1.0;
	
	
    uv.x *= iResolution.x / iResolution.y;
	sdf=max(sdf,(0.01+sdfCircle(uv / .1505 + vec2(03.60, -04.5092995)) * -.1505)*(1.-step(1.-1./8.,uvbg.y)));
	sdf=smoothstep(0.0, 3./ iResolution.y, sdf);
	if(sdf>0.5) return texture(iChannel8,(uvy-vec2(0.245,0.4295))*2.43);
	return texture(iChannel6,uvy);
}


vec2 SampleSimplest(vec2 _pos){
    vec2 curentPos;
    vec2 uv;
    vec2 gradient = vec2(0.0);
    float offset = 0.002;
    float factor = 10.0;
    
    curentPos = _pos;
    uv = curentPos / iResolution.xy;
    uv.x *= aspect_ratio;
    gradient.x = get3dc( uv + vec2(-offset, 0.0)).r * factor - get3dc( uv + vec2(offset, 0.0)).r * factor;
    gradient.y = get3dc( uv + vec2(0.0, -offset)).r * factor - get3dc( uv + vec2(0.0, offset)).r * factor;

    return gradient;
}
// Sobel Filter || 3x3 || 5x5 || 7x7
// ---------------------------------
vec2 Sample3(vec2 _pos){
    vec2 curentPos;
    vec2 uv;
    float sample3[9];
    float filterX[9] = float[](3.0, 0.0, -3.0,
                                10.0, 0.0, -10.0,
                                3.0, 0.0, -3.0);
    
    float filterY[9] = float[]( -3.0, -10.0, -3.0,
                                 0.0, 0.0, 0.0,
                                3.0,10.0,3.0);
    
    int i = 0;
    for(float y = 1.0; y >= -1.0; y -= 1.0){
        for(float x = -1.0; x <= 1.0; x += 1.0){
            curentPos = _pos + vec2(x*1.0, y*1.0);
            uv = curentPos / iResolution.xy;
            uv.x *= aspect_ratio;
            sample3[i] = get3dc( uv).r;
            i++;
        }
    }
    
    vec2 gradient = vec2(0.0);
    for(int j = 0; j < 9; j++){
        gradient.x = gradient.x + filterX[j] * sample3[j];
        gradient.y = gradient.y + filterY[j] * sample3[j];
    }

    return gradient;
}

vec2 Sample5(vec2 _pos){
    vec2 curentPos;
    vec2 uv;
    float sample3[25];
    /*float filterX[25] = float[](2.0, 1.0, 0.0, -1.0, -2.0,
                                3.0, 2.0, 0.0, -2.0, -3.0,
                                4.0, 3.0, 0.0, -3.0, -4.0,
                                3.0, 2.0, 0.0, -2.0, -3.0,
                                2.0, 1.0, 0.0, -1.0, -2.0);
    
    float filterY[25] = float[](-2.0,-3.0,-4.0,-3.0,-2.0,
                                -1.0,-2.0,-3.0,-2.0,-1.0,
                                 0.0, 0.0, 0.0, 0.0, 0.0,
                                 1.0, 2.0, 3.0, 2.0, 1.0,
                                 2.0, 3.0, 4.0, 3.0, 2.0);*/
	float filterX[25] = float[](5.0,  4.0,  0.0, -4.0,  -5.0,
                                8.0,  10.0, 0.0, -10.0, -8.0,
                                10.0, 20.0, 0.0, -20.0, -10.0,
                                8.0,  10.0, 0.0, -10.0, -8.0,
                                5.0,  4.0,  0.0, -4.0,  -5.0);
    
    float filterY[25] = float[](-5.0,-8.0, -10.0,-8.0, -5.0,
                                -4.0,-10.0,-20.0,-10.0,-4.0,
                                 0.0, 0.0,  0.0,  0.0,  0.0,
                                 4.0, 10.0, 20.0, 10.0, 4.0,
                                 5.0, 8.0,  10.0, 8.0,  5.0);
    
    int i = 0;
    for(float y = 2.0; y >= -2.0; y -= 1.0){
        for(float x = -2.0; x <= 2.0; x += 1.0){
            curentPos = _pos + vec2(x, y);
            uv = curentPos / iResolution.xy;
            uv.x *= aspect_ratio;
            sample3[i] = get3dc( uv).r;
            i++;
        }
    }
    
    vec2 gradient = vec2(0.0);
    for(int j = 0; j < 25; j++){
        gradient.x = gradient.x + filterX[j] * sample3[j];
        gradient.y = gradient.y + filterY[j] * sample3[j];
    }

    return gradient;
}

vec2 Sample7(vec2 _pos){
    vec2 curentPos;
    vec2 uv;
    float sample3[49];
    float filterX[49] = float[](3.0, 2.0, 1.0, 0.0, -1.0, -2.0, -3.0,
                                4.0, 3.0, 2.0, 0.0, -2.0, -3.0, -4.0,
                                5.0, 4.0, 3.0, 0.0, -3.0, -4.0, -5.0,
                                6.0, 5.0, 4.0, 0.0, -4.0, -5.0, -6.0,
                                5.0, 4.0, 3.0, 0.0, -3.0, -4.0, -5.0,
                                4.0, 3.0, 2.0, 0.0, -2.0, -3.0, -4.0,
                                3.0, 2.0, 1.0, 0.0, -1.0, -2.0, -3.0);
    
    float filterY[49] = float[](-3.0,-4.0,-5.0,-6.0,-5.0,-4.0,-3.0,
                                -2.0,-3.0,-4.0,-5.0,-4.0,-3.0,-2.0,
                                -1.0,-2.0,-3.0,-4.0,-3.0,-2.0,-1.0,
                                 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                 1.0, 2.0, 3.0, 4.0, 3.0, 2.0, 1.0,
                                 2.0, 3.0, 4.0, 5.0, 4.0, 3.0, 2.0,
                                 3.0, 4.0, 5.0, 6.0, 5.0, 4.0, 3.0);
    
    int i = 0;
    for(float y = 3.0; y >= -3.0; y -= 1.0){
        for(float x = -3.0; x <= 3.0; x += 1.0){
            curentPos = _pos + vec2(x, y);
            uv = curentPos / iResolution.xy;
            uv.x *= aspect_ratio;
            sample3[i] = get3dc( uv).r;
            i++;
        }
    }
    
    vec2 gradient = vec2(0.0);
    for(int j = 0; j < 49; j++){
        gradient.x = gradient.x + filterX[j] * sample3[j];
        gradient.y = gradient.y + filterY[j] * sample3[j];
    }

    return gradient;
}
//------------------------------------------------------------------------

vec3 computeNormal(vec2 _pos){
    //Change filter here
    vec2 gradient = SampleSimplest(_pos);
    return normalize(vec3(gradient, 1.0 - length(gradient)));
}

vec4 mix3( vec2 fragCoord,vec2 ballPos,vec4 colx)
{
	vec4 fragColor;
	fragCoord*=2.725;
    aspect_ratio = iResolution.x / iResolution.y;
    vec3 lightPosition = vec3(0.0, 0.7, 0.13);
    lightPosition = rotateZ(vec3(ballPos*2.*2.725-1.,0.3), 0.);
    lightPosition.x*=aspect_ratio;
    
    vec3 fragPos3D = vec3((fragCoord - iResolution.xy / 2.0) / (iResolution.xy / 2.0), 0.0);
    fragPos3D.x *= aspect_ratio;
    
    vec2 uv = fragCoord / iResolution.xy;
    uv.x *= aspect_ratio;
    
    vec3 fragNormal = computeNormal(fragCoord);
    //fragColor = mix(get3dc( uv).rrra,colx,0.1);
    fragColor =get3dc( uv);
    
    float lightFactor = dot(normalize(lightPosition - fragPos3D), fragNormal);
    //fragColor =mix(fragColor*lightFactor,colx.bgra,0.1);
    fragColor*=lightFactor;
    
    //Uncomment this to see the normal map
    //fragColor = vec4(fragNormal, 1.0);
    return fragColor;
}


vec2 worldToUV(vec2 v) {
    v.x /= iResolution.x / iResolution.y;
    v = (v + 1.0) * 0.5;
    return v;
}




#define fac 1.
const int numLights = 1;

vec3 esnm2(in vec2 uv, in vec2 t)
{
	return normalize(vec3(
    	texture(iChannel5, vec2(uv.x + t.x*fac, uv.y)).x - texture(iChannel5, vec2(uv.x - t.x*fac, uv.y)).x,
    	texture(iChannel5, vec2(uv.x, uv.y + t.y*fac)).x - texture(iChannel5, vec2(uv.x, uv.y - t.y*fac)).x,
        1
    ));
}

struct material {
	vec3 ambient, diffuse, specular;
    float shininess;
};
    
struct light {
	vec3 o, ambient, diffuse;
    float power;
};
    
vec3 shade(in vec3 p, in material m0, in vec3 N, in light[numLights] l) {
    vec3 ambient = m0.ambient;
    vec3 diffuse = m0.diffuse;
    for(int i=0; i<numLights; ++i)
    {
        ambient += l[i].ambient;
        float d = distance(l[i].o, p);
        vec3 ldir = p-l[i].o;
        vec3 L = normalize(ldir);
        float NdotL = dot(N,L);
        diffuse += NdotL*l[i].diffuse*l[i].power/d;
    }
    return (ambient+diffuse)/float(numLights);
}

vec4 mixx( in vec2 fragCoord ,vec3 clx,vec2 ballPos)
{
	clx=min(vec3(1.),clx);
    vec2 uv = fragCoord/iResolution.xy;
    float aspect = iResolution.y/iResolution.x;
    
	vec2 p = uv*2.-1.;
    uv.y*=aspect;
    p.y*=aspect;
    
    vec2 mouse = worldToUV(ballPos);
    vec2 mousep = mouse*2.-1.;
    mousep.y *= aspect;
    
    light[numLights] l;
    l[0] = light(vec3(mousep, -.01), vec3(.075, .056, 0), clx.bgr/1.5, .1);
    //l[1] = light(vec3(mousep+0.3, -.02), vec3(.075, .056, 0), vec3(.3, .34, 0), .6);
    
    material m0 = material(vec3(0.), clx/1.68, vec3(.56, .54, .34), 10.0);
    
    vec3 N = esnm2(uv, 1./iResolution.xy);
    vec3 col = shade(vec3(p,0), m0, N, l);
    
    //vec3 col = N*.5+.5;
    
    return vec4(col,1);
}

vec4 gt7(vec2 fragCoord){

	return stext(iChannel7,fragCoord,vec2(34,87),vec2(1.32,-1.+.8715),9.);
	
	}

vec4 mainImage( in vec2 fragCoord )
{
	gfp=fragCoord;
    vec2 uv = fragCoord/iResolution.xy;
    vec2 uvbg=uv;
    vec4 fragColor;
    vec4 bgcol1 = texture(iChannel0,uvbg)*step(0.5,uvbg.x)+texture(iChannel0,vec2(1.-uvbg.x,uvbg.y))*(1.-step(0.5,uvbg.x));
    vec2 ballPos = texelFetch(iChannel3, ivec2(0), 0).xy;
    vec2 ballVel = texelFetch(iChannel3, ivec2(0), 0).zw;
    bgcol1*=step(1./8.,uvbg.y);
    uvbg.y=1.-uvbg.y;
    bgcol1+=(texture(iChannel0,uvbg)*step(0.5,uvbg.x)+texture(iChannel0,vec2(1.-uvbg.x,uvbg.y))*(1.-step(0.5,uvbg.x)))*step(1.-1./8.,uvbg.y);
    
    fragColor = bgcol1;
    sunColor=bgcol1.rrg*1.5;
    darkColor=bgcol1.bbr/1.5;
    if(antxtstate)fragColor=fragColor*(step(1.-1./8.,uvbg.y)<0.5&&1.-step(1./8.,uvbg.y)<0.5&&step(1.-1./10.,uvbg.x)<0.5&&1.-step(1./10.,uvbg.x)<0.5?0.:1.)+mixx(fragCoord,fragColor.rgb,ballPos)*(step(1.-1./8.,uvbg.y)<0.5&&1.-step(1./8.,uvbg.y)<0.5&&step(1.-1./10.,uvbg.x)<0.5&&1.-step(1./10.,uvbg.x)<0.5?1.:0.);
    float xz=step(1./10.,uv.x)*(1.-step(1.-1./7.85,uv.y))*(1.-step(1./8.,uv.x))*(step(1.-1./4.,uv.y));
    if(xz>0.5){
		if(antxtstate){
			fragColor=vec4(fragColor.g/0.2,fragColor.r/0.5,1.8954*max(fragColor.r,max(fragColor.b,fragColor.g)),1.)*gt7(fragCoord);
			}
		}
	if(antxtstate){
		float xf=gbxx(fragCoord);
		fragColor*=1.-vec4(xf);
		}
    float x;
    
    //return textureLod(iChannel12,uv*3.-vec2(1.45,1.7),0.0)*gbxx4(fragCoord);
    
    x=step(1./10.,worldToUV(ballPos).x)*(1.-step(1.-1./8.,worldToUV(ballPos).y))*(1.-step(1./8.,worldToUV(ballPos).x))*(step(1.-1./4.,worldToUV(ballPos).y));
    if(!antxtstate)fragColor = fragColor*(1.-xz)+vec4(.2,0.3,.8,1)*xz;
    fragColor = (fragColor*(step(1.-1./8.,uvbg.y)<0.5&&1.-step(1./8.,uvbg.y)<0.5&&step(1.-1./10.,uvbg.x)<0.5&&1.-step(1./10.,uvbg.x)<0.5?abs(texture(iChannel1,uv)):vec4(1.)))*(ffm?max(vec4(.30,0.58,.9,1.),(1.-texture(iChannel2,uv-vec2(0.,0.5)+(vec2(0.,1.)-worldToUV(ballPos+vec2(-1.0,0.)))))):vec4(1.));
    if(antxtstate)fragColor += mix3(fragCoord,worldToUV(ballPos),bgcol1)*(1.-(step(1.-1./8.,uvbg.y)<0.5&&1.-step(1./8.,uvbg.y)<0.5&&step(1.-1./10.,uvbg.x)<0.5&&1.-step(1./10.,uvbg.x)<0.5?min(1.-vec4(gbxx(fragCoord)),abs(texture(iChannel1,uv))):vec4(1.)))*(ffm?max(vec4(.30,0.58,.9,1.),(1.-texture(iChannel2,uv-vec2(0.,0.5)+(vec2(0.,1.)-worldToUV(ballPos+vec2(-1.0,0.)))))):vec4(1.));
    if(x>0.5)fragColor *=1.-textureLod(iChannel4,  (uv-vec2(-0.31,0.44)),0.0);
    if(antxtstate)fragColor+=fragColor.rrba*sbldr(fragCoord)*(1.-step(1.-1./10.,uv.x));
    if(antxtstate)fragColor+=fragColor.rrba*sbldr2(fragCoord);
    
    if(antxtstate){
	float fgh=gbxx2(fragCoord);
    if(fgh>0.) return misn(fragCoord)*fgh/1.25+fragColor*(1.-fgh)+misn(fragCoord)*fgh*fragColor*(fgh)/1.25;
    //return misn(fragCoord)*fgh/1.5+fragColor*(1.-fgh)+misn(fragCoord)*fgh*fragColor*(fgh)/1.5;
    }
    if(antxtstate){
		float fgh=gbxx4(fragCoord);
		if(fgh>0.){
			vec4 c=textureLod(iChannel12,uv*3.-vec2(1.45,1.7),0.0)*fgh;
		return fragColor*(1.-fgh)+c*0.8+c*bgcol1/2.;
		}
		}
    if(antxtstate){
    float fgh=gbxx3(fragCoord);
    if(fgh>0.)
    return fragColor*(1.-fgh)+micld(fragCoord)*fgh;}
    return fragColor;
}

void main() {
    glFragColor=mainImage(gl_FragCoord.xy);
}
