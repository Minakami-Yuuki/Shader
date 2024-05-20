using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase
{
    // 运动模糊的shader
    public Shader motionBlurShader;

    // 运动模糊的材质
    public Material motionBlurMaterial = null;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    // 控制模糊拖尾效果 数值越大 效果越明显
    // 为放置拖尾效果完全替代当前帧的渲染效果 定值为[0.0, 0.9]
    [Range(0.0f, 0.9f)]
    public float blurAmount = 0.5f;

    // 借助 RenderTexture 将前后图像进行叠加
    private RenderTexture accumulationTexture = null;

    // 脚本不运行时 (调用OnDisable函数) 立即销毁accumulationTexture
    private void OnDisable()
    {
        DestroyImmediate(accumulationTexture);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            int width = source.width;
            int height = source.height;

            // 当RT的纹理无法满足当前尺寸 将其销毁并重新生成
            if (accumulationTexture == null || 
                accumulationTexture.width != width || 
                accumulationTexture.height != height)
            {
                // 立即销毁RT
                DestroyImmediate (accumulationTexture);
                // 重新生成RT
                accumulationTexture = new RenderTexture(width, height, 0);
                // 设定自己控制变量销毁 即不会保存至Hierarchy中
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                // 将新产生的RT和渲染图象混合
                Graphics.Blit(source, accumulationTexture);
            }

            // 进行渲染纹理恢复操作
            // 指渲染到纹理面但没有被提前清空或销毁 (防止Unity误报错)
            // 因为需要混合 所有不用提前清空
            accumulationTexture.MarkRestoreExpected();

            material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            // 叠加渲染
            Graphics.Blit(source, accumulationTexture, material);
            // 屏幕显示
            Graphics.Blit(accumulationTexture, destination);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
    
