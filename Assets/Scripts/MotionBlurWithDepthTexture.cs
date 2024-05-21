using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    // �˶�ģ��Shader
    public Shader motionBlurShader;
    // �˶�ģ������
    public Material motionBlurMaterial;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    // �����˶�ģ����ģ��ͼ��Ĵ�С
    public float blurSize = 0.5f;

    // ��ȡ���
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

    // ��һ֡������ӽ� * ͶӰ����
    private Matrix4x4 matrixPreviousViewProjection;

    private void OnEnable()
    {
        // ��ȡ������������
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_BlurSize", blurSize);

            // ����һ֡����ӽ� * �ӽǾ�����Shader
            material.SetMatrix("_PreviousViewProjectionMatrix", matrixPreviousViewProjection);

            // ���㵱ǰ֡������ӽ� * ͶӰ����
            Matrix4x4 matrixCurrentViewPorjection = camera.projectionMatrix * camera.worldToCameraMatrix;
            Matrix4x4 matrixCurrentViewPorjectionInverse = matrixCurrentViewPorjection.inverse;
            // ��������Shader
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
