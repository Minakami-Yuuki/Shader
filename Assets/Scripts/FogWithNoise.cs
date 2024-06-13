using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithNoise : PostEffectsBase
{
    // ��Чshader
    public Shader fogShader;
    // ��Ч����
    private Material fogMaterial = null;
    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    // �����ز���
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

    // ��ȡ���������ռ��µ����ܷ���
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

    // ��ЧŨ��
    [Range(0.1f, 3.0f)]
    public float fogDensity = 1.0f;
    // ��Ч��ɫ
    public Color fogColor = Color.white;

    // ��Ч���߶�
    public float fogStart = 0.0f;
    // ��Ч�յ�߶�
    public float fogEnd = 2.0f;

    // ��Ч��������
    public Texture noiseTexture;
    // ������x���ƶ��ٶ�
    [Range(-0.5f, 0.5f)]
    public float fogXSpeed = 0.1f;
    // ������y���ƶ��ٶ�
    [Range(-0.5f, 0.5f)]
    public float fogYSpeed = 0.1f;
    // �������ó̶�
    [Range(0.0f, 3.0f)]
    public float noiseAmount = 1.0f;

    private void OnEnable()
    {
        // �����������
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        // 4x4 �����¼4���ǵ�λ��
        Matrix4x4 frustumCorners = Matrix4x4.identity;

        // �������
        float fov = camera.fieldOfView;
        float near = camera.nearClipPlane;
        float aspect = camera.aspect;

        // ��ƽ���һ��߶�
        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        // ��ƽ�����ĵ����ҵ����� ������ƽ��һ��Ŀ�Ⱦ���
        Vector3 toRight = cameraTransform.right * halfHeight * aspect;
        // ��ƽ�����ĵ����ϵ����� ������ƽ��һ��ĸ߶Ⱦ���
        Vector3 toTop = cameraTransform.up * halfHeight;

        // ���ϽǶ���λ��
        Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;

        // ����������ԭ����ʹ�õĹ�ʽ�ı���ϵ��
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

        // ���ĸ��ǵ������洢��������
        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topRight);
        frustumCorners.SetRow(3, topLeft);

        // ��Shader�д������Ե�ֵ
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
