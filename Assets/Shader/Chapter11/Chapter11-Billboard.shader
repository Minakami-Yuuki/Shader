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
            }
            
            ENDCG
        }
    }
}
