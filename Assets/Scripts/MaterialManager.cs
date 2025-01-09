using UnityEngine;

public class MaterialManager : MonoBehaviour
{
    public MaterialData[] materials;

    private float[] _materialData;
    private const int MATERIAL_STRIDE = 5;
    private const int MAX_MATERIALS = 100;
    // Start is called before the first frame update
    void Start()
    {
        _materialData = new float[MAX_MATERIALS * MATERIAL_STRIDE];
        
        for(int i = 0; i < materials.Length; i++)
        {
            MaterialData mat = materials[i];
            _materialData[i * MATERIAL_STRIDE] = mat.albedo.r;
            _materialData[i * MATERIAL_STRIDE + 1] = mat.albedo.g;
            _materialData[i * MATERIAL_STRIDE + 2] = mat.albedo.b;
            _materialData[i * MATERIAL_STRIDE + 3] = mat.roughness;
            _materialData[i * MATERIAL_STRIDE + 4] = mat.metallic;
        }
        for(int i = materials.Length; i < MAX_MATERIALS; i++)
        {
            _materialData[i * MATERIAL_STRIDE] = 0;
            _materialData[i * MATERIAL_STRIDE + 1] = 0;
            _materialData[i * MATERIAL_STRIDE + 2] = 0;
            _materialData[i * MATERIAL_STRIDE + 3] = 0;
            _materialData[i * MATERIAL_STRIDE + 4] = 0;
        }
        
        Shader.SetGlobalFloatArray("_MaterialData", _materialData);
        Shader.SetGlobalFloat("_MaterialStride", MATERIAL_STRIDE);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
