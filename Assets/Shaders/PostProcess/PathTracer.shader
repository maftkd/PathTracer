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
            uint _AccumulationFrames;
            float _NumSamples;
            float _AntiAliasing;
            float _MaxBounces;
            float _ProgressiveRendering;
            float _DofBlur;

            fixed4 frag (v2f IN) : SV_Target
            {
                if(_NumSamples <= 0)
                {
                    return fixed4(1,0,0,1);
                }
                
                //init camera
                float3 viewPointLocal = float3(IN.uv - 0.5, 1) * _ViewParams.xyz;
                float3 viewPoint = mul(_CamLocalToWorld, float4(viewPointLocal, 1)).xyz;
                float3 camRight = _CamLocalToWorld._m00_m10_m20;
                float3 camUp = _CamLocalToWorld._m01_m11_m21;
                float aa = _AntiAliasing * 0.01;
                float dofBlur = _DofBlur;

                //init rng
                uint2 pixCoords = IN.uv * _ScreenParams.xy;
                uint pixIndex = pixCoords.y * _ScreenParams.x + pixCoords.x;
                uint rngState = pixIndex + _AccumulationFrames * 719393;

                float4 col = 0;
                HitInfo hits[100];
                BounceInfo bounces[100];
                for(int i = 0; i < _NumSamples; i++)
                {
                    Ray ray;
                    float3 jitteredOrigin = jitterPoint(_WorldSpaceCameraPos, camRight, camUp, dofBlur, rngState);
                    ray.origin = jitteredOrigin;
                    float3 jitteredViewPoint = jitterPoint(viewPoint, camRight, camUp, aa, rngState);
                    ray.direction = normalize(jitteredViewPoint - ray.origin);
                    uint lightIndex = 999999;
                    for(int j = 0; j <= _MaxBounces; j++)
                    {
                        HitInfo hit;
                        rayTrace(ray, hit);
                        hits[j] = hit;
                        if(hit.hitLight > 0.5)
                        {
                            lightIndex = j;
                            break;
                        }
                        else
                        {
                            BounceInfo bounce;
                            bounce.wo = -ray.direction;
                            ray.origin = hit.position + hit.normal * 0.0001;
                            float roughness = hitRoughness(hit);
                            float metallic = hitMetallic(hit);
                            //ray.direction = hit.normal;
                            //ray.direction = getRandomVectorInHemisphere(hit.normal, rngState);
                            //ray.direction = getCosineWeightedDiffuseBounceDirection(hit.normal, rngState);

                            //bounce.pdf = 0.5 * (1.0 / UNITY_PI + materialPdf(roughness, hit.normal, bounce.wo, halfway));
                            float3 diffuseDir = getCosineWeightedDiffuseBounceDirection(hit.normal, rngState);
                            float3 specDir = reflect(ray.direction, hit.normal);
                            bool isSpecularBounce = random(rngState) < metallic;
                            ray.direction = lerp(diffuseDir, specDir, (1-roughness) * isSpecularBounce);

                            bounce.isSpecular = isSpecularBounce;
                            bounce.wi = ray.direction;
                            
                            float3 halfway = normalize(bounce.wo + bounce.wi);
                            bounces[j] = bounce;
                        }
                    }
                    //a ray that never reaches a light source
                    if(lightIndex == 999999)
                    {
                        //col.rgb += float3(9,0,9);
                        //col.rgb += float3(0,1,0);
                    }
                    else
                    {
                        float3 lightCol = hitLightCol(hits[lightIndex]);
                        for(int j = lightIndex - 1; j >= 0; j--)
                        {
                            HitInfo hit = hits[j];
                            BounceInfo bounce = bounces[j];
                            float metallic = hitMetallic(hit);
                            //curCol = evaluateBrdf(hit.rayIn, hit.rayOut, hit.normal, curCol, hit.material);
                            float3 reflectance = lerp(simpleBrdf(hit), float3(1,1,1), bounce.isSpecular * (1 - metallic));// / dot(hit.normal, bounce.wi);
                            //float3 reflectance = cookTorranceBrdf(hit, bounce) / bounce.pdf;
                            lightCol *= reflectance;
                            //lightCol = cookTorranceBrdf(lightCol, hit, bounce);
                        }
                        col.rgb += lightCol;
                    }
                }
                col.rgb /= _NumSamples;

                if(_ProgressiveRendering > 0.5)
                {
                    
                    float4 prevColor = tex2D(_AccumulationBuffer, IN.uv);
                    float curFrameWeight = 1.0 / (_AccumulationFrames + 1);
                    float accumulationWeight = 1 - curFrameWeight;
                    col.rgb = col.rgb * curFrameWeight + prevColor.rgb * accumulationWeight;
                }

                return col;
            }
            ENDCG
        }
    }
}
