//	<https://www.shadertoy.com/view/Xd23Dh>
//	by inigo quilez <http://iquilezles.org/www/articles/voronoise/voronoise.htm>
//

float3 hash3( float2 p ){
    float3 q = float3( dot(p,float2(127.1,311.7)), 
				   dot(p,float2(269.5,183.3)), 
				   dot(p,float2(419.2,371.9)) );
	return frac(sin(q)*43758.5453);
}

float iqnoise( in float2 x, float u, float v ){
    float2 p = floor(x);
    float2 f = frac(x);
		
	float k = 1.0+63.0*pow(1.0-v,4.0);
	
	float va = 0.0;
	float wt = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        float2 g = float2( float(i),float(j) );
		float3 o = hash3( p + g )*float3(u,u,1.0);
		float2 r = g - f + o.xy;
		float d = dot(r,r);
		float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
		va += o.z*ww;
		wt += ww;
    }
	
    return va/wt;
}
