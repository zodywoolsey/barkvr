#ifndef POI_ENVIRONMENTAL_RIM
    #define POI_ENVIRONMENTAL_RIM
    
    //enviro rim
    float _EnableEnvironmentalRim;
    POI_TEXTURE_NOSAMPLER(_RimEnviroMask); 
    float _RimEnviroBlur;
    float _RimEnviroMinBrightness;
    float _RimEnviroWidth;
    float _RimEnviroSharpness;
    float _RimEnviroIntensity;
    
    float3 calculateEnvironmentalRimLighting(in float4 albedo)
    {
        float enviroRimAlpha = saturate(1 - smoothstep(min(float(0), float(0.45)), float(0.45), poiCam.viewDotNormal));
        float(0.7) *= 1.7 - 0.7 * float(0.7);
        
        float3 enviroRimColor = 0;
        float interpolator = unity_SpecCube0_BoxMin.w;
        
        if (interpolator < 0.99999)
        {
            //Probe 1
            float4 reflectionData0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, poiMesh.normals[1], float(0.7) * UNITY_SPECCUBE_LOD_STEPS);
            float3 reflectionColor0 = DecodeHDR(reflectionData0, unity_SpecCube0_HDR);
            
            //Probe 2
            float4 reflectionData1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, poiMesh.normals[1], float(0.7) * UNITY_SPECCUBE_LOD_STEPS);
            float3 reflectionColor1 = DecodeHDR(reflectionData1, unity_SpecCube1_HDR);
            
            enviroRimColor = lerp(reflectionColor1, reflectionColor0, interpolator);
        }
        else
        {
            float4 reflectionData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, poiMesh.normals[1], float(0.7) * UNITY_SPECCUBE_LOD_STEPS);
            enviroRimColor = DecodeHDR(reflectionData, unity_SpecCube0_HDR);
        }
        
        half enviroMask = poiMax(POI2D_SAMPLER_PAN(_RimEnviroMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)).rgb);
        return lerp(0, max(0, (enviroRimColor - float(0)) * albedo.rgb), enviroRimAlpha).rgb * enviroMask * float(1);
    }
    
#endif
