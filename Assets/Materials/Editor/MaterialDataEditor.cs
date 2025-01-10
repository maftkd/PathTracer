using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(MaterialData))]
public class MaterialDataEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        var script = (MaterialData)target;

        if (Application.isPlaying)
        {
            MaterialManager.Instance.UpdateMaterialData(script);
            //script.CreateAndUpdateColorPalette();
        }
    }
}
