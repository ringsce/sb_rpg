#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoords;
layout (location = 3) in vec3 aTangent;

out VS_OUT {
    vec3 FragPos;
    vec2 TexCoords;
    vec3 TangentViewPos;
    vec3 TangentFragPos;
} vs_out;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 viewPos;

void main() {
    vec3 T = normalize(aTangent);
    vec3 N = normalize(aNormal);
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);
    mat3 TBN = mat3(T, B, N);

    vec4 fragPos = model * vec4(aPos, 1.0);
    vs_out.FragPos = fragPos.xyz;
    vs_out.TexCoords = aTexCoords;
    vs_out.TangentViewPos = TBN * viewPos;
    vs_out.TangentFragPos = TBN * fragPos.xyz;

    gl_Position = projection * view * fragPos;
}

