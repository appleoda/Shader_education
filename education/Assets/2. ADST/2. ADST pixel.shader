Shader "Custom/2.  ADST pixel" {   
     Properties {
         _Color ("Main Color", Color) = (1,1,1,1) 
         _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		 _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
		 _SpecColor("Spec COlor", Color) = (1,1,1,1) 
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
 float4 _SpecColor;
 float4 _Color;
 float _Cutoff;
 float _Shininess;

  uniform float4 _LightColor0; 

   struct vertexOutput {
            float4 pos : SV_POSITION;
            float4 posWorld : TEXCOORD0;
            float3 normalDir : TEXCOORD1;
         };

         float4 vert(float4 vertexPos : POSITION) : SV_POSITION 
         {
            return mul(UNITY_MATRIX_MVP, vertexPos);
         }
 
         float4 frag(vertexOutput input) : COLOR 
         {
            float3 normalDirection = normalize(input.normalDir);
 
            float3 viewDirection = normalize(
               _WorldSpaceCameraPos - input.posWorld.xyz);
            float3 lightDirection;
            float attenuation;
 
            if (0.0 == _WorldSpaceLightPos0.w) // directional light?
            {
               attenuation = 1.0; // no attenuation
               lightDirection = normalize(_WorldSpaceLightPos0.xyz);
            } 
            else // point or spot light
            {
               float3 vertexToLightSource = 
                  _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
               float distance = length(vertexToLightSource);
               attenuation = 1.0 / distance; // linear attenuation 
               lightDirection = normalize(vertexToLightSource);
            }
 
            float3 ambientLighting = 
               UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
 
            float3 diffuseReflection = 
               attenuation * _LightColor0.rgb * _Color.rgb
               * max(0.0, dot(normalDirection, lightDirection));
 
            float3 specularReflection;
            if (dot(normalDirection, lightDirection) < 0.0) 
               // light source on the wrong side?
            {
               specularReflection = float3(0.0, 0.0, 0.0); 
                  // no specular reflection
            }
            else // light source on the right side
            {
               specularReflection = attenuation * _LightColor0.rgb 
                  * _SpecColor.rgb * pow(max(0.0, dot(
                  reflect(-lightDirection, normalDirection), 
                  viewDirection)), _Shininess);
            }

            return float4(ambientLighting + diffuseReflection 
               + specularReflection, 1.0);
         }
 
         ENDCG  
      }
   }
}
      
