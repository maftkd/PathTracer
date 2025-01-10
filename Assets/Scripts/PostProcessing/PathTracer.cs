using System;
using UnityEngine;

public class PathTracer : MonoBehaviour, IPostProcessLayer
{
    public Shader pathTraceShader;
    private Material _mat;

    public int numSamples;
    public float antiAliasing;
    public int maxBounces;

    private RenderTexture _accumulationBuffer;
    private int _accumulationFrames;
    public Shader clearShader;
    private Material clearMat;

    public static PathTracer Instance;

    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void Start()
    {
        _accumulationFrames = 1;
    }

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_mat == null)
        {
            _mat = new Material(pathTraceShader);
        }

        if (_accumulationBuffer == null || _accumulationBuffer.width != source.width || _accumulationBuffer.height != source.height)
        {
            if (_accumulationBuffer != null)
            {
                _accumulationBuffer.Release();
            }
            _accumulationBuffer = new RenderTexture(source.width, source.height, 0, source.format);
            Shader.SetGlobalTexture("_AccumulationBuffer", _accumulationBuffer);
            //_accumulationBuffer.enableRandomWrite = true;
            //_accumulationBuffer.Create();
        }
        _mat.SetFloat("_NumSamples", numSamples);
        _mat.SetFloat("_AntiAliasing", antiAliasing);
        _mat.SetFloat("_MaxBounces", maxBounces);
        Graphics.Blit(null, _accumulationBuffer, _mat);
        //Graphics.Blit(source, destination, _mat);
        Graphics.Blit(_accumulationBuffer, destination);
        _accumulationFrames++;
        Shader.SetGlobalFloat("_AccumulationFrames", _accumulationFrames);
    }

    public void ResetAccumulation()
    {
        Debug.Log("Resetting accumulation");
        if(clearMat == null)
        {
            clearMat = new Material(clearShader);
            clearMat.SetColor("_Color", Color.black);
        }
        
        Graphics.Blit(null, _accumulationBuffer, clearMat);
        
        _accumulationFrames = 1;
        Shader.SetGlobalFloat("_AccumulationFrames", _accumulationFrames);
    }
}
