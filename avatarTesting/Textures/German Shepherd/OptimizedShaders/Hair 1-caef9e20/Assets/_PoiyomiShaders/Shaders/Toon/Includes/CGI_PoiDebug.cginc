#ifndef POI_DEBUG
    #define POI_DEBUG
    
    float _DebugEnabled;
    float _DebugMeshData;
    float _DebugLightingData;
    float _DebugCameraData;
    
    void displayDebugInfo(inout float4 finalColor)
    {
        
        if (float(0) != 0)
        {
            //Mesh Data
            if (float(0) == 1)
            {
                finalColor.rgb = poiMesh.normals[0];
                return;
            }
            else if(float(0) == 2)
            {
                finalColor.rgb = poiMesh.normals[1];
                return;
            }
            else if(float(0) == 3)
            {
                finalColor.rgb = poiMesh.tangent;
                return;
            }
            else if(float(0) == 4)
            {
                finalColor.rgb = poiMesh.binormal;
                return;
            }
            else if(float(0) == 5)
            {
                finalColor.rgb = poiMesh.localPos;
                return;
            }
            
            #ifdef POI_LIGHTING
                if(float(0) == 1)
                {
                    finalColor.rgb = poiLight.attenuation;
                    return;
                }
                else if(float(0) == 2)
                {
                    finalColor.rgb = poiLight.directLighting;
                    return;
                }
                else if(float(0) == 3)
                {
                    finalColor.rgb = poiLight.indirectLighting;
                    return;
                }
                else if(float(0) == 4)
                {
                    finalColor.rgb = poiLight.lightMap;
                    return;
                }
                else if(float(0) == 5)
                {
                    finalColor.rgb = poiLight.rampedLightMap;
                    return;
                }
                else if(float(0) == 6)
                {
                    finalColor.rgb = poiLight.finalLighting;
                    return;
                }
                else if(float(0) == 7)
                {
                    finalColor.rgb = poiLight.nDotL;
                    return;
                }
            #endif
            
            if(float(0) == 1)
            {
                finalColor.rgb = poiCam.viewDir;
                return;
            }
            else if(float(0) == 2)
            {
                finalColor.rgb = poiCam.tangentViewDir;
                return;
            }
            else if(float(0) == 3)
            {
                finalColor.rgb = poiCam.forwardDir;
                return;
            }
            else if(float(0) == 4)
            {
                finalColor.rgb = poiCam.worldPos;
                return;
            }
            else if(float(0) == 5)
            {
                finalColor.rgb = poiCam.viewDotNormal;
                return;
            }
        }
    }
    
#endif
