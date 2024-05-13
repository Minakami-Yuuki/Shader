using UnityEngine;

// 编辑器状态下也可用
[ExecuteInEditMode]
// 该脚本需要绑定在带有相机组件的GameObject上
[RequireComponent(typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{

    // 检查各种资源和条件是否满足，在Start中调用
    protected void CheckResources()
    {
        bool isSupported = CheckSupport();

        if (isSupported == false)
        {
            NotSupported();
        }
    }

    // 判断当前平台是否支持屏幕后处理（是否支持ImageEffect和RenderTexture）
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

    // 每个屏幕后处理效果通常需要指定一个Shader来创建一个用于处理渲染纹理的材质
    // shader：指定该特效使用的Shader
    // material：用于后期处理的材质
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        if (shader == null)
        {
            return null;
        }

        // 当前材质已经使用了特效Shader
        if (shader.isSupported && material && material.shader == shader)
            return material;

        // 检查Shader是否可用
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