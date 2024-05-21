using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    // 运动模糊Shader
    public Shader motionBlurShader;
    // 运动模糊材质
    public Material motionBlurMaterial;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    // 定义运动模糊是模糊图像的大小
    public float blurSize = 0.5f;

    // 获取相机
    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }

            return myCamera;
        }
    }

    // 上一帧相机的视角 * 投影矩阵
    private Matrix4x4 matrixPreviousViewProjection;

    private void OnEnable()
    {
        // 获取相机的深度纹理
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_BlurSize", blurSize);

            // 将上一帧相机视角 * 视角矩阵传入Shader
            material.SetMatrix("_PreviousViewProjectionMatrix", matrixPreviousViewProjection);

            // 计算当前帧相机的视角 * 投影矩阵
            Matrix4x4 matrixCurrentViewPorjection = camera.projectionMatrix * camera.worldToCameraMatrix;
            Matrix4x4 matrixCurrentViewPorjectionInverse = matrixCurrentViewPorjection.inverse;
            // 将矩阵传入Shader
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", matrixCurrentViewPorjectionInverse);
            matrixPreviousViewProjection = matrixCurrentViewPorjection;

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
