using UnityEngine;

// ���ڱ༭��ģʽ��ʹ��
[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour
{
    // ʹ�øýű����ɵĳ�������
    public Material material = null;

    // C#���ԣ��ɽ����еĴ����۵���������ע��
    #region Material properties

    // �����С
    [SerializeField, SetProperty("textureWidth")]
    private int m_textureWidth = 512;
    public int textureWidth
    {
        get { return m_textureWidth; }
        set
        {
            m_textureWidth = value;
            _UpdateMaterial();
        }
    }

    // ����ɫ
    [SerializeField, SetProperty("backgroundColor")]
    private Color m_backgroundColor = Color.white;
    public Color backgroundColor
    {
        get { return m_backgroundColor; }
        set
        {
            m_backgroundColor = value;
            _UpdateMaterial();
        }
    }

    // Բ����ɫ
    [SerializeField, SetProperty("circleColor")]
    private Color m_circleColor = Color.yellow;
    public Color circleColor
    {
        get { return m_circleColor; }
        set
        {
            m_circleColor = value;
            _UpdateMaterial();
        }
    }

    // ģ�����ӣ�ģ��Բ�α߽�
    [SerializeField, SetProperty("blurFactor")]
    private float m_blurFactor = 2.0f;
    public float blurFactor
    {
        get { return m_blurFactor; }
        set
        {
            m_blurFactor = value;
            _UpdateMaterial();
        }
    }
    #endregion

    // ���ɵĳ�������
    private Texture2D m_generatedTexture = null;

    private void Start()
    {
        if (material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if (renderer == null)
            {
                Debug.LogWarning("Cannot find a renderer");
                return;
            }

            material = renderer.sharedMaterial;
        }

        _UpdateMaterial();
    }

    // ���²�������
    private void _UpdateMaterial()
    {
        if (material != null)
        {
            m_generatedTexture = _GenerateProceduralTexture();
            material.SetTexture("_MainTex", m_generatedTexture);
        }
    }

    private Texture2D _GenerateProceduralTexture()
    {
        Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

        // ����Բ��Բ֮��ļ��
        float circleInterval = textureWidth / 4.0f;
        // ����Բ�İ뾶
        float radius = textureWidth / 10.0f;
        // ����ģ��ϵ��
        float edgeBlur = 1.0f / blurFactor;

        for (int w = 0; w < textureWidth; w++)
        {
            for (int h = 0; h < textureWidth; h++)
            {
                // ʹ�ñ�����ɫ���г�ʼ��
                Color pixel = backgroundColor;

                // ���λ�9��Բ
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        // ���㵱ǰ�����Ƶ�Բ��Բ��λ��
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));
                        // ���㵱ǰ������Բ�ĵľ���
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;
                        // ģ��Բ�ı߽�
                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f),
                                Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));
                        // ��֮ǰ�õ�����ɫ���л��
                        pixel = _MixColor(pixel, color, color.a);
                    }
                }

                proceduralTexture.SetPixel(w, h, pixel);
            }
        }

        proceduralTexture.Apply();
        return proceduralTexture;
    }

    // ����ShaderLab��lerp�﷨
    private Color _MixColor(Color color0, Color color1, float mixFactor)
    {
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
        return mixColor;
    }
}