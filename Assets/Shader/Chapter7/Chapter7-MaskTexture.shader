// 通过纹理存储RBBA值 来控制不同点的光照强度
Shader "Unlit/Chapter7-MaskTexture"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        // 主纹理
        _MainTex ("Main Tex", 2D) = "White" {}
        // 法线纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 法线纹理响应系数
        _BumpSclae ("Bump Scale", Float) = 1.0
        // 高光反射遮罩纹理
        _SpecularMask ("Specular Mask", 2D) = "White" {}
        // 高光纹理响应系数
        _SpecularScale ("Specular Mask", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                // 将法线转值切线空间的矩阵: rotation
                TANGENT_SPACE_ROTATION;

                // 切线空间的光照和视场角
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex).xyz);
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex).xyz);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 归一化
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 获得切线空间的法线
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                // 乘以响应系数
                tangentNormal.xy *= _BumpScale;
                // 分离z分量
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 光照模型
                // 主纹理反射率
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rbg * albedo
                                    * max(0, dot(tangentNormal, tangentLightDir));
                fixed3 halfDir = normalize(tangentNormal + tangentViewDir);
                // 遮罩纹理采用 因为当前每个纹理的rgb均相同 直接表示该点对应的高光反射强度
                // 所以直接采用 R 分量计算掩码值
                fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
                // 将掩码值作用于高光反射上
                fixed3 specular = _LightColor0.rgb * _Specular.rgb
                                    * pow(max(0, dot(tangentNormal, halfDir)), _Gloss)
                                    * specularMask;

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
