using UnityEngine;

// �༭��״̬��Ҳ����
[ExecuteInEditMode]
// �ýű���Ҫ���ڴ�����������GameObject��
[RequireComponent(typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{

    // ��������Դ�������Ƿ����㣬��Start�е���
    protected void CheckResources()
    {
        bool isSupported = CheckSupport();

        if (isSupported == false)
        {
            NotSupported();
        }
    }

    // �жϵ�ǰƽ̨�Ƿ�֧����Ļ�����Ƿ�֧��ImageEffect��RenderTexture��
    protected bool CheckSupport()
    {
        if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            Debug.LogWarning("This platform does not support image effects or render textures.");
            return false;
        }

        return true;
    }

    protected void NotSupported()
    {
        enabled = false;
    }

    protected void Start()
    {
        CheckResources();
    }

    // ÿ����Ļ����Ч��ͨ����Ҫָ��һ��Shader������һ�����ڴ�����Ⱦ����Ĳ���
    // shader��ָ������Чʹ�õ�Shader
    // material�����ں��ڴ���Ĳ���
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        if (shader == null)
        {
            return null;
        }

        // ��ǰ�����Ѿ�ʹ������ЧShader
        if (shader.isSupported && material && material.shader == shader)
            return material;

        // ���Shader�Ƿ����
        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material)
                return material;
            else
                return null;
        }
    }
}