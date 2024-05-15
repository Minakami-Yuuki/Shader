using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// 集成后处理基类
public class Bloom : PostEffectsBase
{
    // Bloom效果Shader
    public Shader bloomShader;
    // Bloom效果材质
    public Material bloomMaterial = null;
    public Material material
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0, 4)]
    public int iterations = 3;
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;
    [Range(1, 8)]
    public int downSample = 2;
    // 明度，在开启HDR后，亮度可以超过1
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            // 出于性能考虑，对纹理宽高进行降采样
            int width = source.width / downSample;
            int height = source.height / downSample;

            // 分配一个临时的缓存
            RenderTexture buffer0 = RenderTexture.GetTemporary(width, height, 0);
            // 双线性过滤
            buffer0.filterMode = FilterMode.Bilinear;
            // 取原来纹理高于明度阈值的部分，渲染到降采样后的缓存纹理中
            Graphics.Blit(source, buffer0, material, 0);

            // 经过几次迭代，将纹理进行高斯模糊后暂存到buffer0缓存中
            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(width, height, 0);
                // 使用第2个Pass进行竖直方向上的高斯模糊
                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;

                buffer1 = RenderTexture.GetTemporary(width, height, 0);
                // 使用第3个Pass进行水平方向上的高斯模糊
                Graphics.Blit(buffer0, buffer1, material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            // 将高斯模糊后的纹理作为Bloom纹理
            material.SetTexture("_Bloom", buffer0);
            Graphics.Blit(source, destination, material, 3);

            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}