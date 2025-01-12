float4 _ViewParams;
float4x4 _CamLocalToWorld;

float _SphereData[500];
fixed _NumSpheres;
fixed _SphereStride;

float _MaterialData[500];
fixed _MaterialStride;

struct Ray
{
    float3 origin;
    float3 direction;
};

struct HitInfo
{
    float hitLight;
    //int sphereIndex;
    float3 position;
    float3 normal;
    int materialIndex;
    //float3 col;
    //float3 emission;
};

struct BounceInfo
{
    float3 wo;
    float3 wi;
    //float pdf;
    bool isSpecular;
};

float random(inout uint state)
{
    state = state * 747796405u + 2891336453u;
    uint result = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    result = (result >> 22u) ^ result;
    return result / 4294967296.0;
}

float3 jitterPoint(float3 pos, float3 right, float3 up, float amount, uint rngState)
{
    float2 jitterVec = 0;
    for(int i = 0; i < 10; i++)
    {
        jitterVec = float2(random(rngState) * 2 - 1, random(rngState) * 2 - 1);
        float mag = length(jitterVec);
        if(mag <= 1)
        {
            break;
        }
    }

    jitterVec *= amount;
    return pos + right * jitterVec.x + up * jitterVec.y;
}

// axis aligned box centered at the origin, with size boxSize
float2 boxIntersection( in float3 ro, in float3 rd, float3 boxSize, out float3 outNormal ) 
{
    float3 m = 1.0/rd; // can precompute if traversing a set of aligned boxes
    float3 n = m*ro;   // can precompute if traversing a set of aligned boxes
    float3 k = abs(m)*boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return float2(-1.0, -1.0); // no intersection
    outNormal = (tN>0.0) ? step(float3(1,1,1)*tN,t1) : // ro ouside the box
                           step(t2,float3(1,1,1)*tF);  // ro inside the box
    outNormal *= -sign(rd);
    return float2( tN, tF );
}

//https://iquilezles.org/articles/intersectors/
float2 sphIntersect(float3 ro, float3 rd, float3 center, float radius )
{
    float3 oc = ro - center;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - radius*radius;
    float h = b*b - c;
    if( h<0.0 ) return float2(-1, -1); // no intersection
    h = sqrt( h );
    return float2( -b-h, -b+h );
}

float3 getEmissionFromMaterial(int materialIndex)
{
    return float3(_MaterialData[materialIndex * _MaterialStride + 3], _MaterialData[materialIndex * _MaterialStride + 4],
        _MaterialData[materialIndex * _MaterialStride + 5]);
}

void rayTrace(Ray ray, out HitInfo hit)
{
    float minT = 1000000;
    int sphereIndex = 999999;
    
    float distance = -1;
    hit.position = 0;
    hit.normal = 0;
    hit.hitLight = 0;
    //hit.emission = 0;
    
    //check against all spheres to find min
    for(int i = 0; i < _NumSpheres; i++)
    {
        float3 spherePos = float3(_SphereData[i * _SphereStride + 0], _SphereData[i * _SphereStride + 1], _SphereData[i * _SphereStride + 2]);
        float2 hitTest = sphIntersect(ray.origin, ray.direction, spherePos, _SphereData[i * _SphereStride + 3]);
        //float2 hitTest = float2(-1,-1);
        if(hitTest.y >= 0 && hitTest.x > 0)
        {
            if(hitTest.x < minT)
            {
                minT = hitTest.x;
                sphereIndex = i;
                distance = hitTest.x;
            }
            //minT = min(minT, hitTest.x);
            //hit.distance = hitTest.x;
            //hit.sphereIndex = i;
        }
    }

    //check if there was any hit
    if(minT < 1000000)
    {
        float3 spherePos = float3(_SphereData[sphereIndex * _SphereStride + 0],
            _SphereData[sphereIndex * _SphereStride + 1], _SphereData[sphereIndex * _SphereStride + 2]);
        hit.position = ray.origin + ray.direction * distance;
        hit.normal = normalize(hit.position - spherePos);
        int matIndex = _SphereData[sphereIndex * _SphereStride + 4];

        hit.materialIndex = matIndex;
        float3 emission = getEmissionFromMaterial(hit.materialIndex);
        if(dot(emission, emission) > 0.01)
        {
            hit.hitLight = 1;
        }
    }
    else
    {
        hit.materialIndex = -1;
        hit.normal = ray.direction;
        hit.hitLight = 1;
        /*
        float a = 0.5 * (ray.direction.y + 1.0);
        //hit.emission = lerp(float3(1,1, 1), float3(0.5, 0.7, 1), a);
        hit.col = (1.0 - a) * float3(1.0, 1.0, 1.0) + a * float3(0.5, 0.7, 1.0);
        */
    }
}

float3 getRandomVectorInHemisphere(float3 normal, uint rngState)
{
    for(int i = 0; i < 10; i++)
    {
        float3 testVec = float3(random(rngState) * 2 - 1, random(rngState) * 2 - 1, random(rngState) * 2 - 1);
        float mag = length(testVec);
        if(mag > 1)
        {
            continue;
        }
        else
        {
            testVec /= mag;
            float dt = dot(normal, testVec);
            if(dt < 0)
            {
                testVec = -testVec;
            }
            return testVec;
        }
    }
    return 0;
}

float3 getCosineWeightedDiffuseBounceDirection(float3 normal, uint rngState)
{
    for(int i = 0; i < 10; i++)
    {
        float3 testVec = float3(random(rngState) * 2 - 1, random(rngState) * 2 - 1, random(rngState) * 2 - 1);
        float mag = length(testVec);
        if(mag > 1)
        {
            continue;
        }
        else
        {
            testVec /= mag;
            return normalize(normal + testVec);
            //return testVec;
        }
    }
    return 0;
}

float3 importanceSampleGGX(float2 xi, float3 normal, float roughness)
{
    float a = roughness * roughness;

    float phi = UNITY_TWO_PI * xi.x;
    float cosTheta = sqrt((1.0 - xi.y) / (1.0 + (a*a - 1.0) * xi.y));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

    //from spherical coords to cartesian
    float3 halfway = 0;
    halfway.x = cos(phi) * sinTheta;
    halfway.y = sin(phi) * sinTheta;
    halfway.z = cosTheta;

    //from tangent space to world space
    float3 up = abs(normal.z) < 0.999 ? float3(0,0,1) : float3(1,0,0);
    float3 tangent = normalize(cross(up, normal));
    float3 bitangent = normalize(cross(normal, tangent));

    float3 sampleVec = tangent * halfway.x + bitangent * halfway.y + normal * halfway.z;
    return normalize(sampleVec);
}

float3 hitEmissive(HitInfo hit)
{
    return getEmissionFromMaterial(hit.materialIndex);
}

float hitMetallic(HitInfo hit)
{
    return _MaterialData[hit.materialIndex * _MaterialStride + 7];
}
float hitRoughness(HitInfo hit)
{
    return _MaterialData[hit.materialIndex * _MaterialStride + 6];
}

float3 skyColor(float3 dir)
{
    float t = 0.5 * (dir.y + 1.0);
    return lerp(float3(1,1,1), float3(0.5, 0.7, 1), t);
}

float3 hitAlbedo(HitInfo hit)
{
    return float3(_MaterialData[hit.materialIndex * _MaterialStride + 0], _MaterialData[hit.materialIndex * _MaterialStride + 1],
        _MaterialData[hit.materialIndex * _MaterialStride + 2]);
}

float3 hitLightCol(HitInfo hit)
{
    if(hit.materialIndex < 0)
    {
        return skyColor(hit.normal);
    }
    return hitEmissive(hit);
}

#include "PbrCommon.cginc"
float materialPdf(float roughness, float3 normal, float3 wo, float3 halfway)
{
    float vdoth = dot(wo, halfway);
    return distributionGGX(normal, halfway, roughness) / (4 * vdoth);
}

float3 simpleBrdf(HitInfo hit)
{
    float3 albedo = hitAlbedo(hit);
    float metallic = hitMetallic(hit);
    return lerp(albedo, albedo / UNITY_PI, 1-metallic);
    //return albedo / UNITY_PI;
}

float3 cookTorranceBrdf(HitInfo hit, BounceInfo bounce)
{
    float roughness = hitRoughness(hit);
    float metallic = hitMetallic(hit);
    float3 albedo = hitAlbedo(hit);
    float3 normal = hit.normal;
    float3 wi = bounce.wi;
    float3 wo = bounce.wo;
    float3 lightDir = wi;
    float3 viewDir = -wo;
    
    float3 F0 = float3(0.04, 0.04, 0.04); 
    F0 = lerp(F0, albedo, metallic);
    
    float3 halfVec = normalize(lightDir + viewDir);

    float nDotH = max(dot(normal, halfVec), 0.0);
    
    //cook-torrance brdf
    float ndf = distributionGGX(normal, halfVec, roughness);
    float geometryTerm = geometry(normal, viewDir, halfVec, lightDir);
    float3 fresnel = fresnelSchlick(max(dot(halfVec, viewDir), 0.0), F0);
    float3 specular = ndf * geometryTerm * fresnel / (4 * dot(normal, viewDir) * dot(normal, lightDir) + 0.001);
    //float3 specular = geometryTerm * fresnel / (4 * dot(normal, viewDir) * dot(normal, lightDir) + 0.001);
    //float3 specular = fresnel / (4 * dot(normal, viewDir) * dot(normal, lightDir) + 0.001);

    float3 specularRatio = fresnel;
    float3 diffuseRatio = 1.0 - specularRatio;
    diffuseRatio *= 1.0 - metallic; //prevent metallic from having diffuse component
    
    float3 diffuse = albedo / UNITY_PI;
    //return lightCol;
    return diffuseRatio * diffuse + specularRatio * specular;
    //return lightCol * (diffuseRatio * diffuse + specularRatio * dot(normal, halfVec)) * dot(normal, lightDir);
}
