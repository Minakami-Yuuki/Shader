using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithNoise : PostEffectsBase
{
    // 雾效shader
    public Shader fogShader;
    // 雾效材质
    private Material fogMaterial = null;
    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    // 相机相关参数
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

    // 获取相机在世界空间下的四周方向
    private Transform myCameraTransform;
    public Transform cameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = camera.transform;
            }
            return myCameraTransform;
        }
    }

    // 雾效浓度
    [Range(0.1f, 3.0f)]
    public float fogDensity = 1.0f;
    // 雾效颜色
    public Color fogColor = Color.white;

    // 雾效起点高度
    public float fogStart = 0.0f;
    // 雾效终点高度
    public float fogEnd = 2.0f;

    // 雾效噪声纹理
    public Texture noiseTexture;
    // 纹理沿x轴移动速度
    [Range(-0.5f, 0.5f)]
    public float fogXSpeed = 0.1f;
    // 纹理沿y轴移动速度
    [Range(-0.5f, 0.5f)]
    public float fogYSpeed = 0.1f;
    // 纹理作用程度
    [Range(0.0f, 3.0f)]
    public float noiseAmount = 1.0f;

    private void OnEnable()
    {
        // 启用深度纹理
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        // 4x4 矩阵记录4个角的位置
        Matrix4x4 frustumCorners = Matrix4x4.identity;

        // 相机参数
        float fov = camera.fieldOfView;
        float near = camera.nearClipPlane;
        float aspect = camera.aspect;

        // 近平面的一半高度
        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        // 近平面中心点向右的向量 包含近平面一半的宽度距离
        Vector3 toRight = cameraTransform.right * halfHeight * aspect;
        // 近平面中心点向上的向量 包含近平面一半的高度距离
        Vector3 toTop = cameraTransform.up * halfHeight;

        // 左上角顶点位置
        Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;

        // 近似三角形原理中使用的公式的比例系数
        float scale = topLeft.magnitude / near;
        topLeft.Normalize();
        topLeft *= scale;

        Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
        topRight.Normalize();
        topRight *= scale;

        Vector3 bottomLeft = cameraTransform.forward * near - toRight - toTop;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
        bottomRight.Normalize();
        bottomRight *= scale;

        // 将四个角的向量存储到矩阵中
        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topRight);
        frustumCorners.SetRow(3, topLeft);

        // 往Shader中传入属性的值
        material.SetMatrix("_FrustumCornersRay", frustumCorners);

        material.SetFloat("_FogDensity", fogDensity);
        material.SetColor("_FogColor", fogColor);
        material.SetFloat("_FogStart", fogStart);
        material.SetFloat("_FogEnd", fogEnd);

        material.SetTexture("_NoiseTex", noiseTexture);
        material.SetFloat("_FogXSpeed", fogXSpeed);
        material.SetFloat("_FogYSpeed", fogYSpeed);
        material.SetFloat("_NoiseAmount", noiseAmount);

        Graphics.Blit(source, destination, material);
    }
}
