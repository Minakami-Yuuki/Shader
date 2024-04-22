Shader "Unlit/Chapter6-BlinnPhong"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
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
                // 顶点着色器输出的世界法线
                float3 worldNormal : TEXCOORD0;
                // 顶点着色器输出的世界空间坐标
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 世界表面法线: 逆转置矩阵
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                // 世界观察坐标: 矩阵乘积
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // 对像素处理
            fixed4 frag (v2f i) : SV_Target
            {
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                // 法线归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                // 光照方向归一化
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // Lambert漫反射
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                // 摄像机视角
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // 半程向量 (入射光方向 和 视场角方向 的向量和)
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 高光反射公式: (C * Ks * pow(max(0, n * h), gloss))
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

                // 返回高光模型
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
Fallback "specular"
}
