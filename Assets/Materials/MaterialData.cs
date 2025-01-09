using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "MaterialData", menuName = "Material Data", order = 0)]
public class MaterialData : ScriptableObject
{
    public Color albedo;
    public float roughness;
    public float metallic;
}
