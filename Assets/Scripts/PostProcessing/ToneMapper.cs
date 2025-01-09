using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ToneMapper : MonoBehaviour, IPostProcessLayer
{
    public Shader shader;
    private Material _material;
    [Range(0,5)]
    public float exposure;
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_material == null)
        {
            _material = new Material(shader);
        }

        _material.SetFloat("_Exposure", exposure);
        
        Graphics.Blit(source, destination, _material);
    }

}
