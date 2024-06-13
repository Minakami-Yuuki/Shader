Shader "Unlit/FogWithNoise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 雾效浓度
        _FogDensity ("Fog Density", Float) = 1.0
        // 雾效颜色
        _FogColor ("For Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // 起始高度
        _FogStart ("Fog Start", Float) = 0.0
        // 终止高度
        _FogEnd ("For End", Float) = 1.0
        // 噪声纹理
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        // x轴速度
        _FogXSpeed ("Fog Horizontal Speed", Float) = 0.1
        // y轴速度
        _FogYSpeed ("Fog Vertical Speed", Float) = 0.1
        // 噪声纹理影响程度
        _NoiseAmount ("Noise Amount", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        // 纹理的四个方向
        float4x4 _FrustumCornersRay;

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        // 相机看到的法线纹理
        sampler2D _CameraDepthTexture;
        half _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        float _FogEnd;
        sampler2D _NoiseTex;
        half _FogXSpeed;
        half _FogYSpeed;
        half _NoiseAmount;

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
            // 深度纹理uv
            o.uv_depth = v.texcoord;

            // 兼容DirectX等平台 (原点坐标翻转)
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif

            // 使用索引值，来获取_FrustCornersRay中对应的行作为该顶点的interpolatedRay值
            int index = 0;
            float x = v.texcoord.x;
            float y = v.texcoord.y;
            // 一般使用if会造成比较大的性能问题，但本案例中用到的模型是一个四边形网格，质保函4个顶点，所以影响不大
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
            // 采样深度纹理 转换为线性值
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            // 基于深度值得到与相机之间的偏移 进而获得当前片元的世界坐标
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

            // 基于时间和噪声的偏移速度 得到噪声的偏移量
            float2 offset = _Time.y * float2(_FogXSpeed, _FogYSpeed);
            // 对噪声纹理的uv值偏移后进行采样（只取r分量），减去0.5后（为了让数值有正有负，有加强有衰减），
            // 并乘以噪声纹理影响强度得到噪声值
            float noise = (tex2D(_NoiseTex, i.uv + offset).r - 0.5) * _NoiseAmount;

            // 根据当前片元的高度以及雾效高度范围得到当前片元雾效的浓度比值
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
            // 将浓度比值乘以总的浓度，加上噪声的干扰，得到最终的雾效浓度
            fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));

            // 对主纹理进行采样
            fixed4 finalColor = tex2D(_MainTex, i.uv);
            // 通过雾效浓度，在原始颜色和雾效颜色之间进行差值，得到最终颜色
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

            return finalColor;
        }
        ENDCG

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            ENDCG
        }
    }
    Fallback Off
}
