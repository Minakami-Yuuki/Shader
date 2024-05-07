// 菲涅尔反射: 部分反射 部分折射
Shader "Unlit/Chapter10-Fresnel"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // Schlick 菲涅尔近似等式的反射系数
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 0.5
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}
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
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldReflectDir : TEXCOORD3;
            };

            fixed4 _Color;
            float _FresnelScale;
            samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldReflectDir = reflect(-o.worldViewDir, o.worldNormal);

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
                // 光照衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                // 反射采样
                fixed3 reflection = texCUBE(_Cubemap, i.worldReflectDir).rgb;
                // 菲涅尔系数
                // Schlick-F 方程: F + (1 - F) * pow((1 - view * normal), 5)
                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel));

                return fixed4(color, 1.0);
            }
            
            ENDCG
        }
    }
}
