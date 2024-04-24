// 世界空间的法线贴图
Shader "Unlit/Chapter7-NormalMapWorldSpace"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "White" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
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
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                fixed4 vertex : POSITION;
                float3 normal : NORMAL;
                // xyz表示坐标 w表示方向
                float4 tangent : TANGENT;
                // 原始纹理坐标
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                // 因为插值中最多只能存储 float4 大小的变量
                // 所以将每一行矩阵都存为 float4 大小 (x y z)
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };

            // 顶点着色器
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 缩放与位移 主纹理与法线纹理
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // 切线空间 转 世界空间
                // 将顶点坐标由 模型空间 转为 世界空间
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 将法线方向由 模型空间 转为 世界空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // 将切线方向由 模型空间 转为 世界空间
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // TBN叉乘 (带上正方向)
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 计算 切线空间 转 世界空间的矩阵 并保存至 TtoW 中
                // w 存储 世界坐标分量
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 拆分w分量 获得世界坐标下的当前坐标
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                // 光照方向
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                // 视场角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                // 反映射采样
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                // 将获得的法线由 切线空间 转 世界空间 (乘以转换矩阵)
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

                // 光照模型
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Specular"
}
