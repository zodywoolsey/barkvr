using UnityEditor;
using UnityEngine;

public class ftAdditionalConfig
{
    // Affects texture import settings for lightmaps
    public const bool mipmapLightmaps = false;

    // Shader eval coeff * gaussian convolution coeff
    // ... replaced with more typical convolution coeffs
    // Used for legacy light probes
    public const float irradianceConvolutionL0 =       0.2820947917f;
    public const float irradianceConvolutionL1 =       0.32573500793527993f;//0.4886025119f * 0.7346029443286334f;
    public const float irradianceConvolutionL2_4_5_7 = 0.2731371076480198f;//0.29121293321402086f * 1.0925484306f;
    public const float irradianceConvolutionL2_6 =     0.07884789131313001f;//0.29121293321402086f * 0.3153915652f;
    public const float irradianceConvolutionL2_8 =     0.1365685538240099f;//0.29121293321402086f * 0.5462742153f;

    // Coefficients used in "Remove ringing" mode
    public const float rr_irradianceConvolutionL0 =       irradianceConvolutionL0;
    public const float rr_irradianceConvolutionL1 =       irradianceConvolutionL1;
    public const float rr_irradianceConvolutionL2_4_5_7 = irradianceConvolutionL2_4_5_7 * 0.6F;
    public const float rr_irradianceConvolutionL2_6 =     irradianceConvolutionL2_6 * 0.6f;
    public const float rr_irradianceConvolutionL2_8 =     irradianceConvolutionL2_8 * 0.6f;

    // Used for L1 light probes and volumes
    public const float convL0 = 1;
    public const float convL1 = 0.9f; // approx convolution

    // Calculate multiple point lights in one pass. No reason to disable it, unless there is a bug.
    public static bool batchPointLights = true;

#if UNITY_2017_3_OR_NEWER
    public const int sectorFarSphereResolution = 256;
#else
    // older version can't handle 32 bit meshes
    public const int sectorFarSphereResolution = 64;
#endif

/*
    Following settings are moved to Project Settings
    (on >= 2018.3; you can also edit BakeryProjectSettings.asset directly)

    // Use PNG instead of TGA for shadowmasks, directions and L1 maps
    public const bool preferPNG = false;

    // Padding values for atlas packers
    public const int texelPaddingForDefaultAtlasPacker = 3;
    public const int texelPaddingForXatlasAtlasPacker = 1;

    // Scales resolution for alpha Meta Pass maps
    public const int alphaMetaPassResolutionMultiplier = 2;

    // Render mode for all volumes in the scene. Defaults to Auto, which uses global scene render mode.
    public const BakeryLightmapGroup.RenderMode volumeRenderMode = BakeryLightmapGroup.RenderMode.Auto;

    // Should previously rendered Bakery lightmaps be deleted before the new bake?
    // Turned off by default because I'm scared of deleting anything
    public const bool deletePreviousLightmapsBeforeBake = false;

    // Print information about the bake process to console?
    public enum LogLevel
    {
        Nothing = 0,
        Info = 1,   // print to Debug.Log
        Warning = 2 // print to Debug.LogWarning
    }
    public const LogLevel logLevel = LogLevel.Info | LogLevel.Warning;

    // Make it work more similar to original Unity behaviour
    public const bool alternativeScaleInLightmap = false;

    // Should we adjust sample positions to prevent incorrect shadowing on very low-poly meshes with smooth normals?
    public const bool generateSmoothPos = true;
*/
}
