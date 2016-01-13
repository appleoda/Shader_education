float4x4 g_mWVP 	: WorldViewProjection;
float4x4 g_mWorld	: World;
float4x4 g_mViewI	: ViewInverse;
float4 	 g_vEye		: vecEyePosWorld;

int meshDesc : MeshDescription
<
	bool Normals = true;
>;

/////////////////////////////////////////////////////////////
// Textures

texture g_texDiffuse : DiffuseMap
<
	string UIName = "Diffuse Texture";
	int Texcoord = 0;
	int MapChannel = 1;
>;

texture g_texNormal : NormalMap
<
	string UIName = "Normal Map";
	int Texcoord = 1;
	int MapChannel = 2;
>;
texture g_texLight : LightMap
<
	string UIName = "Light Map";
	int Texcoord = 2;
	int MapChannel = 1;
>;

/////////////////////////////////////////////////////////////
// data

half4 g_vLightDirArr[1]		: vecLightDirWorld;

float3 g_vLightDir : Direction
<
	string UIName = "Light";
	string Object = "DirectionalLight";
	string Space = "World";
> = float3(0.0f, -1.0f, 1.0f);

half g_hBumpStrength
<
	string UIName = "Bump Strength";
	string UIWidget = "Slider";
	float UIMin = 0.0;
	float UIMax = 1.0;
	float UIStep = 0.01;
> = 1.0;

float g_fRollOff
<
	string UIName = "Roll off contrast";
	string UIWidget = "Slider";
	float UIMin = 0.0;
	float UIMax = 1.0;
	float UIStep = 0.01;
> = 0.0;

//Fuzz Color
float4 g_vFuzzColor : Diffuse
<
	string UIName = "FuzzColor";
> = {0.3f, 0.3f, 0.75f, 1};

//ambient
float4 g_vAmbientLight : Diffuse
<
	string UIName = "Ambient Light Color";
> = {1.0f, 1.0f, 1.0f, 1.0f};

float4 g_vMaterialAmbient : Diffuse
<
	string UIName = "Material Ambient  Color";
> = {1.0f, 1.0f, 1.0f, 1.0f};

//diffuse
float4 g_vDiffuseLight : Diffuse
<
	string UIName = "Diffuse Light Color";
> = {1.0f, 1.0f, 1.0f, 1.0f};

float4 g_vMaterialDiffuse : Diffuse
<
	string UIName = "Material Diffuse Color";
> = {1.0f, 1.0f, 1.0f, 1.0f};

/////////////////////////////////////////////////////////////
// Smaplers

sampler2D g_sampDiffuse = sampler_state
{
	Texture = <g_texDiffuse>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler2D g_sampNormal = sampler_state
{
	Texture = <g_texNormal>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};
sampler2D g_sampLight = sampler_state
{
	Texture = <g_texLight>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

/////////////////////////////////////////////////////////////
// Structures
struct vsi20
{
				float4 Position		: POSITION;
				float3 Normal		: NORMAL;
				float3 Tangent		: TANGENT0;
				float3 Binormal		: BINORMAL0;
				float2 DiffuseTC	: TEXCOORD0;
				float2 LightTC		: TEXCOORD1;
				float2 NormalTC		: TEXCOORD2;	
				float3 TangentTex	: TEXCOORD3;
				float3 BinormalTex	: TEXCOORD4;
};
struct vsi11
{
				float4 Position		: POSITION;
				float3 Normal		: NORMAL;
				float3 Tangent		: TANGENT0;
				float3 Binormal		: BINORMAL0;
				float2 DiffuseTC	: TEXCOORD0;
				float2 NormalTC		: TEXCOORD1;	
				float3 LightTC		: TEXCOORD2;
				float3 TangentTex	: TEXCOORD3;
};

struct psi20
{
			float4 Position					: POSITION;
			float2 DiffuseTC				: TEXCOORD0;
			float2 LightTC					: TEXCOORD1;
			float2 NormalTC					: TEXCOORD2;
			float3 Eye						: TEXCOORD3;
			float3x3 TangentToWorldSpace	: TEXCOORD4;
};
struct psi11
{
			float4 Position					: POSITION;
			float2 DiffuseTC				: TEXCOORD0;
			float2 NormalTC					: TEXCOORD1;
			float2 LightTC					: TEXCOORD2;
			float3 L    					: COLOR0;
			float3 Eye						: COLOR1;
};


/////////////////////////////////////////////////////////////
// Shaders

/////////////////////////////////////////////////////////////
//VS 20
void VsMain20(	vsi20 i,
				out psi20 o			
							)
{
	o.Position = mul(i.Position, g_mWVP);//position of the vertex
	o.DiffuseTC = i.DiffuseTC;//diffuse texcoords
	o.NormalTC = i.NormalTC;//normal texcoords(bump)
	o.LightTC = i.LightTC;//Light texcoords
	
	//create TangentToObjSpace 
	float3x3 TangentToObjSpace;	
	#ifdef ReFlex//then by texcoords
		TangentToObjSpace[0] = i.TangentTex;
		TangentToObjSpace[1] = i.BinormalTex;
	#else//then by real
		TangentToObjSpace[0] = i.Tangent;
		TangentToObjSpace[1] = i.Binormal;
	#endif
	TangentToObjSpace[2] = i.Normal;
	
	//create TangentToWorldSpace 
	o.TangentToWorldSpace = mul(TangentToObjSpace, g_mWorld);
	
	//compute position (in world space)  	
  	float3 PosWorld = mul(i.Position, g_mWorld);
  	
  	//Compute Eye (in world space)
  	#ifdef ReFlex
		o.Eye = normalize(g_vEye - PosWorld);
	#else
		o.Eye = normalize(g_mViewI[3] - PosWorld);
	#endif
}
/////////////////////////////////////////////////////////////
//VS 11
void VsMain11(	vsi11 i,
				out psi11 o			
							)
{
	o.Position = mul(i.Position, g_mWVP);//position of the vertex
	o.DiffuseTC = i.DiffuseTC;//diffuse texcoords
	o.NormalTC = i.NormalTC;//normal texcoords(bump)
	o.LightTC = i.LightTC;//Light texcoords
	
	//create TangentToObjSpace 
	float3x3 TangentToObjSpace;	
	#ifdef ReFlex//then by texcoords
		TangentToObjSpace[0] = i.TangentTex;
		TangentToObjSpace[1] = cross(i.TangentTex, i.Normal);
	#else//then by real
		TangentToObjSpace[0] = i.Tangent;
		TangentToObjSpace[1] = cross(i.Tangent, i.Normal);
	#endif
	TangentToObjSpace[2] = i.Normal;
	
	//create TangentToWorldSpace 
	float3x3 TangentToWorldSpace = mul(TangentToObjSpace, g_mWorld);
	
	//compute position (in world space)  	
  	float3 PosWorld = mul(i.Position, g_mWorld);
  	
  	//Compute Eye (in world space)
  	#ifdef ReFlex
		o.Eye = normalize( mul(TangentToWorldSpace ,g_vEye - PosWorld));
	#else
		o.Eye = normalize(mul(TangentToWorldSpace ,g_mViewI[3] - PosWorld));
	#endif
	//compute light directon 
	float4 L;
  	#ifdef ReFlex
  		o.L = normalize( mul(TangentToWorldSpace ,-g_vLightDirArr[0]));
  	#else 
  		o.L = normalize( mul(TangentToWorldSpace ,g_vLightDir)); 
  	#endif
	
}
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
float4 PsMain20( psi20 i,	
				 uniform half4 lightAmbient,
				 uniform half4 materialAmbient,
				 uniform half4 lightDiffuse,
				 uniform half4 materialDiffuse ) : COLOR
{
	half4 diffMC = tex2D(g_sampDiffuse, i.DiffuseTC);//from diffuse map 
	half4 lightMC = tex2D(g_sampLight,i.LightTC);//from light map
	
  	half3 bumpNormal = 2 * tex2D(g_sampNormal, i.NormalTC) - 1.0f;//normal from texture
	
	//calculating normal vector
	half3 N;
	#ifdef ReFlex
		N = lerp(half3(0.0, 1.0, 0.0), bumpNormal, g_hBumpStrength);
	#else
		N = lerp(half3(0.0, 0.0, 1.0), bumpNormal, g_hBumpStrength);
	#endif
	N = normalize(mul(N, i.TangentToWorldSpace));//to world space
	
	//compute light directon 
	float3 L;
  	#ifdef ReFlex
  		L = -g_vLightDirArr[0]; 
  	#else 
  		L = g_vLightDir; 
  	#endif
  	
    half diff = saturate(dot(L,N));
        
    //Velvety...
    float3 V = normalize(i.Eye);
    half VdotN = 1 - saturate(dot(V,N) * (1 + g_fRollOff));
    float4 vecColor = float4(VdotN.xxx,1) * g_vFuzzColor;
    
    //other...	
	half4 ambColor = lightAmbient * materialAmbient;
    half4 diffColor = lightDiffuse * materialDiffuse * diff;
    half4 diffAmbColor = diffColor + ambColor;
        
  	return vecColor * diff  + diffMC  * diffAmbColor * lightMC;
}
float4 PsMain11( psi11 i,	
				 uniform half4 ambient,
				 uniform half4 diffuse,
				 uniform half4 fuzzColor,				 
				 uniform half4 rollOff ) : COLOR
{
	//calculating normal vector
  	half3 N  = 2 * tex2D(g_sampNormal, i.NormalTC) - 1.0f;//normal from texture
				
    float3 V = (i.Eye);
    float oldVdotN = dot(V,N);
    float VdotN = 1 - saturate(oldVdotN * rollOff + oldVdotN);
    float4 vecColor = float4(VdotN.xxx,1) * fuzzColor;

    //calc diff
    float diff = dot(i.L,N);    
    //compute resColor
    V = ((vecColor + diffuse)*diff + ambient) 
    			* tex2D(g_sampDiffuse, i.DiffuseTC);// * tex2D(g_sampLight, i.LightTC);
    
    return float4(V,1);
}

/////////////////////////////////////////////////////////////
// Techniques


technique MaxPreviewPs20
{
	pass P0
	{
		AlphaBlendEnable = false;
		VertexShader = compile vs_1_1 VsMain20();
		PixelShader = compile ps_2_0 PsMain20(g_vAmbientLight,
											  g_vMaterialAmbient,
											  g_vDiffuseLight,
											  g_vMaterialDiffuse);
	}
}
technique MaxPreviewPs11
{
	pass P0
	{
		AlphaBlendEnable = false;
		VertexShader = compile vs_1_1 VsMain11();
		PixelShader = compile ps_1_1 PsMain11(g_vAmbientLight * g_vMaterialAmbient,
											  g_vDiffuseLight * g_vMaterialDiffuse,
											  g_vFuzzColor,
											  g_fRollOff);
	}
}
