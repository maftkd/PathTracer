using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PathTracerCamera : MonoBehaviour
{
    private Camera _mainCam;
    // Start is called before the first frame update
    void Start()
    {
        _mainCam = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        float planeHeight = _mainCam.nearClipPlane * Mathf.Tan(_mainCam.fieldOfView * 0.5f * Mathf.Deg2Rad) * 2f;
        float planeWidth = planeHeight * _mainCam.aspect;
        
        Shader.SetGlobalVector("_ViewParams", new Vector4(planeWidth, planeHeight, _mainCam.nearClipPlane, _mainCam.farClipPlane));
        Shader.SetGlobalMatrix("_CamLocalToWorld", _mainCam.transform.localToWorldMatrix);
    }
}
