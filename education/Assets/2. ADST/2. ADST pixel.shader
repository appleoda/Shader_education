Shader "Custom/1. Unlit - ADS pixel" {   
     Properties {
         _Color ("Main Color", Color) = (1,1,1,1) 
         _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		 _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
     }
     
       SubShader {
      Tags { "Queue" = "Transparent" } 
         // draw after all opaque geometry has been drawn
      Pass {
         ZWrite Off // don't write to depth buffer 
            // in order not to occlude other objects

         Blend SrcAlpha OneMinusSrcAlpha // use alpha blending

         CGPROGRAM 
 
         #pragma vertex vert 
         #pragma fragment frag
 
 float4 _Color;
 float _Cutoff;
 float _Shininess;

         float4 vert(float4 vertexPos : POSITION) : SV_POSITION 
         {
            return mul(UNITY_MATRIX_MVP, vertexPos);
         }
 
         float4 frag(void) : COLOR 
         {
            return float4(_Color.x*_Shininess, _Color.y*_Shininess, _Color.z*_Shininess, _Cutoff); 
               // the fourth component (alpha) is important: 
               // this is semitransparent green
         }
 
         ENDCG  
      }
   }
}
      
