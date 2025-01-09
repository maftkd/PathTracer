using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Sphere : MonoBehaviour
{
    private const int MAX_SPHERES = 100;
    private const int STRIDE = 4;
    
    private static float[] _sphereData;
    private static int numSpheres;
    private int _sphereIndex;
    // Start is called before the first frame update
    void Start()
    {
        if (_sphereData == null)
        {
            _sphereData = new float[MAX_SPHERES * STRIDE];
            Shader.SetGlobalFloat("_SphereStride", STRIDE);
        }
        if(numSpheres < MAX_SPHERES)
        {
            _sphereData[numSpheres * STRIDE + 0] = transform.position.x;
            _sphereData[numSpheres * STRIDE + 1] = transform.position.y;
            _sphereData[numSpheres * STRIDE + 2] = transform.position.z;
            _sphereData[numSpheres * STRIDE + 3] = transform.localScale.x * 0.5f;
            
            _sphereIndex = numSpheres;
            
            numSpheres++;
            
            Shader.SetGlobalFloatArray("_SphereData", _sphereData);
            Shader.SetGlobalFloat("_NumSpheres", numSpheres);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
