#version 330 core

in vec2 bMeshPos;
in vec4 bPartCol;

layout(location = 0) out vec4 oFragCol;

void main(){
  oFragCol  = bPartCol;
  oFragCol *= 1-length(bMeshPos);
}
