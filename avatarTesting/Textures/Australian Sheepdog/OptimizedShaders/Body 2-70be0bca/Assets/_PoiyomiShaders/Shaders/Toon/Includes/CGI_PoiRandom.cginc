#ifndef POI_RANDOM
    #define POI_RANDOM
    
    float _EnableRandom;
    float m_start_Angle;
    float _AngleType;
    float3 _AngleForwardDirection;
    float _CameraAngleMin;
    float  _CameraAngleMax;
    float _ModelAngleMin;
    float  _ModelAngleMax;
    float _AngleMinAlpha;
    float _AngleCompareTo;
    
    float ApplyAngleBasedRendering(float3 modelPos, float3 worldPos)
    {
        half cameraAngleMin = float(45) / 180;
        half cameraAngleMax = float(90) / 180;
        half modelAngleMin = float(45) / 180;
        half modelAngleMax = float(90) / 180;
        float3 pos = float(0) == 0 ? modelPos : worldPos;
        half3 cameraToModelDirection = normalize(pos - getCameraPosition());
        half3 modelForwardDirection = normalize(mul(unity_ObjectToWorld, normalize(float4(0,0,1,0))));
        half cameraLookAtModel = remapClamped(.5 * dot(cameraToModelDirection, getCameraForward()) + .5, cameraAngleMax, cameraAngleMin, 0, 1);
        half modelLookAtCamera = remapClamped(.5 * dot(-cameraToModelDirection, modelForwardDirection) + .5, modelAngleMax, modelAngleMin, 0, 1);
        if (float(0) == 0)
        {
            return max(cameraLookAtModel, float(0));
        }
        else if(float(0) == 1)
        {
            return max(modelLookAtCamera, float(0));
        }
        else if(float(0) == 2)
        {
            return max(cameraLookAtModel * modelLookAtCamera, float(0));
        }
        return 1;
    }
    
#endif
