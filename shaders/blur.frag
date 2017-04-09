#version 330 core

uniform sampler2DRect tex;

in vec2 fragTexCoord;

out vec4 fragColor;

void main()
{
  //fragColor = texture(tex, fragTexCoord);
  fragColor=vec4(1,0,0,1);
}
