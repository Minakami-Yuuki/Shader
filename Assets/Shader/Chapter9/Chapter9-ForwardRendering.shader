// 在前向渲染路径中，访问FB的5个属性: 位置、方向、颜色、强度以及衰减
Shader "Unlit/Chapter9-ForwardRendering"
{
    // 采用 BlinnPhong 代码
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        // Base pass
        Pass
        {
            // 设置为ForwardBase，处理环境光和第一个逐像素光照（平行光）
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            // 执行该指令，让前向渲染路径的光照衰减等变量可以被正确赋值
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                // Unity会选择最亮的平行光传递给Base Pass进行逐像素处理
                // 其他平行光会按照逐顶点或在Additional Pass中按逐像素的方式处理
                // 对于Base Pass来说，处理逐像素光源类型一定是平行光
                // 使用_WorldSpaceLightPos0得到这个平行光的方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 环境光只需要计算在Base Pass中计算一次即可
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 使用_LightColor0得到平行光的颜色和强度
                // （_LightColor0已经是颜色和强度相乘后的结果）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 因为平行光没有衰减，所以衰减值为1.0
                fixed atten = 1.0;

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            ENDCG
        }

        // Additional pass
        Pass
        {
            // 设置为ForwardAdd
            Tags { "LightMode" = "ForwardAdd" }

            // 开启混合模式，将帧缓冲中的颜色值和不同光照结果进行叠加
            // （Blend One One并不是唯一，也可以使用其他Blend指令，比如：Blend SrcAlpha One）
            Blend One One

            // Additional pass中的顶点、片元着色器代码是根据Base Pass中的代码复制修改得到的
            // 这些修改一般包括：去掉Base Pass中的环境光、自发光、逐顶点光照、SH光照的部分
            CGPROGRAM

            // 执行该指令，保证Additional Pass中访问到正确的光照变量
            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 去掉Base Pass中环境光

                fixed3 worldNormal = normalize(i.worldNormal);

                // 计算不同光源的方向
                #ifdef USING_DIRECTIONAL_LIGHT
                    // 平行光方向可以直接通过_WorldSpaceLightPos0.xyz得到
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    // 点光源或聚光灯，_WorldSpaceLightPos0表示世界空间下的光源位置
                    // 需要减去世界空间下的顶点位置才能得到光源方向
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif

                // 使用_LightColor0得到光源（可能是平行光、点光源或聚光灯）的颜色和强度
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 计算不同光源的衰减
                #ifdef USING_DIRECTIONAL_LIGHT
                    // 平行光不衰减
                    fixed atten = 1.0;
                #else
                    // 将片元的坐标由世界空间转到光源空间
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    // Unity选择使用一张纹理作为查找表（Lookup Table, LUT）
                    // 对衰减纹理进行采样得到衰减值
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif

                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Specular"
}
