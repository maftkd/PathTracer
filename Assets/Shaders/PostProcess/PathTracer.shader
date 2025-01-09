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
            float _NumSamples;
            float _AntiAliasing;
            float _MaxBounces;

            fixed4 frag (v2f i) : SV_Target
            {
                if(_NumSamples <= 0)
                {
                    return fixed4(1,0,1,1);
                }

                //init camera
                float3 viewPointLocal = float3(i.uv - 0.5, 1) * _ViewParams.xyz;
                float3 viewPoint = mul(_CamLocalToWorld, float4(viewPointLocal, 1)).xyz;
                float3 camRight = _CamLocalToWorld._m00_m10_m20;
                float3 camUp = _CamLocalToWorld._m01_m11_m21;
                float aa = _AntiAliasing * 0.0001;

                //init rng
                uint2 pixCoords = i.uv * _ScreenParams.xy;
                uint pixIndex = pixCoords.y * _ScreenParams.x + pixCoords.x;
                uint rngState = pixIndex;

                /*
                fixed4 col = 0;
                for(int i = 0; i < _NumSamples; i++)
                {
                    Ray ray;
                    ray.origin = _WorldSpaceCameraPos;
                    float3 jitteredViewPoint = viewPoint + camRight * (random(rngState) - 0.5) * aa + camUp * (random(rngState) - 0.5) * aa;
                    ray.direction = normalize(jitteredViewPoint - ray.origin);
                    
                    float3 hitCol = 0;
                    HitInfo hit;
                    rayTrace(ray, hit);
                    col.rgb += hit.col;
                }
                col.rgb /= _NumSamples;
                */

                //avgCol = 0
                //for i in samples
                //  ray = camera.generateRay(sample)
                //  HitInfo hits[MaxBounces]
                //  uint bounces = 0
                //  uint lightIndex = 999999
                //  for bounces = 0; bounces <= maxBounces; bounces++
                //      rayTrace(ray, out hitInfo)
                //      hits[bounces] = hitInfo;
                //      if !hitInfo.didHit
                //          lightIndex = bounces
                //          break;
                //      else
                //          ray = generateBounceRay(ray, hitInfo)
                //  if lightIndex == 999999
                //      avgCol += 0
                //  else
                //      curCol = hits[lightIndex].color
                //      for j = lightIndex - 1; j >= 0; j--
                //          hitInfo = hits[j];
                //          curCol = evaluateBrdf(hitInfo.rayIn, hitInfo.rayOut, hitInfo.normal, curCol, hitInfo.material)
                //      avgCol += curCol
                //avgCol /= samples

                //***********************************************************************************************************************
                //debug code
                //avgCol = 0
                //for i in samples
                //  ray = camera.generateRay(sample)
                //  HitInfo hits[MaxBounces]
                //  uint bounces = 0
                //  uint lightIndex = 999999
                //  for bounces = 0; bounces <= maxBounces; bounces++
                //      rayTrace(ray, out hitInfo)
                //      hits[bounces] = hitInfo;
                //      if !hitInfo.didHit
                //          lightIndex = bounces
                //          break;
                //      else
                //          ray = generateBounceRay(ray, hitInfo)
                //  if lightIndex == 999999
                //      avgCol += 0
                //  else
                //      curCol = hits[lightIndex].color
                //      for j = lightIndex - 1; j >= 0; j--
                //          hitInfo = hits[j];
                //          curCol = evaluateBrdf(hitInfo.rayIn, hitInfo.rayOut, hitInfo.normal, curCol, hitInfo.material)
                //      avgCol += curCol
                //avgCol /= samples

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
                            ray.direction = reflect(ray.direction, hit.normal);
                        }
                    }
                    if(lightIndex == 999999)
                    {
                        //col.rgb += float3(9,0,9);
                        //col.rgb += float3(0,1,0);
                    }
                    else
                    {
                        col.rgb += lightIndex / _MaxBounces;
                        //col.rgb += float3(1,0,0);
                    }
                }
                col.rgb /= _NumSamples;

                return col;
            }
            ENDCG
        }
    }
}
