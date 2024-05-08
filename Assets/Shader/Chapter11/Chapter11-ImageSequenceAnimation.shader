// 爆炸特效
Shader "Unlit/Chapter11-ImageSequenceAnimation"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 关键帧图集
        _MainTex ("Image Sequence", 2D) = "white" {}
        // 图集横向关键帧数量
        _HorizontalAmount ("Horizontal Amount", Float) = 4
        // 图集纵向关键帧数量
        _VerticalAmount ("Vertical Amount", Float) = 4
        // 控制序列帧动画的播放速度
        _Speed ("Speed", Range(1, 100)) = 30
    }
    SubShader
    {
        // 序列帧一般是透明纹理 需要设置透明队列
        Tags 
        { 
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }
        
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            // 关闭深度写入 (要渲染透明物体)
            ZWrite Off
            // 设置混合模式
            Blend SrcAlpha OneMinusSrcAlpha
            
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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            half4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // _Time.y 自从场景加载后所经过的时间
                float time = floor(_Time.y * _Speed);
                // 行和列随时间变化
                float row = floor(time / _HorizontalAmount);
                float column = time - row * _VerticalAmount;

                // uv 随时间变化
                half2 uv = i.uv + half2(column, -row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                fixed4 c = tex2D(_MainTex, uv);
                c.rgb *= _Color;
                return c;

                // fixed4 col = tex2D(_MainTex, i.uv);
                // return col;
            }
            
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
