using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Sobel 算子边缘检测
public class EdgeDetection : PostEffectsBase
{
    // 声明边缘检测Shader
    public Shader edgeDetectShader;
    // 声明边缘检测材质
    private Material edgeDetectMaterial = null;
    // 自动初始化生成component
    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    // Shder初始化:
    // edgeOnly为0: 表示边缘将叠加在原渲染图像上
    // edgeOnly为1: 表示只显示边缘 不显示图像
    [Range(0.0f, 1.0f)]
    public float edgeOnly = 1.0f;
    // 边缘颜色
    public Color edgeColor = Color.white;
    // 背景颜色
    public Color backgroundColor = Color.white;

    // 传参至Shader
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgeOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);

            // 混合结果
            Graphics.Blit(source, destination, edgeDetectMaterial);
        }
        else
        {
            // 产生原结果
            Graphics.Blit(source, destination);
        }
    }

}
