// 透明度混合的双面渲染
// 第一个 Pass 处理背面 第二个 Pass 处理正面 进行混合 形成全透明混合效果
Shader "Unlit/Chapter8-AlphaBlendBothSided"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }
        
        // 第一步渲染
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            
            // 进行正面剔除 只采用图元背面的渲染
            Cull Front
            
            // 关闭深度写入 (透明度测试不用关闭深度写入)
            ZWrite Off
            // 将原颜色 (片元着色器) 的混合因子设为 SrcAlpha
            // ⬇ 合成
            // 将目标颜色 (已存在颜色换成中的颜色) 的混合因子设为 OneMinusSrcAlpha
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 光照模型
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                // 最后添加透明通道 改变物体的透明度
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDCG
        }

        // 第二步渲染
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            
            // 进行背面剔除 只进行图元正面的渲染
            Cull Back
            
            // 关闭深度写入 (透明度测试不用关闭深度写入)
            ZWrite Off
            // 将原颜色 (片元着色器) 的混合因子设为 SrcAlpha
            // ⬇ 合成
            // 将目标颜色 (已存在颜色换成中的颜色) 的混合因子设为 OneMinusSrcAlpha
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 光照模型
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                // 最后添加透明通道 改变物体的透明度
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
