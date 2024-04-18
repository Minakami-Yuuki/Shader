Shader "Unlit/Chaper6-HalfLambert"
{
    Properties
    {
       _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            // 应用前向主光照
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = glstate_lightmodel_ambient;
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // half-Lambert = C * Kd * (a(n * l), + b)  || a = b = 0.5
                fixed halfLambet = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambet;

                // 输出半兰伯特颜色值 (环境光 + 漫反射)
                fixed3 color = ambient + diffuse;
                return fixed4(color, 1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Diffuse"
}
