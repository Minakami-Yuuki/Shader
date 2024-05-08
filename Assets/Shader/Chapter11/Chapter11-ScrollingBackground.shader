Shader "Unlit/Chapter11-ScrollingBackground"
{
    Properties
    {
        // 第一层 (较远) 背景纹理
        _MainTex ("Base Layer (RGB)", 2D) = "white" {}
        // 第二层 (较近) 背景纹理
        _DetailTex ("Sub Layer (RGB)", 2D) = "white" {}
        // 第一层背景纹理的水平滚动速度
        _ScrollX ("Base Layer Scroll Speed", Float) = 1.0
        // 第二层背景纹理的水平滚动速度
        _Scorll2X ("Sub Layer Scroll Speed", Float) = 1.0
        // 控制纹理的整体亮度
        _Multiplier ("Layer Multiplier", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
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
                float4 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;
            
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 获得采样图片的缩放和平移
                // 返回数值的小数部分
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 纹理采样
                fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
                fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);

                // 根据第二层纹理的透明度 将两层的颜色进行混叠
                fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
                c.rgb *= _Multiplier;

                return c;
            }
            
            ENDCG
        }
    }
    Fallback "VertexLit"
}
