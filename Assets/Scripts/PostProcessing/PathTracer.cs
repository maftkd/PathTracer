using UnityEngine;

public class PathTracer : MonoBehaviour, IPostProcessLayer
{
    public Shader pathTraceShader;
    private Material _mat;

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_mat == null)
        {
            _mat = new Material(pathTraceShader);
        }
        Graphics.Blit(source, destination, _mat);
    }
}
