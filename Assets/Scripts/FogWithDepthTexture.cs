using UnityEngine;

public class FogWithDepthTexture : PostEffectsBase
{
    // ����ЧShader
    public Shader fogShader;
    // ����Ч����
    private Material fogMaterial = null;
    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    // ��ȡ�����ز���
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

    // ���Transform
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

    // ���ܶ�
    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;
    // ����ɫ
    public Color fogColor = Color.white;
    // ��ʼ�߶�
    public float fogStart = 0.0f;
    // ��ֹ�߶�
    public float fogEnd = 2.0f;

    private void OnEnable()
    {
        // ��ȡ�������
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        // 4*4�����¼�ĸ���λ��
        Matrix4x4 frustumCorners = Matrix4x4.identity;

        // �������
        float fov = camera.fieldOfView;
        float near = camera.nearClipPlane;
        float aspect = camera.aspect;

        // ������ƽ��һ��߶�
        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        // ������ƽ�����ĵ����ϵ����� ����������ƽ��һ��Ŀ��Ⱦ���
        Vector3 toRight = cameraTransform.right * halfHeight * aspect;
        // ���ü�ƽ�����ĵ����ϵ����� �������ü�ƽ��һ��ĸ߶Ⱦ���
        Vector3 toTop = cameraTransform.up * halfHeight;

        // ���ϽǶ���λ��
        Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
        // ����������ԭ����ʹ�ù�ʽ����ϵ��
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
        material.SetMatrix("_ViewProjectionInverseMatrix", (camera.projectionMatrix * camera.worldToCameraMatrix).inverse);

        material.SetFloat("_FogDensity", fogDensity);
        material.SetColor("_FogColor", fogColor);
        material.SetFloat("_FogStart", fogStart);
        material.SetFloat("_FogEnd", fogEnd);

        Graphics.Blit(source, destination, material);
    }
}