// 开启深度写入 double pass 实现半透明效果
Shader "Unlit/Chapter8-AlphaBlendZWrite"
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
        
        // 只开启深度写入的 Pass
        Pass
        {
            ZWrite On
            // ColorMask 用于设置颜色的写掩码
            // ColorMask RGA | A | 0
            // 0 表示该 Pass 不写入任何颜色通道
            ColorMask 0
        }
        
        // 根据深度写入 在片元着色器进行透明混合渲染
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            ZWrite Off
            // 正常（Normal），即透明度混合
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM

            #pragma vertex vert;
            #pragma fragment frag;
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
                float2 uv : TEXCOORD3;
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
                // 初始化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 纹理采样
                fixed4 texColor = tex2D(_MainTex, i.uv);
                
                // 光照模型
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo
                            * max(0, dot(worldNormal, worldLightDir));

                // 进行透明混合
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            
            ENDCG
        }
    }
    Fallback "Diffuse" 
}
