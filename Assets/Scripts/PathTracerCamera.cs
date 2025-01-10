using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PathTracerCamera : MonoBehaviour
{
    private Camera _mainCam;

    private Vector3 _prevPos;
    private Quaternion _prevRot;

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
        
        if(_mainCam.transform.position != _prevPos || _mainCam.transform.rotation != _prevRot)
        {
            PathTracer.Instance.ResetAccumulation();
        }
        
        _prevPos = _mainCam.transform.position;
        _prevRot = _mainCam.transform.rotation;
    }
}
