Shader "Unlit/Voronoise"
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // 随机马赛克效果
            float3 hash3(float2 p)
            {
                // 三通道颜色注入
                float3 q = float3(dot(p, float2(127.1, 311.7)),
                                  dot(p, float2(269.5, 183.3)),
                                  dot(p, float2(419.2, 371.9)));
                // 随机取值
                return frac(sin(q) * 43758.5453);
            }

            // 方格过度 + 模糊过度
            // x: 24倍uv  u: 表示方格的细胞格子变化  v: 表示模糊程度的过度
            float iqnoise(in float2 x, float u, float v)
            {
                // 向下取整
                float2 p = floor(x);
                // 取小数 --> 得到 一行24格方格
                float2 f = frac(x);
                // k: 模糊程度 (1, 64)倍
                float k = 1.0 + 63.0 * pow(1.0 - v, 4.0);
                // 加权卷积
                float va = 0.0;
                float wt = 0.0;
                // 5 * 5 卷积矩阵
                for (int i = -2; i <= 2; i++)
                {
                    for (int j = -2; j <= 2; j++)
                    {
                        // 当前的坐标点
                        float2 g = float2(float(i), float(j));
                        // 对当前像素周围的24个格子进行采样 （卷积）
                        float3 o = hash3(p + g) * float3(u, u, 1.0);
                        // 坐标间的偏移量
                        float2 r = g - f + o.xy;
                        float2 d = dot(r, r);
                        // 平滑移动过渡
                        float2 ww = pow(1.0 - smoothstep(0.0, 1.414, sqrt(d)), k);
                        va += o.z * ww;
                        wt += ww;
                    }
                }
                return va / wt;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * _ScreenParams / _ScreenParams.x;
                // 自上而下
                float2 p = 0.5 + 0.5 * cos(_Time.y + i.uv.xyx + float3(0, 4, 2));
                // float2 p = 0.5 - 0.5 * sin(_Time.y * float2(1.01, 1.71));
                
                return iqnoise(24.0 * uv, p.x, p.y);
            }
            ENDCG
        }
    }
}
