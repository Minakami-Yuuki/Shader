// 采用纹理映射替代漫反射的颜色
Shader "Unlit/Chapter7-SingleTexture"
{
    Properties
    {
        // 叠加颜色 默认白色
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        // 纹理 类型为2D 没有纹理时 默认用白色覆盖物体表面
        _MainTex("Main Tex", 2D) = "white" {}
        // 高光颜色 默认白色
        _Specular("Specular", Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            // 默认前向光照
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            // 重定义变量
            fixed4 _Color;
            sampler2D _MainTex;
            // 和 _MainTex 配对的 纹理缩放(Scale) 和 纹理平移(translation) 可在Inspector中进行调节
            // 命名规范: 纹理变量名 + "_ST"
            // _MainTex_ST.xy: 存储缩放值
            // _MainTex_ST.zw: 存储偏移值
            fixed4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                // 原始纹理坐标
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                // 纹理坐标的uv值 可在片元着色器中进行纹理采样
                float2 uv : TEXCOORD2;
            };

            // a2v 将具体值转为世界空间坐标
            v2f vert(a2v v)
            {
                v2f o;
                // 将 顶点坐标 由模型转裁切空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 将 法线 由模型转世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 将 顶点坐标 由模型转世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 通过缩放和平移后的纹理坐标 (缩放乘 平移加)
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 也可以调用内置宏 TRANSFORM_TEX() 获得缩放和平移后的纹理UV值
                // 定义: #define TRANSFORM_TEX(tex, name) (tex.xy * name##_ST.xy + name##_ST.zw)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            // v2f 采用纹理映射替换漫反射
            fixed4 frag(v2f i) : SV_Target
            {
                // 法线归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界空间的光照方向 + 归一化
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 通过 tex2D() 根据当前坐标点的 uv值 获得当前点的纹理颜色 (纹理采样)
                // 乘以颜色属性得到反射率
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                // 获得当前反射率的环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                // 漫反射: 兰伯特反射公式(用 albedo 代替 Kd) (C * albedo * max(0, n * l))
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                // 视场角
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 半程向量
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 基于Blinn-Phong光照模型: C * Ks * pow(max(0, n * h), _Gloss)
                // LightColor0 为最亮光源 是ForwardBase的主要颜色光源
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    }
    // 高光兜底
    Fallback "Specular"
}
