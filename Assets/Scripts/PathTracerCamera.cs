using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PathTracerCamera : MonoBehaviour
{
    private Camera _mainCam;

    [Range(0, 50)]
    public float focalDistance;
    [Range(0,1)]
    public float dofBlur;

    private float _prevDofBlur;

    private float _prevFocalDistance;
    // Start is called before the first frame update
    void Start()
    {
        _mainCam = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        float nearClip = focalDistance;
        float planeHeight = nearClip * Mathf.Tan(_mainCam.fieldOfView * 0.5f * Mathf.Deg2Rad) * 2f;
        float planeWidth = planeHeight * _mainCam.aspect;
        
        Shader.SetGlobalVector("_ViewParams", new Vector4(planeWidth, planeHeight, nearClip, _mainCam.farClipPlane));
        Shader.SetGlobalMatrix("_CamLocalToWorld", _mainCam.transform.localToWorldMatrix);
        
        //_mat.SetFloat("_FocalDistance", focalDistance);
        Shader.SetGlobalFloat("_DofBlur", dofBlur);
        
        if(_prevDofBlur != dofBlur || _prevFocalDistance != focalDistance)
        {
            PathTracer.Instance.ResetAccumulation();
            _prevDofBlur = dofBlur;
            _prevFocalDistance = focalDistance;
        }
    }
}
