// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Water_unlit"
{
    Properties //Interaction for user
    {
		//Texture coordinates
		 _MainTex("Albedo (RGB)", 2D) = "white" {}

		// Water 
		_Smoothness("Smoothness", Float) = 1.0
		_ColorMain("Color", Color) = (0.2,0.2,0.5,0.6)
		_ColorDetail("Color Detail", Color) = (0,0,1,0.6)

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
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

			//Generate a pseudorandom number
			float random(float2 uv)
			{
				return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
			}

			// Simplex 2D noise
			float3 permute(float3 x) { return fmod(((x*34.0) + 1.0)*x, 289.0); }

			float snoise(float2 v) {
			  const float4 C = float4(0.211324865405187, 0.366025403784439,
					   -0.577350269189626, 0.024390243902439);
			  float2 i = floor(v + dot(v, C.yy));
			  float2 x0 = v - i + dot(i, C.xx);
			  float2 i1;
			  i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
			  float4 x12 = x0.xyxy + C.xxzz;
			  x12.xy -= i1;
			  i = fmod(i, 289.0);
			  float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0))
			  + i.x + float3(0.0, i1.x, 1.0));
			  float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy),
				dot(x12.zw,x12.zw)), 0.0);
			  m = m * m;
			  m = m * m;
			  float3 x = 2.0 * frac(p * C.www) - 1.0;
			  float3 h = abs(x) - 0.5;
			  float3 ox = floor(x + 0.5);
			  float3 a0 = x - ox;
			  m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h * h);
			  float3 g;
			  g.x = a0.x  * x0.x + h.x  * x0.y;
			  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			  return 130.0 * dot(m, g);
			}

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed4 _ColorMain, _ColorDetail;

			//Vertex shader
            v2f vert (appdata v)
            {
                v2f o;
				// transform position to clip space
				// (multiply with model*view*projection matrix)

				//Simple handling of vertex
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				//o.vertex = UnityObjectToClipPos(v.vertex + snoise(v.uv));   
				//o.uv = v.uv + snoise(v.uv);

                return o;
            }

			//Fragment shader
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 base = _ColorMain;
			    fixed4 detail = _ColorMain + snoise(i.uv*5);
                return base*detail;
            }
            ENDCG
        }
    }
}
