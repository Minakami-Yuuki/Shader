Shader "Unlit/Dissolve"
{
    Properties
    {
        // 控制消融的程度 0为无 1为完全消融
        _BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0
        // 控制灼烧边缘的线宽 值越大 边缘蔓延范围越广
        _LineWidth ("Blur Line Width", Range(0.0, 2.0)) = 0.1
        // 物体原本的漫反射纹理
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 物体原本的法线纹理
        _BumpTex ("Normal Map", 2D) = "white" {}
        // 火焰边缘颜色 1
        _BurnFirstColor ("Burn First Color", Color) = (1.0, 0.0, 0.0, 1.0)
        // 火焰边缘颜色 2
        _BurnSecondColor ("Burn Second Color", Color) = (1.0, 0.0, 0.0, 1.0)
        // 消融效果的噪声纹理
        _BurnMap ("Burn Map", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            // 正面光照
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            
            // 双面渲染
            Cull Off
            
            CGPROGRAM

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpMap : TEXCOORD1;
                float2 uvBurnMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                // 阴影纹理坐标
                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;
            float _BurnAmount;
            float _LineWidth;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSceondColor;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 三张纹理的uv
                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                // 加载模型空间转切线空间矩阵
                TANGENT_SPACE_ROTATION;
                // 将光源方向从模型空间转切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                // 为得到阴影信息 需要计算世界空间下的顶点位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 计算阴影纹理的采样坐标
                TRANSFER_SHADOW(o)

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 消融噪声纹理采样
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

                // 裁切：阈值以下的r分量被丢弃 效果为0
                clip(burn.r - _BurnAmount);

                // 方向初始化
                // 切线空间的光源方向
                float3 tangentLightDir = normalize(i.lightDir);
                // 切线空间的法线方向
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));

                // 通过漫反射纹理采样活动的反射率
                fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb
                            * albedo
                            * max(0, dot(tangentNormal, tangentLightDir));

                // 在宽度_LineWidth的范围内模拟一个烧焦的颜色变化
                // 计算得到混合系数t
                // t = 1 表明当前像素位于消融的边界处
                // t = 0 表明当前像素位于未开始消融的地方
                fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
                // 根据消融的程度 获得烧焦的颜色
                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSceondColor, t);
                // 加深烧焦的颜色
                burnColor = pow(burnColor, 5);

                // 光照衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // 根据烧焦的颜色 在正常漫反射和烧焦颜色之间进行插值
                // 保证当 _BurnAmount = 0时 不进行任何消融效果处理
                fixed3 finalColor = lerp(ambient + diffuse * atten
                            , burnColor
                            , t * step(0.0001, _BurnAmount));

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }

        // 投射阴影的Pass
        // 因为被消融的像素不应该投射阴影
        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            struct v2f
            {
                // 内置宏 封装阴影投射
                V2F_SHADOW_CASTER;
                float2 uvBurnMap : TEXCOORD1;
            };

            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;
            float _BurnAmount;

            // 内置封装顶点和法线
            v2f vert (appdata_base v)
            {
                v2f o;

                // 内置宏 阴影投射的内置封装
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

                // 裁切投影阴影
                clip(burn.r - _BurnAmount);

                // 阴影投射内置封装
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
