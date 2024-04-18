Shader "Unlit/Chapter-6-DiffusePixelLevel"
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 世界空间的法线 用于在片元着色器中编写光照计算逻辑
                fixed3 worldNormal : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 将法线从模型转世界空间 采用逆矩阵
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                return o;
            }

            // 片元着色器进行漫反射着色
            fixed4 frag(v2f i) : SV_Target
            {
                // 获取环境光颜色 (RGB)
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                // 法线矢量归一化 (获得法线方向)
                fixed3 worldNormal = normalize(i.worldNormal);
                // 入射光光照归一化 (获得入射光方向)
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 计算漫反射颜色值 (Diffuse = C * Kd * max(0, n * l))
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // 与环境光进行叠加输出颜色
                fixed3 color = ambient + diffuse;
                return fixed4(color, 1.0);
                // 逐像素渲染比逐顶点渲染更为平滑
            }
            
            ENDCG
        }
    }

    Fallback "Diffuse"
}
