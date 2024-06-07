Shader "Unlit/WaterWave"
{
    Properties
    {
        // 水面颜色
        _Color ("Main Color", Color) = (0.0, 0.15, 0.115, 1.0)
        // 水面博文材质纹理 默认白色
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 由噪声纹理生成的法线纹理
        _WaveMap ("Wave Map", 2D) = "bump" {}
        // 用于模拟反射的立方体纹理
        _CubeMap ("Environment Map", Cube) = "SkyBox" {}
        // 法线纹理在x方向上的平移速度
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
        // 法线纹理在x方向上的平移速度
        _WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
        // 控制模拟折射时的扭曲度
        _Distortion ("Distortion", Range(0, 100)) = 10
    }
    SubShader
    {
        Tags
        {
            // 确保水面被渲染时 其他所有不透明物体均在屏幕上
            "Queue" = "Transparent"
            "RenderType" = "Opaque"
        }
        
        // 获取屏幕图像 Pass
        GrabPass
        {
            // 定义名称
            "_RefractionTex"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 当前片元对应屏幕图像的位置
                float4 srcPos : TEXCOORD0;
                // uv: xy存储水面纹理uv zw存储噪声法线纹理uv
                float4 uv : TEXCOORD1;
                // 切线空间转世界空间矩阵 (3 × 3)
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            // 立方体纹理 用于反射周边环境
            samplerCUBE _CubeMap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            float _Distortion;
            sampler2D _RefractionTex;
            // 折射纹理的纹素大小
            // 可用于图像采样偏移
            float4 _RefractionTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 内置宏 获得当前顶点对应的屏幕空间坐标
                o.srcPos = ComputeGrabScreenPos(o.pos);

                // 水面波纹纹理uv
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);

                // 当前顶点在世界空间下的坐标
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 世界空间法线方向
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // 世界空间切线方向
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // TBN 三者垂直 叉乘
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 构建切线空间转世界空间的矩阵
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 片元在世界空间的坐标
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                // 世界空间的视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                // 通过时间以及uv偏移的速度 得到噪声法线纹理的uv偏移量
                float2 waveUvOffset = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
                // 两次采样 模拟两层交叉水波效果
                fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + waveUvOffset)).rgb;
                fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - waveUvOffset)).rgb;
                // 相加归一化得到 切线空间下的法线方向
                fixed3 bump = normalize(bump1 + bump2);

                // 基于法线方向的xy分量乘以折射程度系数 再乘以折射纹素 得到折射纹理偏移
                float2 refractOffset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                // 偏移量乘以屏幕空间的z值 模拟深度越大 折射程度越大的效果
                i.srcPos.xy = i.srcPos.xy + refractOffset * i.srcPos.z;
                // 对屏幕空间坐标进行透视除法后 对折射纹理进行采样
                fixed3 refractColor = tex2D(_RefractionTex, i.srcPos.xy / i.srcPos.w);

                // 将法线由切线空间转换到世界空间
                bump = normalize(half3(dot(i.TtoW0.xyz, bump),
                                       dot(i.TtoW1.xyz, bump),
                                       dot(i.TtoW2.xyz, bump)));
                // 基于uv偏移量 对水面波纹纹理采样
                fixed4 texColor = tex2D(_MainTex, i.uv.xy + waveUvOffset);
                // 获得反射方向
                fixed3 reflectDir = reflect(-viewDir, bump);
                // 对立方体纹理进行采样
                fixed3 reflectColor = texCUBE(_CubeMap, reflectDir).rgb *
                                        texColor.rgb *
                                            _Color.rgb;
                // 计算菲涅尔系数
                fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
                // 将反射颜色和折射颜色进行混合 获得最终的颜色
                fixed3 finalColor = reflectColor * fresnel + refractColor * (1.0 - fresnel);

                return fixed4(finalColor, 1.0);
            }
            
            ENDCG
        }
    }
    // 不投射阴影 (防止水面反光不透亮)
    Fallback Off
}
