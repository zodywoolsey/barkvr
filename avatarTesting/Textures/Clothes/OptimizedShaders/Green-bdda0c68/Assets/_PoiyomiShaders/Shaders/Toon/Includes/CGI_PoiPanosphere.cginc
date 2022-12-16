#ifndef PANOSPHERE
    #define PANOSPHERE
    
    sampler2D _PanosphereTexture; float4 _PanosphereTexture_ST;
    POI_TEXTURE_NOSAMPLER(_PanoMask);
    float _PanoEmission;
    float _PanoBlend;
    float4 _PanosphereColor;
    float3 _PanospherePan;
    float _PanoToggle;
    float _PanoCubeMapToggle;
    float _PanoInfiniteStereoToggle;
    samplerCUBE _PanoCubeMap; half4 _PanoCubeMap_HDR;
    
    float3 panoColor;
    float panoMask;
    
    float2 projectIt(float3 coords)
    {
        float3 normalizedCoords = normalize(coords);
        float latitude = acos(normalizedCoords.y);
        float longitude = atan2(normalizedCoords.z, normalizedCoords.x);
        float2 sphereCoords = float2(longitude + _Time.y * float4(0,0,0,0).x, latitude + _Time.y * float4(0,0,0,0).y) * float2(1.0 / UNITY_PI, 1.0 / UNITY_PI);
        sphereCoords = float2(1.0, 1.0) - sphereCoords;
        return(sphereCoords + float4(0, 1 - unity_StereoEyeIndex, 1, 1.0).xy) * float4(0, 1 - unity_StereoEyeIndex, 1, 1.0).zw;
    }
    
    void applyPanosphereColor(inout float4 albedo, inout float3 panosphereEmission)
    {
        panoMask = POI2D_SAMPLER_PAN(_PanoMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        
        #ifdef POI_BLACKLIGHT
            if (_BlackLightMaskPanosphere != 4)
            {
                panoMask *= blackLightMask[_BlackLightMaskPanosphere];
            }
        #endif
        
        
        if(float(0))
        {
            float3 cubeUV = mul(poiRotationMatrixFromAngles(float4(0,0,0,0).xyz * _Time.y), float4(-poiCam.viewDir, 1));
            half4 cubemap = texCUBE(_PanoCubeMap, cubeUV);
            panoColor = DecodeHDR(cubemap, _PanoCubeMap_HDR);
        }
        else
        {
            float2 uv = projectIt(normalize(lerp(getCameraPosition().xyz, poiCam.worldPos.xyz, float(0)) - poiMesh.worldPos.xyz) * - 1);
            
            float2 ddxuv = ddx(uv);
            float2 ddyuv = ddy(uv);
            if(any(fwidth(uv) > .5))
            {
                ddxuv = ddyuv = 0.001;
            }
            panoColor = tex2D(_PanosphereTexture, TRANSFORM_TEX(uv, _PanosphereTexture), ddxuv, ddyuv).rgb * float4(1,1,1,1).rgb;
        }
        panosphereEmission = panoColor * float(0) * panoMask * float(0);
        albedo.rgb = lerp(albedo.rgb, panoColor, float(0) * panoMask);
    }
    
#endif

