using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectsBase
{
    // 实现后处理的shader
    public Shader briSatShader;
    // 实现后处理的材质
    public Material briSatConMaterial;

    // 初始化创建Material
    public Material material
    {
        get
        {
            briSatConMaterial = CheckShaderAndCreateMaterial(briSatShader, briSatConMaterial);
            return briSatConMaterial;
        }
    }

    // 可调整的亮度
    [Range(0.0f, 3.0f)]
    public float brightness = 1.0f;
    // 可调整的饱和度
    [Range(0.0f, 3.0f)]
    public float saturation = 1.0f;
    // 可调整的对比度
    [Range(0.0f, 3.0f)]
    public float contrast = 1.0f;

    // 将三者传入shader的Material属性中 使其动态调整shader
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_Brightness", brightness);
            material.SetFloat("_Saturation", saturation);
            material.SetFloat("_Contrast", contrast);

            // 应用shader后重新传回Material中 输出更新后的结果
            Graphics.Blit(source, destination, material);
        }
        else
        {
            // 直接输出原结果
            Graphics.Blit(source, destination);
        }
    }
}
