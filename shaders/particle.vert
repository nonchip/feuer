#version 330 core

layout(location = 0) in vec2 iMeshPos;
layout(location = 1) in vec3 iPartPos;
layout(location = 2) in float iPartLft;

uniform mat4 modelViewProjectionMatrix;

out vec2 bMeshPos;
out vec4 bPartCol;

void main()
{
  bMeshPos=iMeshPos;

  bPartCol=vec4(
    1.0-(iPartLft/2.0),
    iPartLft/2.0,
    clamp(4*(iPartLft-.6),0,1),
    iPartLft
  );
  gl_Position = modelViewProjectionMatrix * vec4(iPartPos+vec3(iMeshPos,0), 1);
}
