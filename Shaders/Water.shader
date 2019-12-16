Shader "Custom/Water"
{
	Properties // Interactions enabled for user
	{
		//Texture coordinates
		_MainTex("Albedo (RGB)", 2D) = "white" {}

		// Water 
		_Smoothness("Smoothness", Float) = 1.0
		_ColorMain("Color", Color) = (0.2,0.2,0.5,1)
		_ColorDetail("Color Detail", Color) = (0,0,1,1)

		//Foam
		_FoamDist("Foam Distance", Range(0,1)) = 1.0
		_FoamStrength("Foam Strength", Range(0,1)) = 1.0

		//Waves - speed and scale

		//Normals - strength and possible normal map/bump map and normal speed

		//Depth
		_DepthFactor("Depth Factor", Float) = 1.0
		_DepthCol("Depth Color", Color) = (0,0,0,1)

		//Waves
		_WaveSpeed("Wave Speed", Float) = 1.0
		_WaveAmplitude("Wave Amplitude", Float) = 1.0

		//Glossiness and metallic
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}

	CGINCLUDE
	#include "UnityCG.cginc" 	   // for ComputeScreenPos()
	#include "UnityLightingCommon.cginc" // for _LightColor0
	ENDCG


	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0


		sampler2D _MainTex;

		struct Input
		{
			float2 uv_MainTex;
		};

		//struct Output
		//{

		//};

		half _Glossiness;
		half _Metallic;
		fixed4 _ColorMain, _ColorDetail;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
		// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _ColorMain * _ColorDetail;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
