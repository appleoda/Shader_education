Shader "Custom/1. Unlit - ADS Surface" {    
  Properties {
    _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0) 
		 _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
  }
  SubShader {
    Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
    Blend SrcAlpha OneMinusSrcAlpha
    Cull Off
    LOD 200
 
    CGPROGRAM
    #pragma surface surf Lambert
 
    fixed4 _Color;
 float _Cutoff;
 float _Shininess;
 
    // Note: pointless texture coordinate. I couldn't get Unity (or Cg)
    //       to accept an empty Input structure or omit the inputs.
    struct Input {
      float2 uv_MainTex;
    };
 
    void surf (Input IN, inout SurfaceOutput o) {
      o.Albedo = _Color.rgb*_Shininess; 
	  o.Specular = _Shininess; 
    }
    ENDCG
  } 
  FallBack "Diffuse"
}
      
