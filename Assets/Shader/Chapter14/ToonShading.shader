Shader "Unlit/ToonShading"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0 ,1.0)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Ramp ("Ramp Texture", 2D) = "white" {}
        _Outline ("Outline", Range(0.0, 1.0)) = 0.1
        _OutlineColor ("Outline Color", Color) = (0.0, 0.0, 0.0, 1.0)
        _Specular ("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularScale ("Specular Scale", Range(0.0, 0.1)) = 0.01
    }
    SubShader
    {
        // 背面渲染
        Pass
        {
            // 命名空间 可复用
            Name "OUTLINE"
            // 只渲染背面面片
            Cull Front
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // 轮廓线宽度
            float _Outline;
            // 轮廓线颜色
            float4 _OutlineColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (a2v v)
            {
                v2f o;

                // 物体空间转世界空间的正交矩阵
                float4 worldPos = mul(UNITY_MATRIX_MV, v.vertex);
                // 逆转置矩阵
                float3 worldNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);

                // 将z分量设置为固定值 以降低内凹模型背面面片遮挡正面面片的可能性
                worldNormal.z = -0.5;
                // 顶点位置沿法线方向偏移一定距离
                worldPos = worldPos + float4(normalize(worldNormal), 0) * _Outline;
                // 投影矩阵
                o.pos = mul(UNITY_MATRIX_P, worldPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(_OutlineColor.rgb, 1);
            }
            
            ENDCG
        }

        // 正面渲染
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            
            // 只渲染正面
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            // 控制漫反射色调的渐变纹理
            sampler2D _Ramp;
            // 高光颜色
            float4 _Specular;
            // 控制高光反射的阈值
            float _SpecularScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert (a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                // 世界空间法线方向
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                // 世界空间顶点位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 统一归一化
                // 世界法线方向
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界光照方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 世界视角方向
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 计算半程向量 (用于后面的 Blinn-Phong高光)
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                // 主纹理采样
                fixed4 c = tex2D(_MainTex, i.uv);
                // 叠加颜色
                fixed3 albedo = c.rgb * _Color.rgb;

                // 光照模型
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                // 光照衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // 半兰伯特漫反射
                // 光照颜色 * 主纹理颜色 * 漫反射色调控制
                fixed diff = dot(worldNormal, worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;
                fixed3 diffuse = _LightColor0.rgb
                                * albedo
                                * tex2D(_Ramp, float2(diff, diff)).rgb;

                // 高光反射
                fixed spec = dot(worldNormal, worldHalfDir);
                // 通过 fwidth() 让w被设置为一个很小的值
                // fwidth(v) = abs(ddx(v))+ abs(ddy(v)) 用于计算像素间的距离 (关联度)
                fixed w = fwidth(spec) * 2.0;
                // 控制高光渐变 (小幅度渐变)
                float stepFactor = smoothstep(-w, w, spec + _SpecularScale - 1);
                // 最后采用 step() 完全消除_SpecularScale为0时的高光反射光照 (Blinn-Phong)
                fixed3 specular = _Specular.rgb
                                * lerp(0, 1, stepFactor)
                                * step(0.0001, _SpecularScale);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Diffuse"
}
