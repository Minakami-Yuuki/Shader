Shader "Unlit/VFace"
{
    Properties
    {
        _FrontTex("FrontTex", 2d) = "white" {}
        _BackTex("BackTex", 2d) = "white" {}
    }
    SubShader
    {
        // 表面剔除关闭
        cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // DirectX 3.0
            #pragma target 3.0

            sampler2D _FrontTex;
            sampler2D _BackTex;

            // application var
            struct appdata
            {
                // vertex in_POSTION
                float4 vertex: POSITION;
                float2 texcoord: TEXCOORD0;
            };

            // vertex var
            struct v2f
            {
                // vertex out_POSITION --- fragment in_POSITION
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
            };

            // application to vertex prag
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            // vertex prag to fragment prag (VFACE)
            fixed4 frag (v2f i, float face:VFACE) : SV_Target
            {
                // camera > 0 ==> _FrontTex
                // camera <=0 ==> _BackTex
                fixed4 col = 1;
                col = face > 0 ? tex2D(_FrontTex, i.uv) : tex2D(_BackTex, i.uv);
                return col;
            }
            
            ENDCG
        }
    }
}
