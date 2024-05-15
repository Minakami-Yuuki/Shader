Shader "Unlit/GaussianBlur"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        // 可复用的代码块
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        // 主纹理的纹素大小 利用纹素获得相邻区域坐标
        half4 _MainTex_TexelSize;
        float _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };
        
        // 因为从 vert --> frag 的差值是线性的 所以在顶点着色器中进行纹理坐标采样 可减少运算 提高性能
        v2f vertBlurVertical (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            // 一维纵向高斯核
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            // _BlurSize控制领域像素间的采用距离
            // _BlurSize越大 模糊度越高 但采样数不受影响
            // 但过大的_BlurSize会造成虚影
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

            return o;
        }

        v2f vertBlurHorizontal (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            // 一维纵向高斯核
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            // _BlurSize控制领域像素间的采用距离
            // _BlurSize越大 模糊度越高 但采样数不受影响
            // 但过大的_BlurSize会造成虚影
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;

            return o;
        }

        fixed4 fragBlur (v2f i) : SV_Target
        {
            // 3个高斯权重
            float weight[3] = {0.4026, 0.2442, 0.0545};
            // 权重和
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

            for (int it = 1; it < 3; it++)
            {
                sum += tex2D(_MainTex, i.uv[it]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[2 * it]).rgb * weight[it];
            }

            return fixed4(sum, 1.0);
        }
        ENDCG

        // 后期屏幕处理
        ZTest Always
        Cull Off
        ZWrite Off
        
        Pass
        {
            // 定义名称 其余Shader可直接通过名字调用
            Name "GAUSSIAN_BLUR_VERTICAL"
            
            CGPROGRAM
            // 定义着色器
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            
            ENDCG
        }

        Pass
        {
            // 定义名称 其余Shader可直接通过名字调用
            Name "GAUSSIAN_BLUR_HORIZONTAL"
            
            CGPROGRAM
            // 定义着色器
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            
            ENDCG
        }
    }
    Fallback Off
}
