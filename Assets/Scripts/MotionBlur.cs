using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase
{
    // �˶�ģ����shader
    public Shader motionBlurShader;

    // �˶�ģ���Ĳ���
    public Material motionBlurMaterial = null;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    // ����ģ����βЧ�� ��ֵԽ�� Ч��Խ����
    // Ϊ������βЧ����ȫ�����ǰ֡����ȾЧ�� ��ֵΪ[0.0, 0.9]
    [Range(0.0f, 0.9f)]
    public float blurAmount = 0.5f;

    // ���� RenderTexture ��ǰ��ͼ����е���
    private RenderTexture accumulationTexture = null;

    // �ű�������ʱ (����OnDisable����) ��������accumulationTexture
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

            // ��RT�������޷����㵱ǰ�ߴ� �������ٲ���������
            if (accumulationTexture == null || 
                accumulationTexture.width != width || 
                accumulationTexture.height != height)
            {
                // ��������RT
                DestroyImmediate (accumulationTexture);
                // ��������RT
                accumulationTexture = new RenderTexture(width, height, 0);
                // �趨�Լ����Ʊ������� �����ᱣ����Hierarchy��
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                // ���²�����RT����Ⱦͼ����
                Graphics.Blit(source, accumulationTexture);
            }

            // ������Ⱦ����ָ�����
            // ָ��Ⱦ�������浫û�б���ǰ��ջ����� (��ֹUnity�󱨴�)
            // ��Ϊ��Ҫ��� ���в�����ǰ���
            accumulationTexture.MarkRestoreExpected();

            material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            // ������Ⱦ
            Graphics.Blit(source, accumulationTexture, material);
            // ��Ļ��ʾ
            Graphics.Blit(accumulationTexture, destination);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
    
