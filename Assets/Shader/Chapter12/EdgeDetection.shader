Shader "Unlit/EdgeDetection"
{
    Properties
    {
        // 主纹理
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 边缘显示程度
        _EdgeOnly ("Edge Only", Float) = 1.0
        // 边缘颜色
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        // 背景色
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            // 后置处理 保证处理结果能够写入缓冲区
            ZTest Always
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 卷积核
                half2 uv[9] : TEXCOORD0;
            };

            sampler2D _MainTex;
            // 主纹理像素大小 (例如: 512 * 512 的纹理像素大小为 1 / 512)
            // 利用纹素 在相邻区域内进行纹理采样时 计算各个相邻区域的坐标
            half4 _MainTex_TexelSize;
            fixed _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            // 明度 (固定)
            fixed4 luminance (fixed4 color)
            {
                return 0.2125 * color.r
                    + 0.7154 * color.g
                    + 0.0721 * color.b;
            }

            // Sobel算子
            half Sobel (v2f i)
            {
                // 右乘
                // 水平卷积核 (作用于竖直方向)
                const half Gx[9] = {
                    -1, -2, -1,
                     0,  0,  0,
                     1,  2,  1
                };
                // 竖直卷积核 (作用域水平方向)
                const half Gy[9] = {
                    -1,  0,  1,
                    -2,  0,  2,
                    -1,  0,  1
                };

                half texColor;
                half edgeX = 0;
                half edgeY = 0;

                // 进行卷积
                for (int it = 0; it < 9; it++)
                {
                    // 对明度进行采样
                    texColor = luminance(tex2D(_MainTex, i.uv[it]));
                    // 将明度值和卷积核Gx、Gy的权值相乘后 累加到各自的梯度值上
                    edgeX += texColor * Gx[it];
                    edgeY += texColor * Gy[it];
                }

                // 1 减去 水平和竖直的梯度值的绝对值 可以得到 边缘的梯度值
                half edge = 1 - abs(edgeX) - abs(edgeY);

                return edge;
            }

            // 使用内置appdata_img结构体
            // 只包含图像处理时必须的顶点坐标和坐标纹理等
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv = v.texcoord;

                // 获得图像周围一圈的纹理坐标 进行Sobel算子采样时需要
                // 范围 [-1, 1]
                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);

                return o;
            }

            // 进行Sobel算子采样
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算当前算子的图像边缘梯度
                half edge = Sobel(i);
                
                // 计算背景为原图 和 纯色下的颜色值
                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
                // 计算 _EdgeColor 和 背景色的颜色值
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
                // 混合计算叠加
                return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
            }
            
            ENDCG
        }
    }
    Fallback Off
}
