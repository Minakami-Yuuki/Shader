// 通过纹理存储RBBA值 来控制不同点的光照强度
Shader "Unlit/Chapter7-MaskTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 主纹理
        _MainTex ("Main Tex", 2D) = "white" {}
        // 法线纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 控制法线纹理影响程度的系数
        _BumpScale ("Bump Scale", Float) = 1.0
        // 高光反射遮罩纹理
        _SpecularMask ("Specular Mask", 2D) = "white" {}
        // 控制遮罩影响程度的系数
        _SpecularScale ("Specular Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            // _MainTex、_BumpMap和_SpecularMask共用同一套纹理属性变量_MainTex_ST
            // 意味着修改主纹理的平铺系数和偏移系数，会同时影响3个纹理的采样
            // 这样可以节省存储的纹理坐标数，减少差值寄存器的使用
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
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

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                // 使用宏，让后续可以调用rotation变量获取模型空间到
                // 切线空间的转换矩阵
                TANGENT_SPACE_ROTATION;
                // 获得切线空间的光照方向
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                // 获得切线空间的视角方向
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 从法线纹理中采样获得切线空间的法线
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                // 乘以影响程度系数_BumpScale
                tangentNormal.xy *= _BumpScale;
                // 因为最终法线需要归一化，所以由勾股定理求出z分量
                tangentNormal.z = sqrt(1.0 - saturate(
                        dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo
                        * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                // 对遮罩纹理进行采样，因为本案例中遮罩纹理的每个纹素的rgb分量
                // 都是一样的，表明了该点对应高光反射强度，
                // 所以仅适用r分量来计算掩码值
                fixed specularMask = tex2D(_SpecularMask, i.uv).r
                        * _SpecularScale;
                // 掩码值与最终求得的高光反射相乘，用以控制高光反射的强度
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
