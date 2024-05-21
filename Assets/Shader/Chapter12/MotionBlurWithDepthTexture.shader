Shader "Unlit/MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        // 纹素
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        float4x4 _CurrentViewProjectionInverseMatrix;
        float4x4 _PreviousViewProjectionMatrix;
        half _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
        };

        v2f vert (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            // 不同平台处理图像翻转问题
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif

            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            // 深度纹理采样 返回纹理采样结果的r通道
            float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
            // 获取投影空间下的坐标 (数值控制在[-1, 1])
            float4 H = float4(i.uv.x * 2 - 1,
                              i.uv.y * 2 - 1,
                              d * 2 - 1,
                              1);
            // 通过视角 * 投影矩阵的逆矩阵 得到视角空间下的坐标
            float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
            // 除以w分量 将其转为世界坐标
            float4 worldPos = D / D.w;

            // 当前帧投影空间下的坐标
            float4 currentPos = H;
            // 将世界坐标通过上一帧的视角 * 投影矩阵 转换为上一帧的投影空间下的坐标
            float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
            // 除以W分量 转换为世界坐标
            previousPos /= previousPos.w;

            // 通过前后两帧的投影空间的差值 得到当前像素的速度
            float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;

            float2 uv = i.uv;
            float4 c = tex2D(_MainTex, uv);
            uv += velocity * _BlurSize;

            // 额外叠加两次单位像素偏移后的纹理采样值
            for (int it = 1; it < 3; it++, uv += velocity * _BlurSize)
            {
                float4 currentColor = tex2D(_MainTex, uv);
                c += currentColor;
            }

            // 颜色均值
            c /= 3;

            // 返回颜色均值作为输出颜色
            return fixed4(c.rgb, 1.0);
        }
        
        ENDCG

        Pass
        {
            // 屏幕后处理
            ZTest Always
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    Fallback Off
}
