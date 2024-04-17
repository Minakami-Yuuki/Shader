Shader "Unlit/Chapter5-SimpleShader"
{
    // 第一行，通过Shader语义，定义这个Shader的名字，名字中使用'/'可定义该Shader的路径（或分组）
    // 回到之前创建的材质，选择Shader，可以看到多了一个Unity Shaders Book目录，下面的子目录Chapter 5里面就有我们目前的Shader
    // Properties语义并不是必需的
    Properties
    {
        _Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader
    {
        // SubShader中没有进行任何渲染设置和标签设置，
        // 所以该SubShader将使用默认的设置

        Pass
        {
            // Pass中没有进行任何渲染设置和标签设置，
            // 所以该Pass将使用默认的设置

            // 由 CGPROGRAM 和 ENDCG 包围 CG 代码片段
            CGPROGRAM

            // 告诉Unity，顶点着色器的代码在 vert 函数中 （格式：#pragma vertex [name]）
            #pragma vertex vert
            // 告诉Unity，片元着色器的代码在 frag 函数中 （格式：#pragma fragment [name]）
            #pragma fragment frag
            // 辅助函数
            #include "UnityCG.cginc"

            fixed4 _Color;

            // 使用结构体作为顶点着色器的输入，可以包含更多顶点信息
            // a2v 是当前结构体的名字，可自行定义（写法：struct [StructName]）
            // 这里 a2v 表示 application to vertex ，意思是：把数据从应用阶段传递到顶点着色器中
            struct a2v
            {
                // 模型空间的顶点坐标，相当于之前顶点着色器的输入v
                float4 vertex : POSITION;
                // 模型空间中，该顶点的法线方向，使用 NORMAL 语义
                float3 normal : NORMAL;
                // 该模型的第一套纹理坐标（模型可以有多套纹理坐标），第n+1套纹理坐标，用语义 TEXCOORDn
                float4 texcoord : TEXCOORD0;
            };

            // 这里 v2f 表示 vertex to fragment ，意思是：把数据从顶点着色器的值传递到片元着色器中
            struct v2f
            {
                // SV_POSITION: 表示pos存储的顶点在裁切空间的位置信息
                float4 pos : SV_POSITION;
                // COLOR0: 用于存储颜色信息
                fixed3 color : COLOR0;
            };
            
            // 顶点着色器代码
            v2f vert(a2v v)
            {
                v2f o;
                // 将物体空间变换至裁切空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 将法线的值转变成颜色值，呈现到模型上（这里没有必然的法线和颜色的转换关系，仅作案例演示，无需纠结此段代码）
                // 因为法线方向，各分量范围是[-1, 1]，为了让其转变到颜色的范围[0, 1]，故做如下运算：
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            // 片元着色器代码
            // 通过SV_Target语义，告诉渲染器，把用户的输出颜色存储到一个渲染目标中（比如：帧缓存中）
            // 颜色的RGBA每个分量范围在[0, 1]，所以使用fixed4类型
            // (0, 0, 0)表示黑色，(1, 1, 1)表示白色
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 color = i.color;
                // 改变发现转换的颜色效果
                color *= _Color.rgb;

                // fixed用来存储颜色和单位矢量；half存储更大范围的数据；最差情况下再选择使用float
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}
