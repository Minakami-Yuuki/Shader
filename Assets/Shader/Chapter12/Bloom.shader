Shader "Unlit/Bloom"
{
    Properties
    {
        // 主纹理
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 高斯模糊后的较亮区域
        _Bloom ("Bloom (RGB)", 2D) = "black" {}
        // 提取较亮区域使用的阈值
        _LuminanceThreshold ("Luminance Threshold", Float) = 0.5
        // 控制不同迭代之间高斯模糊的模糊区域范围
        _BlurSize ("Blur Size", Float) = 1.0
    }

    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        // 主纹理的纹素大小（例如：一张512 * 512的纹理，纹素大小为1/512）
        // 利用纹素，做相邻区域内纹理采样时，计算各相邻区域的纹理坐标
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed luminance(fixed4 color)
        {
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        // 截取大于阈值部分的明度
        fixed4 fragExtractBright(v2f i) : SV_Target
        {
            fixed4 c = tex2D(_MainTex, i.uv);
            fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
            return c * val;
        }


        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            // 使用half4，记录两套UV纹理
            half4 uv : TEXCOORD0;
        };

        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;
            o.pos = UnityObjectToClipPos(v.vertex);
            // 主纹理坐标
            o.uv.xy = v.texcoord;
            // Bloom纹理坐标
            o.uv.zw = v.texcoord;

// 对纹理坐标进行平台差异化处理（不同平台纹理坐标方向不同）
#if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0.0)
                o.uv.w = 1.0 - o.uv.w;
#endif

            return o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }

        ENDCG

        // 屏幕后处理“标配”
        ZTest Always
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM

            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright

            ENDCG
        }

        // 使用上一节高斯纹理的纵向处理Pass
        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
        // 使用上一节高斯纹理的横向处理Pass
        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"

        Pass
        {
            CGPROGRAM

            #pragma vertex vertBloom
            #pragma fragment fragBloom

            ENDCG
        }
    }
    Fallback Off
}
