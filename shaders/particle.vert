#version 330 core

#define gradientCalc(from,to,step1,step2,a) mix(from,to,smoothstep(step1,step2,a))
#define gradStart(a) \
  { \
  float stepTMP=-1; \
  vec4 valTMP; \
  float aTMP=a;
#define gradStep(st,x,y,z,w) \
  valTMP=gradientCalc(valTMP,vec4(x,y,z,w),stepTMP,st,aTMP); \
  stepTMP=st;
#define gradStepv(st,v) \
  valTMP=gradientCalc(valTMP,v,stepTMP,st,aTMP); \
  stepTMP=st;
#define gradStop(var) \
  var=valTMP; \
  }

layout(location = 0) in vec2 iMeshPos;
layout(location = 1) in vec3 iPartPos;
layout(location = 2) in float iPartLft;

uniform mat4 modelViewProjectionMatrix;

out vec2 bMeshPos;
out vec4 bPartCol;

void main()
{
  bMeshPos=iMeshPos;

  /*bPartCol=vec4(
    1.0-(iPartLft/2.0),
    iPartLft*.8,
    clamp(4*(iPartLft-.6),0,1),
    iPartLft
  );*/
  /*if(iPartLft>.5)
    bPartCol=mix(
      vec4(1,.5,0,1),
      vec4(.3,.3,1,1),
      (iPartLft-.5)*2
    );
  else
    bPartCol=mix(
      vec4(1,0,0,0),
      vec4(1,.5,0,1),
      iPartLft*2
    );*/

  /*bPartCol = gradientCalc( bPartCol, vec4( 0.3, 0.4, 1.0, 1.0 ),  -1, 0.0, iPartLft );
  bPartCol = gradientCalc( bPartCol, vec4( 1.0, 0.8, 0.0, 1.0 ), 0.0, 0.2, iPartLft );
  bPartCol = gradientCalc( bPartCol, vec4( 1.0, 0.0, 0.0, 1.0 ), 0.2, 0.6, iPartLft );
  bPartCol = gradientCalc( bPartCol, vec4( 1.0, 0.0, 0.0, 0.0 ), 0.6, 1.0, iPartLft );*/

  gradStart(iPartLft);
  gradStep( 0.0, 1.0, 0.0, 0.0, 0.0 );
  gradStep( 0.2, 1.0, 0.0, 0.0, 1.0 );
  gradStep( 0.6, 1.0, 0.8, 0.0, 1.0 );
  gradStep( 1.0, 0.2, 0.3, 1.0, 1.0 );
  gradStop(bPartCol);

  gl_Position = modelViewProjectionMatrix * vec4(iPartPos+vec3(iMeshPos,0), 1);
}
