/* Copyright: Josefine Klintberg
   Procedural ocean shader
*/

Shader "Custom/Water"
{
	Properties // Interactions enabled for user
	{
		//Tessellation
		//[Header(Tessellation Amount)]
		//_Tess("Tessellation", Range(1,32)) = 4

		// Water 
		[Header(General)]
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Opacity("Opacity", Range(0.6,1)) = 0.8

		[Header(Colors)]
		_ColorMain("Color Depth", Color) = (0.2,0.2,0.5,0.6)
		_ColorDetail("Color Surface", Color) = (0,0,1,0.6)

		//Shoreline
		[Header(Shoreline)]
		_InvFade("Foam Amount", Range(0.2, 0.01)) = 0.05
		_FadeLimit("Foam Edge Hardness", Range(1, 0.5)) = 0.8

		//Foam
		[Header(Wave Foam)]
		_FoamIntens("Foam Intensity", Range(0.01, 0.2)) = 0.06

		////Large waves - speed and scale
		//[Header(Large waves)]

		//Wind
		[Header(Wind)]
		_WindDir("Wind direction (2D)", Vector) = (1,0,0,0)
		_WindStrength("Wind Strength", Range(0, 2)) = 0.5
		_WindInt("Wind Intensity", Range(3, 0.3)) = 0.3

		//Small waves
		[Header(Small Waves)]
		_RippleHeight("Ripple Height", Range(0, 0.3)) = 0.1
		_RippleFreq("Ripple Frequency", Range(2, 0.6)) = 1


	}

	CGINCLUDE
	#include "UnityCG.cginc" 	   // for ComputeScreenPos()
	#include "snoise.cginc"		
	#include "noise.cginc"		//Perlin noise
	#include "voronoise.cginc"
	ENDCG


	SubShader
	{
		Tags {"WaterMode" = "Refractive" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		LOD 200
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off


		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		//#pragma surface surf Standard fullforwardshadows vertex:vert addshadow tessellate:tessFixed alpha:fade nolightmap
		#pragma  surface surf Standard vertex:vert alpha:fade nolightmap fullforwardshadows 

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0


		//Triangle wave modulation
		float3 FlowUVW(float2 uv, float2 flowVec, float time) {
			float progress = frac(time);
			float3 uvw;
			uvw.xy = uv - flowVec * progress;
			//uvw.z = 1; //Seesaw wave
			uvw.z = 1 - abs(1 - 2 * progress); //Triangle wave
			return uvw;
		}

		//Tessellation
		float _Tess;

		float4 tessFixed()
		{
			return _Tess;
		}


		struct Input
		{
			float3 viewDir;
			float4 screenPos;
			float2 uv : TEXCOORD1;
			float eyeDepth;
			float3 normal : NORMAL;
			float4 pos : POSITION;
			float3 worldPos;
			float4 screenPosition : TEXCOORD2;
		};


		struct vertexInput
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
		};

		struct vertexOutput
		{
			float4 pos : SV_POSITION;
			float3 normal : NORMAL;
			float3 worldPos;
			float3 viewDir;
			float4 screenPosition : TEXCOORD2;
		};


		sampler2D_float _CameraDepthTexture;
		float4 _CameraDepthTexture_TexelSize;

		float _FadeLimit;
		float _InvFade;


		half _Glossiness;
		half _Metallic;
		fixed4 _ColorMain, _ColorDetail;
		float  _WindStrength, _RippleHeight, _RippleFreq, _Opacity, _WindInt, _FoamHeight, _FoamIntens;
		float2 _Direction, _WindDir, _FoamGradient;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		//Add series of octaves of Perlin Noise together 
		float multiOctavePerlinNoise2D(float x, float y, int octaves)
		{
			float v = 0.0f;
			float scale = 2.0f; //Higher scale, more detail = influence of wind
			float weight = 1.0f;
			float weightTotal = 0.0f;
			for (int i = 0; i < octaves; i++)
			{
				v += cnoise(float3(x * scale, y * scale, _Time.y/4)) * weight;
				weightTotal += weight;
				scale *= 0.5f;
				weight *= 2.0f;
			}
			return v / weightTotal;
		}

		//
		float3 GerstnerWave(float2 dir, float3 p, inout float3 tangent, inout float3 binormal, float steep, float wavelen) {
			float steepness = steep*_WindStrength; 
			float wavelength = wavelen * _WindInt;
			float waveNumb = 2 * UNITY_PI / wavelength;
			float c = sqrt(9.8 / waveNumb);
			float2 d = normalize(dir.xy);
			float f = waveNumb * (dot(d, p.xz) - c * _Time.y);
			float a = steepness / waveNumb;

			tangent += float3(
				-d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);
			binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				-d.y * d.y * (steepness * sin(f))
				);
			return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
		}

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float3 gridPoint = v.vertex.xyz;
			float3 tangent = float3(1, 0, 0);
			float3 binormal = float3(0, 0, 1);
			float3 temp = gridPoint;
			if (_WindStrength != 0) {
				temp += GerstnerWave(_WindDir, gridPoint, tangent, binormal, 0.1, 5);
				temp += GerstnerWave(float2(_WindDir.x, abs(_WindDir.y - 0.4)), gridPoint, tangent, binormal, 0.1, 10);
				if (_WindStrength < 1.0) {
					temp += GerstnerWave(float2(_WindDir.x, abs(_WindDir.y + 0.3)), gridPoint, tangent, binormal, 0.15, 5);
				}
			}

			float3 normal = normalize(cross(binormal, tangent));

			v.vertex.xyz = temp;
			v.normal = normal;
			float3 worldPos = mul(unity_ObjectToWorld, float4(temp.xyz, 1.0)).xyz;
			
			//Endless ocean
			if (distance(_WorldSpaceCameraPos, worldPos) > 800) {
			//v.vertex.y += 10;
			}

			float displacement = (multiOctavePerlinNoise2D(worldPos[0], worldPos[2], 5*_RippleFreq) + multiOctavePerlinNoise2D(0.3*worldPos[0], worldPos[2], 7*_RippleFreq));

			//If no wind, plain ocean
			if (_WindStrength == 0) {
				_RippleHeight = 0.01;
			}

			v.vertex.xyz += v.normal *_RippleHeight * displacement;

			o.screenPos = ComputeScreenPos(v.vertex);

			o.pos = v.vertex;

			o.normal = v.normal;

			COMPUTE_EYEDEPTH(o.eyeDepth); //For shoreline depth
		}
	

		void surf(Input IN, inout SurfaceOutputStandard o) 
		{
			//Ripple effect
			float noise = (multiOctavePerlinNoise2D(IN.worldPos[0], IN.worldPos[2], 5 * _RippleFreq) + multiOctavePerlinNoise2D(0.3*IN.worldPos[0], IN.worldPos[2], 7 * _RippleFreq));
			o.Normal += IN.normal*_RippleHeight*noise;

			//Fresnel effect
			float3 viewDir = normalize(_WorldSpaceCameraPos - IN.screenPos);
			half rim = 1.0 - saturate(dot(normalize(viewDir), IN.normal));
			half4 newCol = half4(_ColorDetail * _ColorMain);
			newCol.rgb = lerp(newCol.rgb, newCol.rgb * _ColorMain.rgb, pow(_ColorDetail, 10));
			o.Albedo = newCol * _ColorDetail *0.05 + (_ColorMain*_ColorDetail);

			//if (distance(_WorldSpaceCameraPos, IN.worldPos) > 800) {
			//	//o.Albedo = (1, 1, 1, 1);
			//}

			//Shoreline calculations
			float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
			float sceneZ = LinearEyeDepth(rawZ);
			float partZ = IN.eyeDepth;

			float fade = 1.0;
			if (rawZ > 0.0) // Make sure the depth texture exists
				fade = abs(saturate(_InvFade * (sceneZ - partZ)));
			
			o.Alpha = 1;
			if (fade < _FadeLimit)
				o.Albedo += (0, 0, 0, 0) * fade +_ColorDetail * (1 - fade);


			//Wave foam
			float foamdis = multiOctavePerlinNoise2D(IN.worldPos[0], IN.worldPos[2], 2);
			float surfaceNoise = foamdis > 0.8 ? 1 : 0;
			float3 gradient = (1, 1, 1)*IN.pos.y;
			gradient += surfaceNoise;
			if (distance(gradient, o.Albedo) > 0.01 && IN.pos.y > 0) {
				o.Albedo += _FoamIntens*gradient;
			}

			o.Metallic = 0.7;
			o.Smoothness = _Glossiness;
			o.Alpha = _Opacity;// c.a;
		}


		ENDCG
	}
	FallBack "Diffuse"
}
