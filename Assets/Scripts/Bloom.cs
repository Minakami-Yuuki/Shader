using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// ���ɺ������
public class Bloom : PostEffectsBase
{
    // BloomЧ��Shader
    public Shader bloomShader;
    // BloomЧ������
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
    // ���ȣ��ڿ���HDR�����ȿ��Գ���1
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            // �������ܿ��ǣ��������߽��н�����
            int width = source.width / downSample;
            int height = source.height / downSample;

            // ����һ����ʱ�Ļ���
            RenderTexture buffer0 = RenderTexture.GetTemporary(width, height, 0);
            // ˫���Թ���
            buffer0.filterMode = FilterMode.Bilinear;
            // ȡԭ���������������ֵ�Ĳ��֣���Ⱦ����������Ļ���������
            Graphics.Blit(source, buffer0, material, 0);

            // �������ε�������������и�˹ģ�����ݴ浽buffer0������
            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(width, height, 0);
                // ʹ�õ�2��Pass������ֱ�����ϵĸ�˹ģ��
                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;

                buffer1 = RenderTexture.GetTemporary(width, height, 0);
                // ʹ�õ�3��Pass����ˮƽ�����ϵĸ�˹ģ��
                Graphics.Blit(buffer0, buffer1, material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            // ����˹ģ�����������ΪBloom����
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