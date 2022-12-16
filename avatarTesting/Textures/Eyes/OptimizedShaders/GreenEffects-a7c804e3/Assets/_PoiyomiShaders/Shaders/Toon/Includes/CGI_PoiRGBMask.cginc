#ifndef POI_RGBMASK
    #define POI_RGBMASK
    
    UNITY_DECLARE_TEX2D_NOSAMPLER(_RGBMask); float4 _RGBMask_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_RedTexure); float4 _RedTexure_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_GreenTexture); float4 _GreenTexture_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_BlueTexture); float4 _BlueTexture_ST;
    
    #ifdef GEOM_TYPE_MESH
        POI_NORMAL_NOSAMPLER(_RgbNormalR);
        POI_NORMAL_NOSAMPLER(_RgbNormalG);
        POI_NORMAL_NOSAMPLER(_RgbNormalB);
        float _RgbNormalsEnabled;
    #endif
    
    float4 _RedColor;
    float4 _GreenColor;
    float4 _BlueColor;
    
    float4 _RGBMaskPanning;
    float4 _RGBRedPanning;
    float4 _RGBGreenPanning;
    float4 _RGBBluePanning;
    
    float _RGBBlendMultiplicative;
    
    float _RGBMaskUV;
    float _RGBRed_UV;
    float _RGBGreen_UV;
    float _RGBBlue_UV;
    float _RGBUseVertexColors;
    float _RGBNormalBlend;
    
    static float3 rgbMask;
    
    void calculateRGBNormals(inout half3 mainTangentSpaceNormal)
    {
        #ifdef GEOM_TYPE_MESH
            #ifndef RGB_MASK_TEXTURE
                #define RGB_MASK_TEXTURE
                
                if (float(0))
                {
                    rgbMask = poiMesh.vertexColor.rgb;
                }
                else
                {
                    rgbMask = POI2D_SAMPLER_PAN(_RGBMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)).rgb;
                }
            #endif
            
            
            if(float(0))
            {
                
                if(float(0) == 0)
                {
                    
                    if(float(0) > 0)
                    {
                        half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalR, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)), float(0));
                        mainTangentSpaceNormal = lerp(mainTangentSpaceNormal, normalToBlendWith, rgbMask.r);
                    }
                    
                    if(float(0) > 0)
                    {
                        half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalG, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)), float(0));
                        mainTangentSpaceNormal = lerp(mainTangentSpaceNormal, normalToBlendWith, rgbMask.g);
                    }
                    
                    if(float(0) > 0)
                    {
                        half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalB, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)), float(0));
                        mainTangentSpaceNormal = lerp(mainTangentSpaceNormal, normalToBlendWith, rgbMask.b);
                    }
                    return;
                }
                else
                {
                    half3 newNormal = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalR, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)), float(0) * rgbMask.r);
                    half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalG, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)), float(0));
                    newNormal = lerp(newNormal, normalToBlendWith, rgbMask.g);
                    normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalB, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)), float(0));
                    newNormal = lerp(newNormal, normalToBlendWith, rgbMask.b);
                    mainTangentSpaceNormal = BlendNormals(newNormal, mainTangentSpaceNormal);
                    return;
                }
            }
        #endif
    }
    
    float3 calculateRGBMask(float3 baseColor)
    {
        //If RGB normals are in use this data will already exist
        #ifndef RGB_MASK_TEXTURE
            #define RGB_MASK_TEXTURE
            
            if (float(0))
            {
                rgbMask = poiMesh.vertexColor.rgb;
            }
            else
            {
                rgbMask = POI2D_SAMPLER_PAN(_RGBMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)).rgb;
            }
        #endif
        
        float4 red = POI2D_SAMPLER_PAN(_RedTexure, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        float4 green = POI2D_SAMPLER_PAN(_GreenTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        float4 blue = POI2D_SAMPLER_PAN(_BlueTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        
        
        if(float(0))
        {
            float3 RGBColor = 1;
            RGBColor = lerp(RGBColor, red.rgb * float4(1,1,1,1).rgb, rgbMask.r * red.a * float4(1,1,1,1).a);
            RGBColor = lerp(RGBColor, green.rgb * float4(1,1,1,1).rgb, rgbMask.g * green.a * float4(1,1,1,1).a);
            RGBColor = lerp(RGBColor, blue.rgb * float4(1,1,1,1).rgb, rgbMask.b * blue.a * float4(1,1,1,1).a);
            baseColor *= RGBColor;
        }
        else
        {
            baseColor = lerp(baseColor, red.rgb * float4(1,1,1,1).rgb, rgbMask.r * red.a * float4(1,1,1,1).a);
            baseColor = lerp(baseColor, green.rgb * float4(1,1,1,1).rgb, rgbMask.g * green.a * float4(1,1,1,1).a);
            baseColor = lerp(baseColor, blue.rgb * float4(1,1,1,1).rgb, rgbMask.b * blue.a * float4(1,1,1,1).a);
        }
        
        return baseColor;
    }
    
#endif
