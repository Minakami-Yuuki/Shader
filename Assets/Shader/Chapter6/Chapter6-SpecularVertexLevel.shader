Shader "Unlit/Chapter6-SpecularVertexLevel"
{
    Properties
    {
        // 漫反射
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        // 高光 默认白色
        _Specular("Specular", Color) = (1, 1, 1, 1)
        // 光泽度 (滑动条)
        _Gloss("Gloss", Range(8.0, 256)) = 20
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

            // 颜色属性
            fixed4 _Diffuse;
            fixed4 _Specular;
            // 光泽度属性
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                // 输出当前顶点的颜色值
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                // 物体转世界法线 单位向量 逆转置矩阵
                fixed3 worldNormal = normalize(mul(v.normal, (fixed3x3)unity_WorldToObject));
                // 入射光 单位向量
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 采用Lambert光照模型 (C * Kd * max(0, n * l))
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                // 采用 reflect() 生成反射光 并归一化
                // reflect() 要求由光源指向焦点处 --> 入射光方向为负值
                // reflectDir = 2 * (n * l) * n - l
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                // 通过Unity内置变量_WorldSpaceCameraPos得到世界空间中的相机位置
                // mul(unity_ObjectToWorld, v.vertex): 使物体坐标转到世界坐标
                // 通过与世界空间中的顶点坐标进行相减，得到世界空间下的视角方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
                // 高光反射公式: (C * Ks * pow(max(0, r * v), gloss))
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                // 高光模型: Diffuse + Ambient + Specular
                o.color = ambient + diffuse + specular;
                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            
            ENDCG
        }
    }
// 高光兜底
Fallback "Specular"
}
