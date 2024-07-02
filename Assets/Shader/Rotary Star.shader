Shader "Unlit/Rotary Star"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // --- 自定义变量 ---
            // 粒子数
            #define NUM_PRATICLES 200.0
            // 粒子半径
            #define RADIUS 0.015
            // 粒子外发光
            #define GLOW 0.5

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // 画出图形并让其随时间进行运动
            float3 Orb (float2 uv, float3 color, float radius, float offset)
            {
                float2 position = float2(
                    sin(offset * (_Time.y + 30.0)),
                    cos(offset * (_Time.y + 30.0)));
                position *= sin((_Time.y) - offset) * cos(offset);
                radius = radius * offset;

                // 通过计算uv坐标和上面的Position间的距离来描绘图形
                // 用 radius 来控制圆形的大小
                float dist = radius / distance(uv, position);
                // 缩小圆形大小
                return color * pow(dist, 1.0 / GLOW); 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 屏幕宽高比
                half ratio = _ScreenParams.x / _ScreenParams.y;
                // 将 uv (0, 1) -> (-1, 1) 起点放置于屏幕中心
                half2 centerUV = i.uv * 2 - 1;
                // 保持UV不受屏幕比例的影响而变形
                centerUV.x *= ratio;

                float3 pixel, color = 0;

                // 颜色随时间变化
                color.r = (sin(_Time.y * 0.55) + 1.5) * 0.4;
                color.g = (sin(_Time.y * 0.34) + 2.0) * 0.4;
                color.b = (sin(_Time.y * 0.31) + 4.5) * 0.3;

                // 圆形大小
                for (int i = 0; i < NUM_PRATICLES; i++)
                {
                    pixel += Orb(centerUV, color, RADIUS, i / NUM_PRATICLES);
                }
                // 圆形从中心到四周的颜色衰减
                float4 fragColor = lerp(
                    float4(centerUV, 0.8+0.5*sin(_Time.y), 1.0),
                    float4(pixel, 1.0),
                    0.8);

                return fragColor;
            }
            
            ENDCG
        }
    }
}
