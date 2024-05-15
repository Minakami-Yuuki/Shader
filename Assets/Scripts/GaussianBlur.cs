using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// ��˹ģ��
public class GaussianBlur : PostEffectsBase
{
    // ��˹ģ��Shader
    public Shader gaussianBlurShader;

    // ��˹ģ������
    private Material gaussianBlurMaterial;
    // �Զ���ʼ������
    private Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }

    // ģ���̶�
    [Range(0, 4)]
    public int iterations = 3;
    // ���Ʋ��ü�� (���ܿ���)
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;
    // �������� (���ܿ���)
    [Range(1, 8)]
    public int downSample = 2;

    // ��˹ģ��������ͨ�汾��
    //private void OnRenderImage(RenderTexture source, RenderTexture destination)
    //{
    //    if (material != null)
    //    {
    //        int width = source.width;
    //        int height = source.height;

    //        // ����һ������Ļͼ���С��ͬ�Ļ�������
    //        RenderTexture buffer = RenderTexture.GetTemporary(width, height, 0);

    //        // ��ʹ�õ�һ��Pass��������ģ������Ⱦ����ʱ������
    //        Graphics.Blit(source, buffer, material, 0);
    //        // ��ʹ�õڶ���Pass���к���ģ��������ʱ������Ⱦ�����յ���Ļ��
    //        Graphics.Blit(buffer, destination, material, 1);

    //        // �ͷ�֮ǰ����Ļ���
    //        RenderTexture.ReleaseTemporary(buffer);
    //    }
    //    else
    //    {
    //        Graphics.Blit(source, destination);
    //    }
    //}

    // ��˹ģ�����������Ż���1��
    //private void OnRenderImage(RenderTexture source, RenderTexture destination)
    //{
    //    if (material != null)
    //    {
    //        // ����Ļ���ؽ��н�����
    //        int width = source.width / downSample;
    //        int height = source.height / downSample;

    //        // ���併���������ʱ����
    //        RenderTexture buffer = RenderTexture.GetTemporary(width, height, 0);
    //        // ˫���Թ��ˣ���ֹ����������������ؿ���ȥ�����ᣬ��ʧ����
    //        buffer.filterMode = FilterMode.Bilinear;

    //        // ��ʹ�õ�һ��Pass��������ģ������Ⱦ����ʱ������
    //        Graphics.Blit(source, buffer, material, 0);
    //        // ��ʹ�õڶ���Pass���к���ģ��������ʱ������Ⱦ�����յ���Ļ��
    //        Graphics.Blit(buffer, destination, material, 1);

    //        // �ͷ�֮ǰ����Ļ���
    //        RenderTexture.ReleaseTemporary(buffer);
    //    }
    //    else
    //    {
    //        Graphics.Blit(source, destination);
    //    }
    //}

    // ��˹ģ�����������Ż���2��
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            // ����Ļ���ؽ��н�����
            int width = source.width / downSample;
            int height = source.height / downSample;

            // ���併���������ʱ����
            RenderTexture buffer0 = RenderTexture.GetTemporary(width, height, 0);
            // ˫���Թ��ˣ���ֹ����������������ؿ���ȥ�����ᣬ��ʧ����
            buffer0.filterMode = FilterMode.Bilinear;
            // �򵥽������󣬽�ͼ����Ⱦ����ʱ����
            Graphics.Blit(source, buffer0);

            // ���ж�θ�˹ģ������
            for (int i = 0; i < iterations; i++)
            {
                // ��̬���ø�˹������Ĳ�����࣬ÿ�θ�˹ģ����������𽥼Ӵ�
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
