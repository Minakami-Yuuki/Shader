Shader "Unlit/RandomCircle"
{
    Properties
    {
        
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
            #include  "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // 随机函数
            float Rand(float2 c)
            {
                return frac(sin(dot(c.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            // 旋转网格
            fixed2 Rotate(float2 p, float t)
            {
                // 0.05s
                p = cos(t) * p + sin(t) * float2(p.y, -p.x);
                return p;
            }
            
            // 制作网格 (画布颜色 中心坐标 圆颜色)
            fixed3 DrawCircle(fixed3 color, float2 p, float3 c)
            {
                // 以 450 像素/单位 来归一化划分网格
                float wrap = 450.0;
                // 切分网格 (+ 0.5是为了提高对比度)
                // Y轴切分
                if (fmod(floor(p.y / wrap + 0.5), 2.0) == 0.0)
                {
                    // X轴切分
                    p.x += wrap * 0.5;
                }
                // 继续细化切分
                float2 pTemp = p + 0.5 * wrap;
                float2 p2 = pTemp - wrap * floor(pTemp / wrap) - 0.5 * wrap;

                // 随机明暗对比度 
                float2 cell = floor(p / wrap + 0.5);
                float cellR = Rand(cell);
                
                // 圆的颜色
                // 降低圆饱和度和对比度
                c *= frac(cellR * 3.33 + 3.33);
                // 圆半径 [30, 70]
                float radius = lerp(30.0, 70.0, cellR);
                // 拉伸圆 使其略微不规则
                p2.x *= lerp(0.9, 1.1, frac(cellR * 11.13 + 11.13));
                p2.y *= lerp(0.9, 1.1, frac(cellR * 17.17 + 17.17));
                // 画圆 + 圆圈发光:
                // 获得圆心周围的渐变值
                float sdf = (length(p2 / radius) - 1.0) * radius;
                // 边缘柔和过度并反向
                float circle = 1.0 - smoothstep(0.0, 1.0, sdf * 0.04);
                // 将范围缩小并反向选择边缘
                float glow = exp(-sdf * 0.025) * 0.3 * (1.0 - circle);
                color += c * (circle + glow);

                return color;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                // bg: 从窗口的上方至下方
                fixed3 color = lerp(fixed3(0.3, 0.1, 0.3), fixed3(0.1, 0.4, 0.5), i.uv.y);
                // 屏幕的UV空间 -- 将p定于屏幕中心
                float2 p = 2.0 * (i.uv * _ScreenParams.xy) - _ScreenParams.xy;
                // 延时
                float time = _Time.x;
                
                // 旋转图层 + 画圆 (共5层)
                float2 p1 = Rotate(p, 0.2 + time * 0.003);
                fixed3 color1 = DrawCircle(color, p1 + float2(-500.0 * time + 0.0, 0.0), 3.0 *float3(0.4, 0.1, 0.2));
                float2 p2 = Rotate(p1, 0.3 - time * 0.5);
                fixed3 color2 = DrawCircle(color1, p2 + float2(-700.0 * time + 33.0, -33.0), 3.5 * float3(0.6, 0.4, 0.2));
                float2 p3 = Rotate(p2, 0.5 + time * 0.7);
                fixed3 color3 = DrawCircle(color2, p3 + float2(-600.0 * time + 55.0, 55.0), 3.0 * float3(0.4, 0.3, 0.2));
                float2 p4 = Rotate(p3, 0.9 - time * 0.3);
                fixed3 color4 = DrawCircle(color3, p4 + float2(-250.0 * time + 77.0, 77.0), 3.0 * float3(0.4, 0.2, 0.1));
                float2 p5 = Rotate(p4, 0.0 + time * 0.5);
                fixed3 color5 = DrawCircle(color4, p5 + float2(-150.0 * time + 99.0, 99.0), 3.0 * float3(0.2, 0.0, 0.4));
                
                return fixed4(color5, 1.0);
                // return float4(p, 0, 1);
            }
            ENDCG
        }
    }
}
