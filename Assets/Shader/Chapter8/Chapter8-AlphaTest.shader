Shader "Unlit/Chapter8-AlphaTest"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        // 透明度测试阈值
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            // 渲染队列
            "Queue" = "AlphaTest"       
            // 让当前Shader不受投射器影响
            "IgnoreProjector" = "True"
            // 让Unity把当前的Shader归入到提前定义的 TransparentCutout 组
            "RenderType" = "TransparentCutout"
        }  
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // 内置光照
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // TRANSFORM_TEX宏 替代 计算缩放、平移后的纹理坐标
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 纹理采样 获得纹理上每一点的颜色值
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 透明度测试: 即透明度 < _Curoff 的值会被丢弃
                // 等同于 if ((texColor.a - _Cutoff) < 0.0)
                // {
                //      discard; // 剔除操作
                // }
                clip(texColor.a - _Cutoff);

                // 光照模型
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo
                            * max(0, dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, 1.0);
            }
            
            ENDCG
        }
    }
    // 使用内置 VertexLit Shader 兜底
    Fallback "Transparent/Cutout/VertexLit"
}
