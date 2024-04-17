Shader "Unlit/DefaultShader"
{
    Properties
    {
        
    }
    SubShader
    {
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

            fixed4 frag(v2f i) : SV_Target
            {
                // make [1, -1] to [1, 0]
                // _Time.x/y/z/w (x=1/20 y=1 z=2 w=3)
                // i.uv.xyx (RGB channel)
                // float3 colR = 0.5 + 0.5 * cos(_Time.y + i.uv.x + 0);
                // float3 colG = 0.5 + 0.5 * cos(_Time.y + i.uv.y + 4);
                // float3 colB = 0.5 + 0.5 * cos(_Time.y + i.uv.x + 2);

                float3 col = 0.5 + 0.5 * cos(_Time.y + i.uv.xyx + float3(0, 4, 2));
                float4 finalCol = float4(col, 1);
                return finalCol;
            }
            
            ENDCG
        }
    }
}
