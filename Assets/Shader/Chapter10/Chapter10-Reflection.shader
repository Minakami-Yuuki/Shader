// 环境光反射
Shader "Unlit/Chapter10-Reflection"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 反射颜色
        _Reflectcolor ("Reflect Color", Color) = (1, 1, 1, 1)
        // 反射率
        _ReflectIntensity ("Reflect Intensity", Range(0, 1)) = 1
        // 反射的环境映射纹理
        _Cubemap ("Reflect Cubemap", Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags{ "RenderType" = "Opaque" }
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
                float3 worldRef1 : TEXCOORD3;
            };

            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectIntensity;
            samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                // 初始化
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                // 世界空间的反射方向
                // var1: 入射方向 var2: 法线方向  方向均向外
                o.worldRef1 = reflect(-o.worldViewDir, o.worldNormal);

                // 计算阴影纹理坐标
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
                // 采用 texCUBE 来对立方体纹理进行采样
                // var1: 存储纹理 var2： 反射方向
                fixed3 reflection = texCUBE(_Cubemap, i.worldRef1).rgb;
                // 光照衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                // 过渡
                fixed3 color = ambient + lerp(diffuse, reflection, _ReflectIntensity);

                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
}
