using UnityEngine;

public interface IPostProcessLayer
{
    void OnRenderImage(RenderTexture source, RenderTexture destination);
}
