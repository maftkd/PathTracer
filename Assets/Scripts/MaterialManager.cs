using System;
using System.Collections.Generic;
using UnityEngine;

public class MaterialManager : MonoBehaviour
{
    private List<MaterialData> materials = new();

    private float[] _materialData;
    private const int MATERIAL_STRIDE = 5;
    private const int MAX_MATERIALS = 100;

    public static MaterialManager Instance;

    void Awake()
    {
        if(Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(this);
        }
    }
    
    // Start is called before the first frame update
    void Start()
    {
    }

    void UpdateMaterialData(MaterialData mat)
    {
        if (_materialData == null || _materialData.Length == 0)
        {
            _materialData = new float[MAX_MATERIALS * MATERIAL_STRIDE];
            for(int i = 0; i < _materialData.Length; i++)
            {
                _materialData[i] = 0;
            }
        }

        int index = materials.Count;
        //Debug.Log($"index: {index}, materials.Count: {materials.Count}, _materialData length: {_materialData.Length}");
        _materialData[index * MATERIAL_STRIDE] = mat.albedo.r;
        _materialData[index * MATERIAL_STRIDE + 1] = mat.albedo.g;
        _materialData[index * MATERIAL_STRIDE + 2] = mat.albedo.b;
        _materialData[index * MATERIAL_STRIDE + 3] = mat.roughness;
        _materialData[index * MATERIAL_STRIDE + 4] = mat.metallic;
        materials.Add(mat);
        
        Shader.SetGlobalFloatArray("_MaterialData", _materialData);
        Shader.SetGlobalFloat("_MaterialStride", MATERIAL_STRIDE);
    }

    private void OnApplicationQuit()
    {
        _materialData = null;
    }

    public int GetMaterialIndex(MaterialData material)
    {
        if (!materials.Contains(material))
        {
            UpdateMaterialData(material);
        }
        
        return materials.IndexOf(material);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
