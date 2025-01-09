using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Sphere : MonoBehaviour
{
    private const int MAX_SPHERES = 100;
    private const int STRIDE = 5;
    
    private static float[] _sphereData;
    private static int numSpheres;
    private int _sphereIndex;

    public MaterialData material;
    // Start is called before the first frame update
    void Start()
    {
        _sphereIndex = -1;
        UpdateSphereData();
    }

    private void OnApplicationQuit()
    {
        _sphereData = null;
        numSpheres = 0;
    }

    public void UpdateSphereData()
    {
        if (_sphereData == null)
        {
            _sphereData = new float[MAX_SPHERES * STRIDE];
            for (int i = 0; i < _sphereData.Length; i++)
            {
                _sphereData[i] = 0;
            }
            Shader.SetGlobalFloat("_SphereStride", STRIDE);
            numSpheres = 0;
        }
        else if (numSpheres >= MAX_SPHERES)
        {
            return;
        }

        if (_sphereIndex < 0)
        {
            _sphereIndex = numSpheres;
            numSpheres++;
        }
        
        _sphereData[_sphereIndex * STRIDE + 0] = transform.position.x;
        _sphereData[_sphereIndex * STRIDE + 1] = transform.position.y;
        _sphereData[_sphereIndex * STRIDE + 2] = transform.position.z;
        _sphereData[_sphereIndex * STRIDE + 3] = transform.localScale.x * 0.5f;
        _sphereData[_sphereIndex * STRIDE + 4] = MaterialManager.Instance.GetMaterialIndex(material);
        
        Shader.SetGlobalFloatArray("_SphereData", _sphereData);
        Shader.SetGlobalFloat("_NumSpheres", numSpheres);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
