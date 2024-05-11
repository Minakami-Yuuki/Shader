Shader "Unlit/Chapter11-Billboard"
{
    Properties
    {
        // 广告牌显示透明问题
        _MainTex ("Texture", 2D) = "white" {}
        // 整体颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 约束垂直方向的程度 (法线固定和向上固定)
        _VerticalBillboarding ("Vertical Restrains", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            // 禁用批处理
            "DisableBatching" = "True"
        }
        LOD 100

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            
            // 关闭深度写入
            ZWrite Off
            // 开启混合模式
            Blend SrcAlpha OneMinusSrcAlpha
            // 关闭剔除 (双面显示)
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _VerticalBillboarding;

            v2f vert (a2v v)
            {
                v2f o;
                // 选择模型空间的原点作为广告牌的锚点
                float3 center = float3(0, 0, 0);
                // 获得模型空间下的视角位置
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                // 法线方向
                float3 normalDir = viewer - center;
                // 如果_VerticalBillboarding为1，法线的期望方向为视角方向；
                // 如果_VerticalBillboarding为0，法线的期望方向Y值为0，则向上的方向固定为（0,1,0）;
                normalDir.y = normalDir.y * _VerticalBillboarding;
                // 归一化
                normalDir = normalize(normalDir);

                // 上方向: 为放置法线方向和向上方向平行 产生偏移量
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);

                // 右方向: 根据法线和上方向进行叉乘
                float3 rightDir = normalize(cross(upDir, normalDir));
                // 再根据精准的法线和右方向进行叉乘
                upDir = normalize(cross(normalDir, rightDir));

                // 得到当前顶点相对锚点的偏移
                float3 centerOffs = v.vertex.xyz - center;
                // 根据正交基矢量 得到新的顶点位置
                float3 localPos = center +
                                    rightDir * centerOffs.x +
                                    upDir * centerOffs.y +
                                    normalDir * centerOffs.z;
                // 模型空间的顶点转裁切空间
                o.pos = UnityObjectToClipPos(float4(localPos, 1));

                // 获得纹理平移和缩放
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 将uv铺至主纹理
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;
                return c;
            }
            
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
