// 斯涅耳定律折射
Shader "Unlit/Chapter10-Refraction"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 折射颜色
        _RefractColor ("Refraction Color", Color) = (1, 1, 1, 1)
        // 折射程度
        _RefractIntensity ("Refraction Intensity", Range(0, 1)) = 1
        // 不同介质的折射比
        _RefractRatio ("Refraction Ratio", Range(0, 1)) = 0.5
        // 折射的环境纹理映射
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefractDir : TEXCOORD3;
            };
            
            fixed4 _Color;
            fixed4 _RefractColor;
            float _RefractIntensity;
            float _RefractRatio;
            samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                // 计算世界空间的折射方向
                // var1: 入射光线方向 需要归一化
                // var2: 表面法线方向 需要归一化
                // var3: 两种介质的折射比
                o.worldRefractDir = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

                // 阴影纹理表面
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                // 光照模型
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                // 调用 texCUBE 函数对立方体纹理进行采样 方向为折射前的入射方向
                fixed3 refraction = texCUBE(_Cubemap, i.worldRefractDir).rgb * _RefractColor.rgb;

                // 计算光照衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // 光照过渡
                fixed3 color = ambient + lerp(diffuse, refraction, _RefractIntensity);

                return fixed4(color, 1.0);
            }
            
            ENDCG
        }
    }
}
