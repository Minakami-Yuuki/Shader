Shader "Unlit/Chapter6-DiffuseVertexLevel"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Pass
        {
            // LightMode 用于定义当前 Pass 在 Unity 的光照流水线中的角色
            // 应用前向主光照
            Tags {"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // 添加 Unity 内置变量
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            
            struct a2v
            {
                // 顶点坐标
                float4 vertex : POSITION;
                // 顶点法线
                float4 normal : NORMAL;
            };

            struct v2f
            {
                // 顶点着色器输出坐标
                float4 pos : SV_POSITION;
                // 顶点着色器输出颜色
                fixed3 color : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                // 模型转裁切空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 内置环境光颜色值
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
                // 将法线从模型转世界空间 并进行归一化 采用逆矩阵
                // (前三行/列: 3 × 3)
                // v.normal = mul(unity_ObjectToWorld,v.normal); (交换相乘顺序)
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                // 对平行光光源方向进行归一化
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 漫反射颜色值: (diffuse = C * Kd * max(0, n * l)) --- saturate(): [0, 1]
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));
                // 光照模型: 环境光 + 漫反射
                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 输出光照颜色
                return fixed4(i.color, 1.0);
            }
            
            ENDCG
        }
    }

    // 保底着色器
    Fallback "Diffuse"
}
