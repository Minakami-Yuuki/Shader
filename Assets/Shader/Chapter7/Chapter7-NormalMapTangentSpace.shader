Shader "Unlit/Chapter7-NormalMapTangentSpace"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        // 法线纹理 
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 控制凹凸程度
        _BumpScale ("Bump Scale", Float) = 1.0
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
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
            fixed4 _Color;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            
            float4 _Specular;
            float _Gloss;

            struct a2v
            {
                // float4 是为了区分 点 和 向量
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                // 切线方向: floar4 类型
                // 使用第四个值 tangent.w 来决定切线空间的第三个坐标轴 (TBN) 的方向
                float4 tangent : TANGENT;
                // 原始纹理坐标
                float3 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // uv.xy: 主纹理坐标 (切线空间) uv.zw: 法线纹理坐标
                float4 uv : TEXCOORD0;
                // 变换到切线空间的光照方向
                float3 lightDir : TEXCOORD1;
                // 变换到切线空间的视场角防线
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 主纹理uv值
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 法线纹理uv值
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // 已知 Tangent(切线) 和 Normal(法线) 可通过叉乘来计算出第三条坐标轴 Binormal
                float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz));
                // 构建从 模型空间 向 切线空间 进行转换的三维矩阵 (xyz: TBN)
                float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

                // 也可采用内置宏 (UnityCG.cgnic) 可直接替换上面两个语法
                // (即: 从模型空间转换至切线空间)
                // TANGENT_SPACE_ROTATION;

                // 将光照方向由模型空间转换到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex).xyz);
                // 将视场角由模型空间转换到切线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex).xyz);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 归一化
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 对法线进行纹理采样
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;
                // 若 _BumpMap 未标记为 "Normal Map"
                // 为了使坐标范围限定于 [0, 1] 需要手动进行切线空间的法线映射
                // 即将 纹理坐标[-1, 1] --> 切线坐标[0, 1]
                // Pixel = (N + 1) / 2
                // tangentNormal.xy = (packedNormal * 2 - 1);

                // 若 _BumpMap 被标记为 "Normal Map"
                // 再进行手动计算会导致 _BumpMap 的rgb分量出错
                // 因为 Unity会自动进行压缩计算 使得 _BumpMap 自动映射 不再是切线空间的法线方向xyz
                // 可直接调用 UnpackNormal 来进行反映射 进而得到切线空间的法线纹理坐标
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                // 将法线归一化 得到 z分量 (保证 > 0)
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 再切线空间的各类光照条件
                // 纹理坐标的反射率
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
                // 半程向量
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                // 镜面反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
                
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
