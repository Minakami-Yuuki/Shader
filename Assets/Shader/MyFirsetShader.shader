Shader "TA/MyFirstShader"
{
    Properties
    {
        // Common:

        // Color
        [Header(Color)]
        _Color("Color", Color) = (1, 1, 1, 1)
        [HDR]_HDRColor("HDRColor", Color) = (0, 1, 0, 1)

        // Value
        [Header(Value)]
        _Int("Int", int) = 1
        _Float("Float", Float) = 0.5

        // Bar
        [Header(Bar)]
        _Range("Range", Range(0, 1)) = 0.5
        [PowerSlider(3)]_PowerSlider("PowerSlider", Range(0, 1)) = 0.5
        [IntRange]_IntRange("IntRange", Range(0, 5)) = 1

        // Switch
        [Header(Switch)]
        [Toggle]_Toggle("Toggle", Range(0, 1)) = 1
        
        // Enum
        [Header(Enum)]
        [Enum(UnityEngine.Rendering.CullMode)]_Enum("Enum", Float) = 1
        
        // 4 Float (RGBA)
        [Header(Vector)]
        _Vector("Vector4d", Vector) = (0, 0, 0, 0)

        // 2DTexture (2var -- tilling + offset)
        // default = "grey"
        [Header(Texture2d)]
        _MainTex2d("MainTex2d", 2D) = "white" {}
        [NoScaleOffset]_SubTex2d("SubTex2d", 2D) = "white" {}
        [Normal]_NormalTex2d("NormalTex2d", 2D) = "white" {}
        
        // 3DTexture (value === "grey")
        [Header(Texture3d)]
        _MainTex3d("MainTex3D", 3d) = "" {}

        // Cube (6 faces) 
        [Header(Cube)]
        _Cube("Cube", Cube) = "" {}

        // Auto_Hide
        [HideInInspector]
        _CubeHide("CubeHide", Cube) = "" {}
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// shader:
			fixed4 _Color;

			// --- application seg: ---
			// application pragma
            struct appdata
            {
	            float4 vertex: POSITION;
            	float2 Texcoord: TEXCOORD;
            };

			// vertex To fragment
            struct v2f
            {
	            float4 pos: SV_POSITION;
            	float2 uv: TEXCOORD;
            };

			// chessboardFunc
			fixed4 checker(float2 uv)
			{
				// uv: [0, 1] --> [0, 10]
				float2 repeatUV = uv * 10;
				// Rounding down [0, 5]
				float2 c = floor(repeatUV) / 2;
				// return decimal (0 or 1)
				float checker = frac(c.x + c.y) * 2;
				// checkboard_Color
				return checker;
			}
			
			// --- Geometry seg: obj ---
			// vertex prag: Obj To clipPos
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.Texcoord;
				return o;
			}

			// --- Rasterization: output ---
			// fragment prag: rasertization
			fixed4 frag (v2f i) : SV_Target
			{
				// Dip dye (RGBA)
				return fixed4(i.uv, 0.5f, 1);

				// (0, 0, 0, 0) or (1, 1, 1, 1)
				// float col = checker(i.uv);
				// return col;
			}
			
			ENDCG
        }
    }

    Fallback "Diffuse"
    CustomEditor "EditorName"
}
