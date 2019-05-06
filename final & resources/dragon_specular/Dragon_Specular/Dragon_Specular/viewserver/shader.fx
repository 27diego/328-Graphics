//--------------------------------------------------------------------------------------
// File: Tutorial022.fx
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------
Texture2D tex : register(t0);
Texture2D tex2 : register(t1);
SamplerState samLinear : register(s0);

cbuffer VS_CONSTANT_BUFFER : register(b0)
{
	float mx;
	float my;
	float scale;
	float trans;
	float div_tex_x;	//dividing of the texture coordinates in x
	float div_tex_y;	//dividing of the texture coordinates in x
	float slice_x;		//which if the 4x4 images
	float slice_y;		//which if the 4x4 images
	float4 vLightDir[2];
	float4 vLightColor[2];
	matrix world;
	matrix view;
	matrix projection;
	float4 campos;
};

//struct float4
//	{
//	float r, g, b, a;//same
//	float x, y, z, w;
//	}
struct SimpleVertex
{
	float4 Pos : POSITION;
	float2 Tex : TEXCOORD0;
	float3 Norm : NORMAL;
};

struct PS_INPUT
{
	float4 Pos : SV_POSITION;
	float4 WorldPos : POSITION1;
	float2 Tex : TEXCOORD0;
	float3 Norm : NORMAL;
};
//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
PS_INPUT VShader(SimpleVertex input)
{
	PS_INPUT output;
	float4 pos = input.Pos;

	pos = mul(world, pos);
	output.WorldPos = pos;
	pos = mul(view, pos);
	pos = mul(projection, pos);

	output.Norm = normalize(mul(world, float4(input.Norm, 0)).xyz);

	output.Pos = pos;
	output.Tex = input.Tex;
	return output;
}


//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
//normal pixel shader
float4 PS(PS_INPUT input) : SV_Target
{
	float4 color = tex.Sample(samLinear, input.Tex);
	float ambient = 0.5;

	float3 light_pos = float3(10, 20, 15);
	float3 light_dir = normalize(light_pos - input.WorldPos.xyz);
	float diffuse = saturate(dot(light_dir, normalize(input.Norm)));

	float3 reflected = reflect(-light_dir, normalize(input.Norm));
	float3 cam_pos = float3(0, 0, 0);
	float3 cam_dir = normalize(cam_pos - input.WorldPos.xyz);
	float specular = pow(saturate(dot(cam_dir, reflected)), 20);

	color.rgb = (ambient + diffuse) * color.rgb + specular;
	return color;
}
//shader for the sky sphere
float4 PSsky(PS_INPUT input) : SV_Target
{
	//return float4(input.Tex.y,input.Tex.y,0,1);
	float4 color = tex.Sample(samLinear, input.Tex);
	color.a = 1;
	return color;
}

float4 PSCube(PS_INPUT input) : SV_Target
{
	float4 color = input.Pos / 1000.0;
	color.r = color.r > 0.5f ? color.r - 0.5 : 0.0;
	color.g = color.g > 0.5f ? color.g - 0.5 : 0.0;
	color.b = color.b > 0.5f ? color.b - 0.5 : 0.0;
	
	//do NdotL lighting for 2 lights
	for (int i = 0; i < 2; i++)
	{
		color += saturate(dot((float3)vLightDir[i], input.Norm)*vLightColor[i]);
	}
	color.a = 1;
	return color;
}
