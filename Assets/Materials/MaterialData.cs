using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "MaterialData", menuName = "Material Data", order = 0)]
public class MaterialData : ScriptableObject
{
    public Color albedo;
    [ColorUsage(false, true)]
    public Color emission;
    public float roughness;
    public float metallic;

    public void UpdateMaterialData()
    {
        
    }
}
