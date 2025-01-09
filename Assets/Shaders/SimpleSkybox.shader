Shader "Unlit/SimpleSkybox"
{
    Properties
    {
        _Cubemap ("Cubemap", CUBE) = "" {}
        
        [Toggle] _DoTest ("Test", Float) = 0
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        //Cull Off ZWrite Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 eyeRay : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.eyeRay = normalize(v.vertex.xyz);
                return o;
            }

            samplerCUBE_half _Cubemap;
            half4 _Cubemap_HDR;
            samplerCUBE_half _TestCube;
            fixed _DoTest;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 eyeRay = normalize(i.eyeRay);

                if(_DoTest > 0)
                {
                    fixed4 col = texCUBE(_TestCube, eyeRay);
                    return col;
                }
                //sample hdr map
                fixed4 envColor = texCUBElod(_Cubemap, float4(eyeRay, 0));
                envColor.rgb = DecodeHDR (envColor, _Cubemap_HDR);
                
                //encode to gamma since we gamma correct everything in post
                envColor = pow(envColor, 2.2);
                return envColor;
            }
            ENDCG
        }
    }
}
