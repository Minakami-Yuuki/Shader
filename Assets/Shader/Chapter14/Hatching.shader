Shader "Unlit/Hatching"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _TileFactor ("Tile Factor", Float) = 1.0
        _Outline ("Outline", Range(0, 1)) = 0.1
        _Hatch0 ("Hatch 0", 2D) = "white" {}
        _Hatch1 ("Hatch 1", 2D) = "white" {}
        _Hatch2 ("Hatch 2", 2D) = "white" {}
        _Hatch3 ("Hatch 3", 2D) = "white" {}
        _Hatch4 ("Hatch 4", 2D) = "white" {}
        _Hatch5 ("Hatch 5", 2D) = "white" {}
    }
    SubShader
    {
       Tags
       {
           "RenderType" = "Opaque"
           "Queue" = "Geometry"
       }
       
       // 使用上一节定义的轮廓线 Pass
       UsePass "Unlit/ToonShading/OUTLINE"
       
       Pass
       {
           Tags
           {
               // 前置渲染
               "LightMode" = "ForwardBase"
           }
           
           CGPROGRAM

           #pragma vertex vert
           #pragma fragment frag

           // 前置光照
           #pragma multi_compile_fwdbase

           #include "UnityCG.cginc"
           #include "AutoLight.cginc"
           #include "Lighting.cginc"

           // 叠加色
           fixed4 _Color;
           // 纹理平铺系数 值越大 线条越密
           float _TileFactor;
           // 轮廓线粗细
           float _Outline;
           // 素描渲染时使用的不同密度的纹理 (密度依次增大) (定义权值)
           sampler2D _Hatch0;
           sampler2D _Hatch1;
           sampler2D _Hatch2;
           sampler2D _Hatch3;
           sampler2D _Hatch4;
           sampler2D _Hatch5;

           struct a2v
           {
               float4 vertex : POSITION;
               float2 texcoord : TEXCOORD0;
               float3 normal : NORMAL;
           };

           struct v2f
           {
               float4 pos : SV_POSITION;
               float2 uv : TEXCOORD0;
               // 素描纹理权重 (6个变量)
               fixed3 hatchWeights0 : TEXCOORD1;
               fixed3 hatchWeights1 : TEXCOORD2;
               fixed3 worldPos : TEXCOORD3;
               // 阴影采样坐标
               SHADOW_COORDS(4)
           };

           v2f vert (a2v v)
           {
               v2f o;
               o.pos = UnityObjectToClipPos(v.vertex);
               o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
               // _TileFactor控制采样纹理的屏幕系数
               o.uv = v.texcoord.xy * _TileFactor;

               // 归一化后的世界空间光照方向
               fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
               // 世界空间法线方向
               fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
               // 漫反射条件
               fixed3 diff = max(0, dot(worldLightDir, worldNormal));

               // 初始化权重
               o.hatchWeights0 = fixed3(0.0, 0.0, 0.0);
               o.hatchWeights1 = fixed3(0.0, 0.0, 0.0);

               // 根据点乘结果 范围为[0, 7] 划分7个子区间
               float hatchFactor = diff * 7.0;

               // 计算混合区间的纹理混合权重
               if (hatchFactor > 6.0)
               {
                   // 纯白色 权值为 0
               }
               // 采用第一个uv保存
               else if (hatchFactor > 5.0)
               {
                   o.hatchWeights0.x = hatchFactor - 5.0;
               }
               else if (hatchFactor > 4.0)
               {
                   o.hatchWeights0.x = hatchFactor - 4.0;
                   o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
               }
               else if (hatchFactor > 3.0)
               {
                   o.hatchWeights0.y = hatchFactor - 3.0;
                   o.hatchWeights0.z = 1 - o.hatchWeights0.y;
               }
               // 采用第二个uv保存
               else if (hatchFactor > 2.0)
                {
                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
                }
                else if (hatchFactor > 1.0)
                {
                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
                }
                else
                {
                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
                }

               // 计算阴影纹理的采样坐标
               TRANSFER_SHADOW(o);

               return o;
           }

           fixed4 frag (v2f i) : SV_Target
           {
               // 还原各素描纹理采样结果
                fixed4 hatchTex0 = tex2D(_Hatch0, i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_Hatch1, i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_Hatch2, i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_Hatch3, i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_Hatch4, i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_Hatch5, i.uv) * i.hatchWeights1.z;

               // 白色占比
               fixed whiteScale = 1.0
                            - i.hatchWeights0.x
                            - i.hatchWeights0.y
                            - i.hatchWeights0.z
                            - i.hatchWeights1.x
                            - i.hatchWeights1.y
                            - i.hatchWeights1.z;

               // 白色部分颜色值 (没有像素的地方默认白色)
               fixed4 whiteColor = fixed4(1.0, 1.0, 1.0, 1.0) * whiteScale;
               // 混合最终颜色
               fixed4 hatchColor = hatchTex0
                                 + hatchTex1
                                 + hatchTex2
                                 + hatchTex3
                                 + hatchTex4
                                 + hatchTex5
                                 + whiteColor;

               // 光照衰减
               UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

               // 返回漫反射的颜色
               return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
           }
           
           ENDCG
       }
    }
    Fallback "Diffuse"
}
