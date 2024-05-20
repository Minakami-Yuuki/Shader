Shader "Unlit/MotionBlur"
{
    Properties
    {
    // 主纹理 
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 混合图片时使用的系数
        _BlurAmount ("Blur Amount", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float _BlurAmount;

        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        v2f vert (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        // 对图像进行采样 将A通道设为_BlurAmount 方便后面混合时进行控制
        fixed4 fragRGB (v2f i) : SV_Target
        {
            return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
        }

        // 返回采样结果
        half4 fragA (v2f i) : SV_Target
        {
            return tex2D(_MainTex, i.uv);
        }
        
        ENDCG

        // 屏幕后处理
        ZTest Always
        Cull Off
        ZWrite Off

        // 用于更新渲染纹理的RGB通道
        // 通过BlurAmount设置A通道来混合图像
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            ENDCG
        }

        Pass
        {
            Blend One Zero
            ColorMask A
            
            CGPROGRAM
            #pragma vertex vert;
            #pragma fragment fragA;
            ENDCG
        }
    }
    Fallback Off
}
