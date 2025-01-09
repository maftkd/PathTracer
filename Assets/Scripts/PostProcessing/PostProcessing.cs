using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostProcessing : MonoBehaviour
{
    public GameObject [] postProcessLayers;

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        RenderTexture tmp = RenderTexture.GetTemporary(src.width, src.height, 0, src.graphicsFormat);
        RenderTexture tmp2 = RenderTexture.GetTemporary(src.width, src.height, 0, src.graphicsFormat);
        
        Graphics.Blit(src, tmp);
        
        bool pingPong = false;
        for (int i = 0; i < postProcessLayers.Length; i++)
        {
            if (!postProcessLayers[i].activeSelf)
            {
                continue;
            }
            IPostProcessLayer postProcessLayer = postProcessLayers[i].GetComponent<IPostProcessLayer>();
            if (postProcessLayer == null)
            {
                continue;
            }
            pingPong = !pingPong;
            
            if(pingPong)
            {
                postProcessLayer.OnRenderImage(tmp, tmp2);
            }
            else
            {
                postProcessLayer.OnRenderImage(tmp2, tmp);
            }
        }
        
        if(pingPong)
        {
            Graphics.Blit(tmp2, dest);
        }
        else
        {
            Graphics.Blit(tmp, dest);
        }
        
        RenderTexture.ReleaseTemporary(tmp);
        RenderTexture.ReleaseTemporary(tmp2);
    }
}
