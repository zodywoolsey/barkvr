float _OutlineRimLightBlend;
float _OutlineLit;
float _OutlineTintMix;
float2 _MainTexPan;
float _MainTextureUV;

float4 frag(v2f i, uint facing: SV_IsFrontFace): COLOR
{
    float4 finalColor = 1;
    
    if (float(0))
    {
        UNITY_SETUP_INSTANCE_ID(i);
        
        float3 finalEmission = 0;
        float4 albedo = 1;
        
        poiMesh.uv[0] = i.uv0.xy;
        poiMesh.uv[1] = i.uv0.zw;
        poiMesh.uv[2] = i.uv1.xy;
        poiMesh.uv[3] = i.uv1.zw;
        
        calculateAttenuation(i);
        InitializeMeshData(i, facing);
        initializeCamera(i);
        calculateTangentData();
        
        float4 mainTexture = UNITY_SAMPLE_TEX2D(_MainTex, TRANSFORM_TEX(poiMesh.uv[float(0)], _MainTex) + _Time.x * float4(0,0,0,0));
        half3 detailMask = 1;
        calculateNormals(detailMask);
        
        #ifdef POI_DATA
            calculateLightingData(i);
        #endif
        #ifdef POI_LIGHTING
            calculateBasePassLightMaps();
        #endif
        
        float3 uselessData0;
        float3 uselessData1;
        initTextureData(albedo, mainTexture, uselessData0, uselessData1, detailMask);
        
        
        fixed4 col = mainTexture;
        float alphaMultiplier = smoothstep(float4(0,0,0,0).x, float4(0,0,0,0).y, distance(getCameraPosition(), i.worldPos));
        float OutlineMask = tex2D(_OutlineMask, TRANSFORM_TEX(poiMesh.uv[float(0)], _OutlineMask) + _Time.x * float4(0,0,0,0)).r;
        clip(OutlineMask * float(0) - 0.001);
        
        col = col * 0.00000000001 + tex2D(_OutlineTexture, TRANSFORM_TEX(poiMesh.uv[float(0)], _OutlineTexture) + _Time.x * float4(0,0,0,0) );
        col.a *= albedo.a;
        col.a *= alphaMultiplier;
        
        #ifdef POI_RANDOM
            col.a *= i.angleAlpha;
        #endif
        
        poiCam.screenUV = calcScreenUVs(i.grabPos);
        col.a *= float4(1,1,1,1).a;
        
        
        if(float(3) == 1)
        {
            applyDithering(col);
        }
        
        clip(col.a - float(0));
        
        #ifdef POI_MIRROR
            applyMirrorRenderFrag();
        #endif
        
        
        if(float(0) == 1)
        {
            #ifdef POI_MIRROR
                applyMirrorTexture(mainTexture);
            #endif
            col.rgb = mainTexture.rgb;
        }
        else if(float(0) == 2)
        {
            col.rgb = lerp(col.rgb, poiLight.color, float(0));
        }
        col.rgb *= float4(1,1,1,1).rgb;
        
        if(float(0) == 1)
        {
            col.rgb = lerp(col.rgb, mainTexture.rgb, float(0));
        }
        
        finalColor = col;
        
        #ifdef POI_LIGHTING
            
            if(float(1))
            {
                finalColor.rgb *= calculateFinalLighting(finalColor.rgb, finalColor);
            }
        #endif
        finalColor.rgb += (col.rgb * float(0));
    }
    else
    {
        clip(-1);
    }
    return finalColor;
}
