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

            sampler2D _AccumulationBuffer;
            float _AccumulationFrames;
            float _NumSamples;
            float _AntiAliasing;
            float _MaxBounces;

            fixed4 frag (v2f IN) : SV_Target
            {
                if(_NumSamples <= 0)
                {
                    return fixed4(1,0,1,1);
                }

                //init camera
                float3 viewPointLocal = float3(IN.uv - 0.5, 1) * _ViewParams.xyz;
                float3 viewPoint = mul(_CamLocalToWorld, float4(viewPointLocal, 1)).xyz;
                float3 camRight = _CamLocalToWorld._m00_m10_m20;
                float3 camUp = _CamLocalToWorld._m01_m11_m21;
                float aa = _AntiAliasing * 0.0001;

                //init rng
                uint2 pixCoords = IN.uv * _ScreenParams.xy;
                uint pixIndex = pixCoords.y * _ScreenParams.x + pixCoords.x;
                uint rngState = pixIndex + _AccumulationFrames * 719393;

                float4 col = 0;
                HitInfo hits[100];
                for(int i = 0; i < _NumSamples; i++)
                {
                    Ray ray;
                    ray.origin = _WorldSpaceCameraPos;
                    float3 jitteredViewPoint = viewPoint + camRight * (random(rngState) - 0.5) * aa + camUp * (random(rngState) - 0.5) * aa;
                    ray.direction = normalize(jitteredViewPoint - ray.origin);
                    uint lightIndex = 999999;
                    for(int bounce = 0; bounce <= _MaxBounces; bounce++)
                    {
                        HitInfo hit;
                        rayTrace(ray, hit);
                        hits[bounce] = hit;
                        if(hit.distance < 0)
                        {
                            lightIndex = bounce;
                            break;
                        }
                        else
                        {
                            ray.origin = hit.position;
                            //ray.direction = getRandomVectorInHemisphere(hit.normal, rngState);
                            ray.direction = getCosineWeightedDiffuseBounceDirection(hit.normal, rngState);
                            //ray.direction = reflect(ray.direction, hit.normal);
                        }
                    }
                    if(lightIndex == 999999)
                    {
                        //col.rgb += float3(9,0,9);
                        //col.rgb += float3(0,1,0);
                    }
                    else
                    {
                        float3 curCol = hits[lightIndex].col;
                        for(int j = lightIndex - 1; j >= 0; j--)
                        {
                            HitInfo hit = hits[j];
                            //curCol = evaluateBrdf(hit.rayIn, hit.rayOut, hit.normal, curCol, hit.material);
                            curCol = simpleBrdf(curCol, hit.col);
                        }
                        //col.rgb += lightIndex / _MaxBounces;
                        //col.rgb += float3(1,0,0);
                        col.rgb += curCol;
                    }
                }
                col.rgb /= _NumSamples;

                float4 prevColor = tex2D(_AccumulationBuffer, IN.uv);
                prevColor.rgb += col.rgb / _AccumulationFrames;
                //return _AccumulationFrames / 1000;

                return prevColor;
            }
            ENDCG
        }
    }
}
