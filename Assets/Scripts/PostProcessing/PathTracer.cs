using UnityEngine;

public class PathTracer : MonoBehaviour, IPostProcessLayer
{
    public Shader pathTraceShader;
    private Material _mat;

    public int numSamples;
    public float antiAliasing;
    public int maxBounces;

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_mat == null)
        {
            _mat = new Material(pathTraceShader);
        }
        _mat.SetFloat("_NumSamples", numSamples);
        _mat.SetFloat("_AntiAliasing", antiAliasing);
        _mat.SetFloat("_MaxBounces", maxBounces);
        Graphics.Blit(source, destination, _mat);
    }
}
