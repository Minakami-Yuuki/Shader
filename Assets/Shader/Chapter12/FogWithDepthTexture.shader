Shader "Unlit/FogWithDepthTexture"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 雾最大密度
        _FogDensity ("Fog Density", Float) = 1.0
        // 雾颜色
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        // 雾起点高度
        _FogStart ("Fog Start", Float) = 0.0
        // 雾终点高度
        _FogEnd ("Fog End", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        // 记录相机到画面的四个角的向量
        // 通过脚本直接传递
        float4x4 _FrustumCornersRay;

        sampler2D _MainTex;
        // 纹素
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        half _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        float _FogEnd;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
            float4 interpolatedRay : TEXCOORD2;
        };

        v2f vert (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            // 平台转换
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif

            // 使用索引值来获取 _FrustCornersRay中对应当前顶点的interpolatedRay值
            int index = 0;
            float x = v.texcoord.x;
            float y = v.texcoord.y;
            // 四边形网格 开销较小
            if (x < 0.5 && y < 0.5)
                index = 0;
            else if (x > 0.5 && y < 0.5)
                index = 1;
            else if (x > 0.5 && y > 0.5)
                index = 2;
            else
                index = 3;

            // 兼容不同平台
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                index = 3 - index;
            #endif

            o.interpolatedRay = _FrustumCornersRay[index];

            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            //深度纹理采样 并转化为视角空间下的线性深度值
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            // 基于线性深度值 得到当前像素对于相机位置的偏移 以此得到当前像素的世界位置
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

            // 基于y分量计算得到归一化的雾密度
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
            // 与雾最大密度相乘 得到实际雾密度
            fogDensity = saturate(fogDensity * _FogDensity);
            
            // 主纹理采样
            fixed4 finalColor = tex2D(_MainTex, i.uv);
            // 根据雾密度 在实际和雾之间进行插值
            finalColor.rgb = lerp(finalColor.rgb, _FogColor, fogDensity);

            return finalColor;
        }
        
        ENDCG
        
        // 雾特效Pass
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
