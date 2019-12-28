// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Water"
{
	Properties // Interactions enabled for user
	{
		_Tess("Tessellation", Range(1,32)) = 4

		//Texture coordinates
		_MainTex("Albedo (RGB)", 2D) = "white" {}

		// Water 
		_Smoothness("Smoothness", Float) = 1.0
		[NoScaleOffset] _FlowMap("Flow map", 2D) = "black" {}
		[NoScaleOffset] _NormalMap("Normal map", 2D) = "bump" {}
		_Displacement("Displacement Amount", Range(1,100)) = 10

		[Header(Colors)]
		_ColorMain("Color", Color) = (0.2,0.2,0.5,0.6)
		_ColorDetail("Color Detail", Color) = (0,0,1,0.6)

		//Foam
		_FoamDist("Foam Distance", Range(0,1)) = 1.0
		_FoamStrength("Foam Strength", Range(0,1)) = 1.0

		//Large waves - speed and scale
		[Header(Large waves)]
		_Wavelength("Wavelength", Range(10,50)) = 10
	    _Steepness("Wave Height", Range(0, 0.8)) = 0.5
	    _Direction("Wind direction (2D)", Vector) = (1,0,0,0)

		//Normals - strength and possible normal map/bump map and normal speed

		//Depth
		_DepthFactor("Depth Factor", Float) = 1.0
		_DepthCol("Depth Color", Color) = (0,0,0,1)

		//Small waves
		_WaveSpeed("Wave Speed", Float) = 1.0
		_WaveAmplitude("Wave Amplitude", Float) = 1.0

		//Glossiness and metallic
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}

	CGINCLUDE
	//#include "UnityCG.cginc" 	   // for ComputeScreenPos()
	//#include "UnityLightingCommon.cginc" // for _LightColor0
	#include "snoise.cginc"
	#include "noise.cginc"
	#include "voronoise.cginc"
	ENDCG


	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow tessellate:tessFixed 

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0


		float2 FlowUV(float2 uv, float2 flowVec, float time) {
			float progress = frac(time);
			return uv - flowVec * progress;
		}

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

		sampler2D _MainTex, _NormalMap, _FlowMap;

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 viewDir;
			float4 screenPos;
			float eyeDepth;
			float3 normal : NORMAL;
			float4 vertex : POSITION;
		};

		struct vertexInput
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float3 texCoord : TEXCOORD0;
		};

		struct vertexOutput
		{
			float4 pos : SV_POSITION;
			float3 normal : NORMAL;
			float4 grabPos : TEXCOORD0;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _ColorMain, _ColorDetail;
		float _Wavelength, _Steepness, _Displacement;
		float2 _Direction;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)


		// Vertex shader
		void vert(inout appdata_full v) {
			//Simple handling of vertex
			float3 temp = v.vertex.xyz;
			float waveNumb = 2 * UNITY_PI / _Wavelength;
			float c = sqrt(9.81 / waveNumb); //Wave speed, sqrt(gravity/wavenumber)
			float2 dir = normalize(_Direction);
			float f = waveNumb * (dot(dir, v.vertex.xz) - c* _Time.y);
			float a = _Steepness / waveNumb; //Prevent looping for Gerstner waves

			//Changing the vertices to appear like waves
			temp.x += a * cos(f);
			temp.y = a * sin(f); //Gerstner waves

			//Sinus waves
			//temp.y = _Amplitude * sin(k*(v.vertex.x - _Speed * _Time.y)); 

			//Compute new normals and tangent so the light reflects according to new positions for vertices
			//float3 tangent = normalize(float3(1, k * _Amplitude * cos(f), 0)); //Tangents for sinus wave
			float3 tangent = normalize(float3(1 - _Steepness * sin(f), _Steepness * cos(f), 0)) ; //Tangents Gerstner waves
			float3 normal = float3(-tangent.y, tangent.x, 0);

			float displacement = tex2Dlod(_NormalMap, v.texcoord);
			float displacement2 = tex2Dlod(_FlowMap, v.texcoord);

			float voronoise1 = 0.05*iqnoise(temp.xz*10, v.texcoord.x, v.texcoord.y);

			v.vertex.xyz = temp;
			v.normal = normalize(normal);// +snoise(v.vertex);
			v.vertex.xyz += v.normal*10*voronoise1*0.4*(1-abs(cnoise(float3(v.vertex.xyz)*_Time.y/3000)));// + 0.2*snoise(v.vertex.xz));// *(1 - snoise(float2(v.vertex.xy)));// *_Displacement;// *displacement*displacement2;

		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			//float3 normalA = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex.xy));// *IN.uv_MainTex.y;
			//o.Normal = 100*normalize(normalA);

			float2 flowVec = tex2D(_MainTex, IN.uv_MainTex).rg * 2 - 1;
			float3 uvw = FlowUVW(IN.uv_MainTex, flowVec, 1);

			//fixed4 c = (texA + texB) * _ColorMain;
			float2 uv = FlowUV(IN.uv_MainTex, flowVec, 1);

			//fixed4 c = tex2D(_MainTex, uv) * _ColorMain;// *_ColorMain * 3 * _ColorDetail;
			o.Albedo = _ColorMain+0.05*snoise(IN.uv_MainTex*200)*_ColorDetail ;//c.rgb;
			//o.Albedo = float3(flowVec, 0); +_ColorMain;
			//o.Normal += tex2D(_MainTex, IN.uv_MainTex);
			//o.Normal += snoise(IN.uv_MainTex*100);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = 0.8;// c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
