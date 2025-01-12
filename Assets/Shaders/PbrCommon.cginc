float _PointLightData[96]; // 6 * 16
float _PointLightCount;
samplerCUBE_half _IndirectDiffuseMap;
samplerCUBE_half _IndirectSpecularMap;
sampler2D _BrdfLut;
static const float MAX_REFLECTION_LOD = 4.0;

float distributionGGX(float3 normal, float3 halfVec, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(normal, halfVec), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float num = a2;
    float denom = NdotH2 * (a2 - 1.0) + 1.0;
    denom = UNITY_PI * denom * denom;
	
    return num / denom;
}
float geometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}
float geometrySmith(float3 normal, float3 view, float3 light, float roughness)
{
    float NdotV = max(dot(normal, view), 0.0);
    float NdotL = max(dot(normal, light), 0.0);
    float ggx2  = geometrySchlickGGX(NdotV, roughness);
    float ggx1  = geometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
}

float geometry(float3 normal, float3 view, float3 halfVec, float3 lightDir)
{
    float nDotV = dot(normal, view);
    float nDotL = dot(normal, lightDir);
    float hDotN = dot(halfVec, normal);
    float hDotV = dot(halfVec, view);

    float a = 2 * hDotN * nDotV / hDotV;
    float b = 2 * hDotN * nDotL / hDotV;

    return min(1, min(a, b));
}

float3 fresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1.0,1.0,1.0) * (1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}