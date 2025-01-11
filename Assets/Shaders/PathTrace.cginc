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
    float distance;
    //int sphereIndex;
    float3 position;
    float3 normal;
    int materialIndex;
    //float3 col;
    //float3 emission;
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

void rayTrace(Ray ray, out HitInfo hit)
{
    float minT = 1000000;
    int sphereIndex = 999999;
    
    hit.distance = -1;
    hit.position = 0;
    hit.normal = 0;
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
                hit.distance = hitTest.x;
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
        hit.position = ray.origin + ray.direction * hit.distance;
        hit.normal = normalize(hit.position - spherePos);
        int matIndex = _SphereData[sphereIndex * _SphereStride + 4];

        hit.materialIndex = matIndex;
        /*
        float3 albedo = float3(_MaterialData[matIndex * _MaterialStride + 0], _MaterialData[matIndex * _MaterialStride + 1],
            _MaterialData[matIndex * _MaterialStride + 2]);
        //hit.col = albedo;
        float3 emission = float3(_MaterialData[matIndex * _MaterialStride + 3], _MaterialData[matIndex * _MaterialStride + 4],
            _MaterialData[matIndex * _MaterialStride + 5]);
        if(dot(emission, emission) > 0.01)
        {
            hit.col = emission;
            hit.distance = -1;
        }
        */
        //hit.emission = emission;
        //col = albedo;
    }
    else
    {
        hit.materialIndex = -1;
        hit.normal = ray.direction;
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

float3 simpleBrdf(float3 lightCol, float3 albedo)
{
    return lightCol * albedo;
}

float hitEmissive(HitInfo hit, out float3 emissionColor)
{
    emissionColor = float3(_MaterialData[hit.materialIndex * _MaterialStride + 3], _MaterialData[hit.materialIndex * _MaterialStride + 4],
        _MaterialData[hit.materialIndex * _MaterialStride + 5]);
    return(dot(emissionColor, emissionColor));
}

float hitMetallic(HitInfo hit)
{
    return _MaterialData[hit.materialIndex * _MaterialStride + 7];
}

float3 skyColor(float3 dir)
{
    float t = 0.5 * (dir.y + 1.0);
    return lerp(float3(1,1,1), float3(0.5, 0.7, 1), t);
}

float3 hitColor(HitInfo hit)
{
    if(hit.materialIndex < 0)
    {
        return skyColor(hit.normal);
    }
    float3 emissionColor;
    if(hitEmissive(hit, emissionColor) > 0.1)
    {
        return emissionColor;
    }
    else
    {
        return float3(_MaterialData[hit.materialIndex * _MaterialStride + 0], _MaterialData[hit.materialIndex * _MaterialStride + 1],
            _MaterialData[hit.materialIndex * _MaterialStride + 2]);
    }
}