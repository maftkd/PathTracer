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
    public bool progressiveRendering;
    public int maxAccumulationFrames;
    private bool _prevProgressive;


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
        _accumulationFrames = 0;
        Shader.SetGlobalInteger("_AccumulationFrames", _accumulationFrames);
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
            _accumulationBuffer = new RenderTexture(source.width, source.height, 0, RenderTextureFormat.ARGBFloat);
            Shader.SetGlobalTexture("_AccumulationBuffer", _accumulationBuffer);
            //_accumulationBuffer.enableRandomWrite = true;
            //_accumulationBuffer.Create();
        }
        _mat.SetFloat("_NumSamples", numSamples);
        _mat.SetFloat("_AntiAliasing", antiAliasing);
        _mat.SetFloat("_MaxBounces", maxBounces);
        _mat.SetFloat("_ProgressiveRendering", progressiveRendering ? 1 : 0);
        _mat.SetInteger("_AccumulationFrames", _accumulationFrames);
        
        if(_accumulationFrames < maxAccumulationFrames)
        {
            RenderTexture tmp = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.ARGBFloat);
            Graphics.Blit(null, tmp, _mat);
            Graphics.Blit(tmp, _accumulationBuffer);
            RenderTexture.ReleaseTemporary(tmp);
        }
        Graphics.Blit(_accumulationBuffer, destination);

        if (progressiveRendering)
        {
            _accumulationFrames++;
        }

        if (progressiveRendering != _prevProgressive)
        {
            ResetAccumulation();
            _prevProgressive = progressiveRendering;
        }
    }

    public void ResetAccumulation()
    {
        if(clearMat == null)
        {
            clearMat = new Material(clearShader);
            clearMat.SetColor("_Color", Color.black);
        }
        
        Graphics.Blit(null, _accumulationBuffer, clearMat);
        
        _accumulationFrames = 0;
        Shader.SetGlobalFloat("_AccumulationFrames", _accumulationFrames);
    }
}
