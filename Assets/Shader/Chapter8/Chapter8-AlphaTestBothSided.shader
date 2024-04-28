// 双面剔除测试
Shader "Unlit/Chapter-8AlphaTestBothSided"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue" = "AlphaTest"
            "IgnoreProjector" = "True"
            "RenderType" = "TransparentCutoff"
        }
        
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            
            // 关闭剔除功能
            Cull Off
//            Cull Back
//            Cull Front
            
            CGPROGRAM

            #pragma vertex vert;
            #pragma fragment frag;
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

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

                // 纹理采样
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 透明度剔除
                clip(texColor.a - _Cutoff);
                
                // 光照模型
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo
                            * max(0, dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, 1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Transparent/Cutout/VertexLit"
}
