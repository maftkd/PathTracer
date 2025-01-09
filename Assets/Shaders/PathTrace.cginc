float4 _ViewParams;
float4x4 _CamLocalToWorld;

float _SphereData[1000];
fixed _NumSpheres;
fixed _SphereStride;

struct Ray
{
    float3 origin;
    float3 direction;
};

struct HitInfo
{
    int sphereIndex;
    float distance;
};

//https://iquilezles.org/articles/intersectors/
float2 sphIntersect(float3 ro, float3 rd, float3 center, float radius )
{
    float3 oc = ro - center;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - radius*radius;
    float h = b*b - c;
    if( h<0.0 ) return float3(-1, -1 , -1); // no intersection
    h = sqrt( h );
    return float2( -b-h, -b+h );
}