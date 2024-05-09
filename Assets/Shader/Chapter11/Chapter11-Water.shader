// 水波效果
Shader "Unlit/Chapter11-Water"
{
    Properties
    {
        // 河流纹理
        _MainTex ("Texture", 2D) = "white" {}
        // 整体颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 波动幅度
        _Magnitude ("Distortion Magnitude", Float) = 1
        // 频率
        _Frequency ("Distortion Frequency", Float) = 1
        // 波长倒数 (数值越大 波长越小)
        _InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
        // 波移动速度
        _Speed ("Speed", Float) = 0.5
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            // 批处理会合并所有相关的模型 会导致各自的模型空间丢失
            // 需要禁止使用批处理
            "DisableBatching" = "True"
        }

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            // 关闭深度写入
            ZWrite Off
            // 开启并设置混合模式
            Blend SrcAlpha OneMinusSrcAlpha
            // 关闭剔除
            Cull Off
            
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
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed3 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;

            v2f vert (a2v v)
            {
                v2f o;

                // 位移偏移值
                float4 offset;
                // 只对顶点的x方向进行位移 -- offset初始化
                offset.yzw = float3(0.0, 0.0, 0.0);
                // 利用_Frequency属性与内置事件_Time.y来控制正弦函数的频率
                // 为使模型在不同位置具有不同位移 另加上模型空间的位置分量 并乘以 _InvWaveLength 控制波长
                // 最后乘以_Magnitude来控制幅度
                offset.x = sin(_Frequency * _Time.y
                    + v.vertex.x * _InvWaveLength
                    + v.vertex.y * _InvWaveLength
                    + v.vertex.z * _InvWaveLength)
                    * _Magnitude;

                // 加上偏移量
                o.pos = UnityObjectToClipPos(v.vertex + offset);
                // 将顶点的uv展开值材质球上 确保缩放和平移正确
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                // 使用 _Time.y 和 _Speed 来控制水平方向上的纹理动画
                o.uv += float2(0.0, _Time.y * _Speed);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 纹理贴图中每一点的颜色
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;
                return c;
            }
            
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
