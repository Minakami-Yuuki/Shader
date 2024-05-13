using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectsBase
{
    // ʵ�ֺ����shader
    public Shader briSatShader;
    // ʵ�ֺ���Ĳ���
    public Material briSatConMaterial;

    // ��ʼ������Material
    public Material material
    {
        get
        {
            briSatConMaterial = CheckShaderAndCreateMaterial(briSatShader, briSatConMaterial);
            return briSatConMaterial;
        }
    }

    // �ɵ���������
    [Range(0.0f, 3.0f)]
    public float brightness = 1.0f;
    // �ɵ����ı��Ͷ�
    [Range(0.0f, 3.0f)]
    public float saturation = 1.0f;
    // �ɵ����ĶԱȶ�
    [Range(0.0f, 3.0f)]
    public float contrast = 1.0f;

    // �����ߴ���shader��Material������ ʹ�䶯̬����shader
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_Brightness", brightness);
            material.SetFloat("_Saturation", saturation);
            material.SetFloat("_Contrast", contrast);

            // Ӧ��shader�����´���Material�� ������º�Ľ��
            Graphics.Blit(source, destination, material);
        }
        else
        {
            // ֱ�����ԭ���
            Graphics.Blit(source, destination);
        }
    }
}
