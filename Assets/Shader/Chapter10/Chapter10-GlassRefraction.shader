Shader "Unlit/Chapter10-GlassRefraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 玻璃的法线纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 模拟反射的环境纹理
        _Cubemap("Environment Cubemap", Cube) = "_Skybox" {}
        // 模拟折射时图像的扭曲程度
        _Distortion ("Distortion", Range(0, 100)) = 10
        // 控制折射程度，1：只包括折射
        _RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags {
            // 额外设置透明队列
            "Queue"="Transparent"
            // 没有使用Transparent，而使用Opaque，是为了在使用着色器替换时，
            // 该物体可以在需要时被正确渲染，
            // 这通常发生在需要得到摄像机的深度和法线纹理时（13章会学到）
            "RenderType"="Opaque"
        }
        LOD 100

        // 使用关键词GrabPass定义一个抓取屏幕图像的Pass
        // 内部字符串决定了图像会被存入哪个纹理中
        // 内部字符串可以省略，但是直接声明字符串可以得到更高的性能
        GrabPass {"_RefractionTex"}

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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 注意这里改成float4，xy用于保存主纹理的uv值，zw用于保存法线纹理的uv值
                float4 uv : TEXCOORD0;
                // 屏幕像素的采样坐标
                float4 srcPos : TEXCOORD1;
                // 切线空间转世界空间的矩阵（分3个变量存储)
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _BumpMap;
            float4 _BumpMap_ST;

            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex;
            // 纹理变量后加"_TexelSize"，可以得到该纹理的纹素大小
            // 例如：一个大小256*512的纹理，纹素大小为：(1/256, 1/512)
            // 可用于偏移屏幕图像的采样坐标
            float4 _RefractionTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                // 内置函数，得到对应抓取的屏幕像素的采样坐标，UnityCG.cginc文件中可以找到声明
                o.srcPos = ComputeGrabScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BumpMap);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 片元着色器中，把法线方向从切线空间（由法线纹理采样得到）变换到世界空间下，
                // 以便对Cubemap进行采样，因此需要计算该顶点对应的从切线空间到世界空间的变换矩阵，
                // 把矩阵的每一行分别存储在TtoW0、TtoW1、TtoW2中
                // （数学方法：得到切线空间的3个坐标轴的世界空间下的表示，把他们一次按“列”组成一个变换矩阵即可）
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                // 从法线纹理得到原始的切线空间的法线方向
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                // 基于扭曲程度，得到偏移量
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                // 基于偏移量，对屏幕图像采样位置进行偏移
                i.srcPos.xy = offset + i.srcPos.xy;
                // 得到折射的颜色
                fixed3 refractColor = tex2D(_RefractionTex, i.srcPos.xy / i.srcPos.w).rgb;

                // 将法线方向转到世界空间下
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                // 计算出表面反射方向
                fixed3 reflectDir = reflect(-worldViewDir, bump);
                // 得到主纹理的颜色
                fixed4 texColor = tex2D(_MainTex, i.uv.xy);
                // 得到反射的颜色（叠上了主纹理的颜色）
                fixed3 reflectColor = texCUBE(_Cubemap, reflectDir).rgb * texColor.rgb;

                // 最终颜色
                fixed3 finalColor = reflectColor * (1 - _RefractAmount) + refractColor * _RefractAmount;

                return fixed4(finalColor, 1);
            }
            ENDCG
        }
    }
}
