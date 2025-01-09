Shader "Hidden/PathTracer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/Shaders/PathTrace.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed4 col = tex2D(_MainTex, i.uv);

                float3 viewPointLocal = float3(i.uv - 0.5, 1) * _ViewParams.xyz;
                float3 viewPoint = mul(_CamLocalToWorld, float4(viewPointLocal, 1)).xyz;
                float3 camRight = _CamLocalToWorld._m00_m10_m20;
                float3 camUp = _CamLocalToWorld._m01_m11_m21;

                Ray ray;
                ray.origin = _WorldSpaceCameraPos;
                ray.direction = normalize(viewPoint - ray.origin);

                float minT = 1000000;
                HitInfo hit;
                for(int i = 0; i < _NumSpheres; i++)
                {
                    float3 spherePos = float3(_SphereData[i * _SphereStride + 0], _SphereData[i * _SphereStride + 1], _SphereData[i * _SphereStride + 2]);
                    float2 hitTest = sphIntersect(ray.origin, ray.direction, spherePos, _SphereData[i * _SphereStride + 3]);
                    if(hitTest.y >= 0 && hitTest.x > 0)
                    {
                        minT = min(minT, hitTest.x);
                        hit.distance = hitTest.x;
                        hit.sphereIndex = i;
                    }
                }
                if(minT < 1000000)
                {
                    float3 spherePos = float3(_SphereData[hit.sphereIndex * _SphereStride + 0],
                        _SphereData[hit.sphereIndex * _SphereStride + 1], _SphereData[hit.sphereIndex * _SphereStride + 2]);
                    float3 hitPoint = ray.origin + ray.direction * hit.distance;
                    float3 normal = normalize(hitPoint - spherePos);
                    int matIndex = _SphereData[hit.sphereIndex * _SphereStride + 4];
                    Material m;
                    m.albedo = float3(_MaterialData[matIndex * _MaterialStride + 0], _MaterialData[matIndex * _MaterialStride + 1],
                        _MaterialData[matIndex * _MaterialStride + 2]);
                    return float4(m.albedo, 1);
                    
                    //return float4(normal, 1);
                }

                
                return fixed4(ray.direction, 1);


                //return col;
            }
            ENDCG
        }
    }
}
