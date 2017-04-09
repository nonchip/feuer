#version 330 core

#define gradientCalc(from,to,step1,step2,a) mix(from,to,smoothstep(step1,step2,a))
#define gradStart(a) { float stepTMP=-1; vec4 valTMP; float aTMP=a;
#define gradStepv(st,v) valTMP=gradientCalc(valTMP,v,stepTMP,st,aTMP); stepTMP=st;
#define gradStep(st,x,y,z,w) gradStepv(st,vec4(x,y,z,w))
#define gradStop(var) var=valTMP; }

layout(location = 0) in vec2 iMeshPos;
layout(location = 1) in vec3 iPartPos;
layout(location = 2) in float iPartLft;

uniform mat4 modelViewProjectionMatrix;

out vec2 bMeshPos;
out vec4 bPartCol;

void main()
{
  bMeshPos=iMeshPos;

  gradStart(iPartLft);
  gradStep( 0.0, 1.0, 0.0, 0.0, 0.0 );
  gradStep( 0.2, 1.0, 0.0, 0.0, 1.0 );
  gradStep( 0.6, 1.0, 0.8, 0.0, 1.0 );
  gradStep( 1.0, 0.2, 0.3, 1.0, 1.0 );
  gradStop(bPartCol);

  gl_Position = modelViewProjectionMatrix * vec4(iPartPos+vec3(iMeshPos,0), 1);
}
