Shader "Unlit/BrightnessSaturationAndContrast"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 可直接在脚本中调整 也可在shader中查看
        _Brightness ("Brightness", Float) = 1
        _Saturation ("Saturation", Float) = 1
        _Contrast ("Contrast", Float) = 1
    }
    SubShader
    {
        Pass
        {
            // 保证处理后的效果能够写入缓冲区
            ZTest Always
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            // 使用内置的 appdata_img 结构体 (在 unitycg 中)
            // 该结构体只包含图像处理时必须的顶点坐标和纹理坐标等 标量
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            // 调整亮度 饱和度 对比度
            fixed4 frag (v2f i) : SV_Target
            {
                // 纹理采样
                fixed4 renderTex = tex2D(_MainTex, i.uv);
                // 亮度
                fixed3 finalColor = renderTex.rgb * _Brightness;
                
                // 饱和度
                // 先计算 光亮度: 通过对每个颜色的分量乘以特定系数再相加
                fixed luminance = 0.2125 * renderTex.r
                                + 0.7154 * renderTex.g
                                + 0.721 * renderTex.b;
                // 得到饱和度为0的颜色值 (rgb相同 --- 纯色)
                fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
                // 通过 _Saturation 插值获得不同饱和度的颜色
                finalColor = lerp(luminanceColor, finalColor, _Saturation);

                // 饱和度
                // 先创建一个饱和度为0的颜色值
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                // 通过 _Contrast 插值获得不同对比度的颜色
                finalColor = lerp(avgColor, finalColor, _Contrast);

                return fixed4(finalColor, renderTex.a);
            }
            ENDCG
        }
    }
    // 关闭 Fallback
    Fallback Off
}
