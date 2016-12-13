#version 330 core

layout(location = 0) in vec2 iMeshPos;
layout(location = 1) in vec3 iPartPos;
layout(location = 2) in vec4 iPartCol;

uniform mat4 modelViewProjectionMatrix;

out vec2 bMeshPos;
out vec4 bPartCol;

void main()
{
  bMeshPos=iMeshPos;
  bPartCol=iPartCol;
  gl_Position = modelViewProjectionMatrix * vec4(iPartPos+vec3(iMeshPos,0), 1);
}
