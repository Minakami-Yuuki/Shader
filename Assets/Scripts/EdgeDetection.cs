using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Sobel ���ӱ�Ե���
public class EdgeDetection : PostEffectsBase
{
    // ������Ե���Shader
    public Shader edgeDetectShader;
    // ������Ե������
    private Material edgeDetectMaterial = null;
    // �Զ���ʼ������component
    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    // Shder��ʼ��:
    // edgeOnlyΪ0: ��ʾ��Ե��������ԭ��Ⱦͼ����
    // edgeOnlyΪ1: ��ʾֻ��ʾ��Ե ����ʾͼ��
    [Range(0.0f, 1.0f)]
    public float edgeOnly = 1.0f;
    // ��Ե��ɫ
    public Color edgeColor = Color.white;
    // ������ɫ
    public Color backgroundColor = Color.white;

    // ������Shader
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgeOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);

            // ��Ͻ��
            Graphics.Blit(source, destination, edgeDetectMaterial);
        }
        else
        {
            // ����ԭ���
            Graphics.Blit(source, destination);
        }
    }

}
