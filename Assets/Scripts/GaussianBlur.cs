using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// 高斯模糊
public class GaussianBlur : PostEffectsBase
{
    // 高斯模糊Shader
    public Shader gaussianBlurShader;

    // 高斯模糊材质
    private Material gaussianBlurMaterial;
    // 自动初始化挂载
    private Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }

    // 模糊程度
    [Range(0, 4)]
    public int iterations = 3;
    // 控制采用间距 (性能控制)
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;
    // 纹理降采样 (性能控制)
    [Range(1, 8)]
    public int downSample = 2;

    // 高斯模糊后处理（普通版本）
    //private void OnRenderImage(RenderTexture source, RenderTexture destination)
    //{
    //    if (material != null)
    //    {
    //        int width = source.width;
    //        int height = source.height;

    //        // 分配一个和屏幕图像大小相同的缓存纹理
    //        RenderTexture buffer = RenderTexture.GetTemporary(width, height, 0);

    //        // 先使用第一个Pass进行纵向模糊，渲染到临时纹理中
    //        Graphics.Blit(source, buffer, material, 0);
    //        // 再使用第二个Pass进行横向模糊，从临时纹理渲染到最终的屏幕上
    //        Graphics.Blit(buffer, destination, material, 1);

    //        // 释放之前分配的缓存
    //        RenderTexture.ReleaseTemporary(buffer);
    //    }
    //    else
    //    {
    //        Graphics.Blit(source, destination);
    //    }
    //}

    // 高斯模糊后处理（性能优化版1）
    //private void OnRenderImage(RenderTexture source, RenderTexture destination)
    //{
    //    if (material != null)
    //    {
    //        // 对屏幕像素进行降采样
    //        int width = source.width / downSample;
    //        int height = source.height / downSample;

    //        // 分配降采样后的临时缓存
    //        RenderTexture buffer = RenderTexture.GetTemporary(width, height, 0);
    //        // 双线性过滤，防止降采样后的纹理像素看上去不连贯，丢失严重
    //        buffer.filterMode = FilterMode.Bilinear;

    //        // 先使用第一个Pass进行纵向模糊，渲染到临时纹理中
    //        Graphics.Blit(source, buffer, material, 0);
    //        // 再使用第二个Pass进行横向模糊，从临时纹理渲染到最终的屏幕上
    //        Graphics.Blit(buffer, destination, material, 1);

    //        // 释放之前分配的缓存
    //        RenderTexture.ReleaseTemporary(buffer);
    //    }
    //    else
    //    {
    //        Graphics.Blit(source, destination);
    //    }
    //}

    // 高斯模糊后处理（性能优化版2）
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            // 对屏幕像素进行降采样
            int width = source.width / downSample;
            int height = source.height / downSample;

            // 分配降采样后的临时缓存
            RenderTexture buffer0 = RenderTexture.GetTemporary(width, height, 0);
            // 双线性过滤，防止降采样后的纹理像素看上去不连贯，丢失严重
            buffer0.filterMode = FilterMode.Bilinear;
            // 简单降采样后，将图像渲染到临时缓存
            Graphics.Blit(source, buffer0);

            // 进行多次高斯模糊操作
            for (int i = 0; i < iterations; i++)
            {
                // 动态设置高斯核邻域的采样间距，每次高斯模糊采样间距逐渐加大
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(width, height, 0);
                Graphics.Blit(buffer0, buffer1, material, 0);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(width, height, 0);

                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            Graphics.Blit(buffer0, destination);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
