using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GammaCorrection : MonoBehaviour, IPostProcessLayer
{
    public Shader shader;
    private Material _material;

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_material == null)
        {
            _material = new Material(shader);
        }
        
        Graphics.Blit(source, destination, _material);
    }
}
