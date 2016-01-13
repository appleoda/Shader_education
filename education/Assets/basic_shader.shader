Shader "PA/Basic Shader" 
{
	Properties 
	{
		_Color ("Diffuse color", Color) = ( 1, 1, 1, 1 )
		_MainTex ("Main texture", 2D) = "white" {}
		_MainTexNormalMap ("Main Tex Normal (RGB)", 2D) = "bump" {}
		         
		_SpecualColor ("Specular Material Color", Color) = (1, 1, 1, 1) 
		_SpecShininess ("Specular Shininess", Range(2, 70)) = 10
		_SpecPower ("Specular power", Range(0, 10)) = 1
	}
	 
	 
	CGINCLUDE
		 
	//uniform sampler2D _MainTex;

	ENDCG
	
	SubShader 
	{
		//Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
		Tags { "RenderType"="Opaque" }
		LOD 400
		
		Pass
		{	
			//LOD 200
			Blend SrcAlpha OneMinusSrcAlpha
        
			CGPROGRAM

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			#pragma vertex vert alpha
			#pragma fragment frag alpha
			#include "UnityCG.cginc"
			#pragma target 3.0

			//uniform float4 _LightColor0;
			
			///////////////////////////////////////////////////////////////////

			// input shader data
			sampler2D _MainTex;
			float4 _Color;
			
			sampler2D _MainTexNormalMap;

			sampler2D _TexOne;
			sampler2D _TexTwo;
			sampler2D _TexThree;
			sampler2D _TexFour;
			
			float4 _MainTex_ST;
			float4 _SpecualColor;
			float _SpecShininess;
			float _SpecPower;

			
			///////////////////////////////////////////////////////////////////
			struct VS_INPUT
			{
			   float4 vertex   : POSITION;
			   float3 normal   : NORMAL;
			   float3 tangent   : TANGENT;
			   float2 texCoord0 : TEXCOORD0;
			   float2 texCoord1 : TEXCOORD1;
			};
			///////////////////////////////////////////////////////////////////

			struct VS_OUTPUT
			{
			   float4 pos      : POSITION;
			   float2 texCoord0 : TEXCOORD0;
               float2 texCoord1 : TEXCOORD1;
			   float3 normal   : TEXCOORD2;
			   float3 viewVec  : TEXCOORD3;
			   float3 lightVec : TEXCOORD4;
			   float atten	   : TEXCOORD5;
			   float3 tangent : TEXCOORD6;
			};
			///////////////////////////////////////////////////////////////////
			
			VS_OUTPUT vert(VS_INPUT i)
			{
			     VS_OUTPUT o = (VS_OUTPUT)0;

				// common calculation
				float4x4 modelMatrix = _Object2World;
				float atten;
				float3 lightDirection;
 
				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					atten = 1.0; // no attenuation
					lightDirection = normalize(_WorldSpaceLightPos0.rgb);
				} 
				else // point or spot light
				{
					float3 vertexToLightSource = (_WorldSpaceLightPos0 - mul(modelMatrix, i.vertex)).rgb;
					float distance = length(vertexToLightSource);
					atten = 1.0 / distance; // linear attenuation 
					lightDirection = normalize(vertexToLightSource);
				}

			   // Output transformed position:
			   o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
			   
			   // Output light vector:
			   o.lightVec = lightDirection;//normalize(-WorldSpaceLightDir(i.vertex)); 
				//o.lightVec = normalize(-WorldSpaceLightDir(i.vertex)); 

			   // Compute position in view space:
			   float3 Pview = WorldSpaceViewDir(i.vertex); 
			   			   
			   // Transform the input normal to view space:
			   o.normal = mul(_Object2World, float4(i.normal, 0));
			   
			   // Compute the view direction in view space:
			   o.viewVec = -normalize(Pview); // 
			   
			   // Propagate texture coordinate for the object:
			   //o.texCoord0 = i.texCoord0;
			   o.texCoord0 = TRANSFORM_TEX(i.texCoord0, _MainTex);
			   o.texCoord1 = i.texCoord1;

			   // output atten
			   o.atten = atten;

			   o.tangent = mul(_Object2World, float4(i.tangent, 0));

			   return o;
			}
			
			///////////////////////////////////////////////////////////////////

			struct PS_INPUT
			{
			   float2 texCoord0		: TEXCOORD0;
               float2 texCoord1		: TEXCOORD1;
			   float3 normal		: TEXCOORD2;
			   float3 viewVec		: TEXCOORD3;
			   float3 lightVec		: TEXCOORD4;
			   float atten			: TEXCOORD5;
			   float3 tangent		: TEXCOORD6;
			};
			///////////////////////////////////////////////////////////////////
			
			float4 frag(PS_INPUT i) : COLOR
			{ 		
				// 
				float4 mainTexClr = tex2D(_MainTex, i.texCoord0);
							
				//
				float3 tangent = normalize(i.tangent);
				float3 normal = normalize(i.normal);
				float3 binormal = normalize(cross(normal, tangent) * tangent);
				float3x3 worldToTangent = float3x3(tangent, binormal, normal);
				
				// calc res normal
				float3 resNormal = normalize(UnpackNormal(tex2D(_MainTexNormalMap, i.texCoord0)).xyz);
				resNormal = mul(resNormal, worldToTangent);
				
				//
				float3 V = normalize(i.viewVec);
				float3 L = normalize(i.lightVec); 
				float3 R = reflect(L, resNormal);
				float3 H = normalize(L - V); // L + V
				float NdotL = max(0, dot(resNormal, L));
				float RdotV = max(0, dot(R, V));
				float NdotH  = saturate(dot(resNormal, H));

				// ambient
				float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb * 2.3 * _Color.rgb * mainTexClr;
								 
				// diffuse
				float3 diffuseLighting = _LightColor0.rgb * 1.5 * _Color.rgb * mainTexClr * NdotL * i.atten;
				 
				// specular
				//float specPower = pow(RdotV, _SpecShininess) * _SpecPower; // Phong
				//float specPower = pow(NdotH, _SpecShininess) * _SpecPower; // Blinn-Phong specular model

				// approximate curve
				float specShininess2 = _SpecShininess * _SpecShininess;
				float specShininess3 = specShininess2 * _SpecShininess;
				float factor = 4.00012  - (0.624042  / specShininess3)
										+ (0.728329  / specShininess2)
										+ (1.22792   / _SpecShininess);
				float specPower = pow(NdotH, factor * _SpecShininess) * _SpecPower; 

				//
				float3 specularColor = _LightColor0.rgb * i.atten * _SpecualColor.rgb * specPower;
				
				// result			
				float4 resClr;
				resClr.rgb = ambientLighting + diffuseLighting + specularColor;	
				resClr.a = 1;  

				return resClr;
			}
			///////////////////////////////////////////////////////////////////
			
			ENDCG
		}
	}

	Fallback "PA/Ground Shader Lite"
} 