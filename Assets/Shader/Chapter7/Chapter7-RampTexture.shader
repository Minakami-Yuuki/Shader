// 采用渐变纹理控制漫反射光照
Shader "Unlit/Chapter7-RampTexture"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        // 渐变纹理
        _RampTex ("Ramp Tex", 2D) = "White" {}
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed3 _Specular;
            float _Gloss;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                // 纹理坐标
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                // TRANSFORM_TEX宏 替代 计算缩放、平移后的纹理坐标
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 光照模型
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                // 采用半兰伯特模型 (计算漫反射)
                fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
                // 以 halfLambert 构建纹理坐标 对 _RampTex 进行渐变采样
                // _RampTex 是一个一维纹理 (即纵轴方向的颜色不变)
                // 所以 u v 均采用 halfLambert 进行采用
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;

                // Blinn-Phong光照模型 计算高光反射
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
