#define USE_TERRAINS

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class ftLightmapsStorage : MonoBehaviour{

#if UNITY_EDITOR
        [System.Serializable]
        public class LightData
        {
            public Matrix4x4 tform;
            public Color color;
            public float intensity, range, radius;
            public int samples, samples2;
            public int bitmask;
            public bool bakeToIndirect;
            public bool selfShadow = false;
            public bool realisticFalloff = false;
            public int projMode;
            public Object cookie;
            public float angle = 30.0f;
            public int UID;
        }

        public class ImplicitLightmapData
        {
            public Dictionary<GameObject, Object> implicitGroupMap = null;
        }

        // Saved render settings
        public int renderSettingsBounces = 5;
        public int renderSettingsGISamples = 16;
        public float renderSettingsGIBackFaceWeight = 0;
        public int renderSettingsTileSize = 512;
        public float renderSettingsPriority = 2;
        public float renderSettingsTexelsPerUnit = 20;
        public bool renderSettingsForceRefresh = true;
        public bool renderSettingsForceRebuildGeometry = true;
        public bool renderSettingsPerformRendering = true;
        public int renderSettingsUserRenderMode = 0;
        public bool renderSettingsDistanceShadowmask = false;
        public int renderSettingsSettingsMode = 0;
        public bool renderSettingsFixSeams = true;
        public bool renderSettingsDenoise = true;
        public bool renderSettingsDenoise2x = false;
        public bool renderSettingsEncode = true;
        public int renderSettingsEncodeMode = 0;
        public bool renderSettingsOverwriteWarning = false;
        public bool renderSettingsAutoAtlas = true;
        public bool renderSettingsUnwrapUVs = true;
        public bool renderSettingsForceDisableUnwrapUVs = false;
        public int renderSettingsMaxAutoResolution = 4096;
        public int renderSettingsMinAutoResolution = 16;
        public bool renderSettingsUnloadScenes = true;
        public bool renderSettingsAdjustSamples = true;
        public int renderSettingsGILODMode = 2;
        public bool renderSettingsGILODModeEnabled = false;
        public bool renderSettingsCheckOverlaps = false;
        public bool renderSettingsSkipOutOfBoundsUVs = true;
        public float renderSettingsHackEmissiveBoost = 1;
        public float renderSettingsHackIndirectBoost = 1;
        public string renderSettingsTempPath = "";
        public string renderSettingsOutPath = "";
        public bool renderSettingsUseScenePath = false;
        public float renderSettingsHackAOIntensity = 0;
        public int renderSettingsHackAOSamples = 16;
        public float renderSettingsHackAORadius = 1;
        public bool renderSettingsShowAOSettings = false;
        public bool renderSettingsShowTasks = true;
        public bool renderSettingsShowTasks2 = false;
        public bool renderSettingsShowPaths = true;
        public bool renderSettingsShowNet = true;
        public bool renderSettingsOcclusionProbes = false;
        public bool renderSettingsTexelsPerMap = false;
        public float renderSettingsTexelsColor = 1;
        public float renderSettingsTexelsMask = 1;
        public float renderSettingsTexelsDir = 1;
        public bool renderSettingsShowDirWarning = true;
        public int renderSettingsRenderDirMode = 0;
        public bool renderSettingsShowCheckerSettings = false;
        public bool renderSettingsSamplesWarning = true;
        public bool renderSettingsSuppressPopups = false;
        public bool renderSettingsPrefabWarning = true;
        public bool renderSettingsSplitByScene = false;
        public bool renderSettingsSplitByTag = false;
        public bool renderSettingsUVPaddingMax = false;
        public bool renderSettingsPostPacking = true;
        public bool renderSettingsHoleFilling = false;
        public bool renderSettingsBeepOnFinish = false;
        public bool renderSettingsExportTerrainAsHeightmap = true;
        public bool renderSettingsRTXMode = false;
        public int renderSettingsLightProbeMode = 1;
        public bool renderSettingsClientMode = false;
        public string renderSettingsServerAddress = "127.0.0.1";
        public int renderSettingsUnwrapper = 0;
        public int renderSettingsDenoiserType = (int)ftGlobalStorage.DenoiserType.OpenImageDenoise;
        public bool renderSettingsExportTerrainTrees = false;
        public bool renderSettingsShowPerf = true;
        public int renderSettingsSampleDiv = 1;
        public ftGlobalStorage.AtlasPacker renderSettingsAtlasPacker = ftGlobalStorage.AtlasPacker.xatlas;
        public bool renderSettingsBatchPoints = true;
        public bool renderSettingsCompressVolumes = false;
        public UnityEngine.Object renderSettingsSector = null;
        public bool renderSettingsRTPVExport = true;
        public bool renderSettingsRTPVSceneView = false;
        public bool renderSettingsRTPVHDR = false;
        public int renderSettingsRTPVWidth = 640;
        public int renderSettingsRTPVHeight = 360;
        public int lastBakeTime = 0;

        public bool enlightenWarningShown = false;
        public bool enlightenWarningShown2 = false;

        // Light settings from the last bake
        public List<GameObject> uniqueLights = new List<GameObject>();
        public List<LightData> lights = new List<LightData>();
        public Dictionary<GameObject, LightData> lightsDict;

        // List of implicit groups
        //public List<BakeryLightmapGroup> implicitGroups = new List<BakeryLightmapGroup>();
        public List<Object> implicitGroups = new List<Object>();
        public List<GameObject> implicitGroupedObjects;

        //public List<BakeryLightmapGroupPlain> previouslyBakedGroups = new List<BakeryLightmapGroupPlain>();

        // List of baked lightmap world-space bounds
        public List<Bounds> bounds = new List<Bounds>();

        // Per-lightmap flags
        public List<bool> hasEmissive = new List<bool>();

        //public float[][] uvSrc;
        //public float[][] uvDest;
        //public int[][] lmrIndices;
        public int[] uvBuffOffsets;
        public int[] uvBuffLengths;
        public float[] uvSrcBuff;
        public float[] uvDestBuff;
        public int[] lmrIndicesOffsets;
        public int[] lmrIndicesLengths;
        public int[] lmrIndicesBuff;

        public int[] lmGroupLODResFlags; // bits which lods are needed for which LMGroups
        public int[] lmGroupMinLOD; // minimum possible resolution for given LMGroup given UV island count
        public int[] lmGroupLODMatrix;

        // Reuired for network bakes
        public List<string> serverGetFileList = new List<string>();
        public List<bool> lightmapHasColor = new List<bool>();
        public List<int> lightmapHasMask = new List<int>();
        public List<bool> lightmapHasDir = new List<bool>();
        public List<bool> lightmapHasRNM = new List<bool>();

        // Partial copy of GlobalStorage to recover UV padding if needed
        public List<string> modifiedAssetPathList = new List<string>();
        public List<ftGlobalStorage.AdjustedMesh> modifiedAssets = new List<ftGlobalStorage.AdjustedMesh>();

        //public Texture2D debugTex;
        //public RenderTexture debugRT;

        public void Init(bool forceRefresh)
        {
            lightsDict = new Dictionary<GameObject, LightData>();
            if (uniqueLights == null) uniqueLights = new List<GameObject>();
            if (lights == null || uniqueLights == null)
            {
                forceRefresh = true;
            }
            else if (lights.Count != uniqueLights.Count)
            {
                forceRefresh = true;
            }

            if (forceRefresh)
            {
                lights = new List<LightData>();
                uniqueLights = new List<GameObject>();
            }
            else
            {
                for(int i=0; i<lights.Count; i++)
                {
                    if (uniqueLights[i] != null)
                    {
                        lightsDict[uniqueLights[i]] = lights[i];
                    }
                }
            }
        }

        public void StoreLight(GameObject u, LightData light)
        {
            if (uniqueLights == null) uniqueLights = new List<GameObject>();
            if (lights == null) lights = new List<LightData>();
            light.UID = uniqueLights.Count + 1;
            uniqueLights.Add(u);
            lights.Add(light);
            lightsDict[u] = light;
        }

        public static void CopySettings(ftLightmapsStorage src, ftLightmapsStorage dest)
        {
            dest.renderSettingsBounces = src.renderSettingsBounces;
            dest.renderSettingsGISamples = src.renderSettingsGISamples;
            dest.renderSettingsGIBackFaceWeight = src.renderSettingsGIBackFaceWeight;
            dest.renderSettingsTileSize = src.renderSettingsTileSize;
            dest.renderSettingsPriority = src.renderSettingsPriority;
            dest.renderSettingsTexelsPerUnit = src.renderSettingsTexelsPerUnit;
            dest.renderSettingsForceRefresh = src.renderSettingsForceRefresh;
            dest.renderSettingsForceRebuildGeometry = src.renderSettingsForceRebuildGeometry;
            dest.renderSettingsPerformRendering = src.renderSettingsPerformRendering;
            dest.renderSettingsUserRenderMode = src.renderSettingsUserRenderMode;
            dest.renderSettingsDistanceShadowmask = src.renderSettingsDistanceShadowmask;
            dest.renderSettingsSettingsMode = src.renderSettingsSettingsMode;
            dest.renderSettingsFixSeams = src.renderSettingsFixSeams;
            dest.renderSettingsDenoise = src.renderSettingsDenoise;
            dest.renderSettingsDenoise2x = src.renderSettingsDenoise2x;
            dest.renderSettingsEncode = src.renderSettingsEncode;
            dest.renderSettingsEncodeMode = src.renderSettingsEncodeMode;
            dest.renderSettingsOverwriteWarning = src.renderSettingsOverwriteWarning;
            dest.renderSettingsAutoAtlas = src.renderSettingsAutoAtlas;
            dest.renderSettingsUnwrapUVs = src.renderSettingsUnwrapUVs;
            dest.renderSettingsForceDisableUnwrapUVs = src.renderSettingsForceDisableUnwrapUVs;
            dest.renderSettingsMaxAutoResolution = src.renderSettingsMaxAutoResolution;
            dest.renderSettingsMinAutoResolution = src.renderSettingsMinAutoResolution;
            dest.renderSettingsUnloadScenes = src.renderSettingsUnloadScenes;
            dest.renderSettingsAdjustSamples = src.renderSettingsAdjustSamples;
            dest.renderSettingsGILODMode = src.renderSettingsGILODMode;
            dest.renderSettingsGILODModeEnabled = src.renderSettingsGILODModeEnabled;
            dest.renderSettingsCheckOverlaps = src.renderSettingsCheckOverlaps;
            dest.renderSettingsSkipOutOfBoundsUVs = src.renderSettingsSkipOutOfBoundsUVs;
            dest.renderSettingsHackEmissiveBoost = src.renderSettingsHackEmissiveBoost;
            dest.renderSettingsHackIndirectBoost = src.renderSettingsHackIndirectBoost;
            dest.renderSettingsTempPath = src.renderSettingsTempPath;
            dest.renderSettingsOutPath = src.renderSettingsOutPath;
            dest.renderSettingsUseScenePath = src.renderSettingsUseScenePath;
            dest.renderSettingsHackAOIntensity = src.renderSettingsHackAOIntensity;
            dest.renderSettingsHackAOSamples = src.renderSettingsHackAOSamples;
            dest.renderSettingsHackAORadius = src.renderSettingsHackAORadius;
            dest.renderSettingsShowAOSettings = src.renderSettingsShowAOSettings;
            dest.renderSettingsShowTasks = src.renderSettingsShowTasks;
            dest.renderSettingsShowTasks2 = src.renderSettingsShowTasks2;
            dest.renderSettingsShowPaths = src.renderSettingsShowPaths;
            dest.renderSettingsShowNet = src.renderSettingsShowNet;
            dest.renderSettingsOcclusionProbes = src.renderSettingsOcclusionProbes;
            dest.renderSettingsTexelsPerMap = src.renderSettingsTexelsPerMap;
            dest.renderSettingsTexelsColor = src.renderSettingsTexelsColor;
            dest.renderSettingsTexelsMask = src.renderSettingsTexelsMask;
            dest.renderSettingsTexelsDir = src.renderSettingsTexelsDir;
            dest.renderSettingsShowDirWarning = src.renderSettingsShowDirWarning;
            dest.renderSettingsRenderDirMode = src.renderSettingsRenderDirMode;
            dest.renderSettingsShowCheckerSettings = src.renderSettingsShowCheckerSettings;
            dest.renderSettingsSamplesWarning = src.renderSettingsSamplesWarning;
            dest.renderSettingsSuppressPopups = src.renderSettingsSuppressPopups;
            dest.renderSettingsPrefabWarning = src.renderSettingsPrefabWarning;
            dest.renderSettingsSplitByScene = src.renderSettingsSplitByScene;
            dest.renderSettingsSplitByTag = src.renderSettingsSplitByTag;
            dest.renderSettingsUVPaddingMax = src.renderSettingsUVPaddingMax;
            dest.renderSettingsPostPacking = src.renderSettingsPostPacking;
            dest.renderSettingsHoleFilling = src.renderSettingsHoleFilling;
            dest.renderSettingsBeepOnFinish = src.renderSettingsBeepOnFinish;
            dest.renderSettingsExportTerrainAsHeightmap = src.renderSettingsExportTerrainAsHeightmap;
            dest.renderSettingsRTXMode = src.renderSettingsRTXMode;
            dest.renderSettingsLightProbeMode = src.renderSettingsLightProbeMode;
            dest.renderSettingsClientMode = src.renderSettingsClientMode;
            dest.renderSettingsServerAddress = src.renderSettingsServerAddress;
            dest.renderSettingsUnwrapper = src.renderSettingsUnwrapper;
            dest.renderSettingsDenoiserType = src.renderSettingsDenoiserType;
            dest.renderSettingsExportTerrainTrees = src.renderSettingsExportTerrainTrees;
            dest.renderSettingsSampleDiv = src.renderSettingsSampleDiv;
            dest.renderSettingsAutoAtlas = src.renderSettingsAutoAtlas;
            dest.renderSettingsBatchPoints = src.renderSettingsBatchPoints;
            dest.renderSettingsCompressVolumes = src.renderSettingsCompressVolumes;
            dest.renderSettingsRTPVExport = src.renderSettingsRTPVExport;
            dest.renderSettingsRTPVSceneView = src.renderSettingsRTPVSceneView;
            dest.renderSettingsRTPVHDR = src.renderSettingsRTPVHDR;
            dest.renderSettingsRTPVWidth = src.renderSettingsRTPVWidth;
            dest.renderSettingsRTPVHeight = src.renderSettingsRTPVHeight;
            dest.renderSettingsAtlasPacker = src.renderSettingsAtlasPacker;
            dest.renderSettingsShowPerf = src.renderSettingsShowPerf;
        }

        public static void CopySettings(ftLightmapsStorage src, ftGlobalStorage dest)
        {
            dest.renderSettingsBounces = src.renderSettingsBounces;
            dest.renderSettingsGISamples = src.renderSettingsGISamples;
            dest.renderSettingsGIBackFaceWeight = src.renderSettingsGIBackFaceWeight;
            dest.renderSettingsTileSize = src.renderSettingsTileSize;
            dest.renderSettingsPriority = src.renderSettingsPriority;
            dest.renderSettingsTexelsPerUnit = src.renderSettingsTexelsPerUnit;
            dest.renderSettingsForceRefresh = src.renderSettingsForceRefresh;
            dest.renderSettingsForceRebuildGeometry = src.renderSettingsForceRebuildGeometry;
            dest.renderSettingsPerformRendering = src.renderSettingsPerformRendering;
            dest.renderSettingsUserRenderMode = src.renderSettingsUserRenderMode;
            dest.renderSettingsDistanceShadowmask = src.renderSettingsDistanceShadowmask;
            dest.renderSettingsSettingsMode = src.renderSettingsSettingsMode;
            dest.renderSettingsFixSeams = src.renderSettingsFixSeams;
            dest.renderSettingsDenoise = src.renderSettingsDenoise;
            dest.renderSettingsDenoise2x = src.renderSettingsDenoise2x;
            dest.renderSettingsEncode = src.renderSettingsEncode;
            dest.renderSettingsEncodeMode = src.renderSettingsEncodeMode;
            dest.renderSettingsOverwriteWarning = src.renderSettingsOverwriteWarning;
            dest.renderSettingsAutoAtlas = src.renderSettingsAutoAtlas;
            dest.renderSettingsUnwrapUVs = src.renderSettingsUnwrapUVs;
            dest.renderSettingsForceDisableUnwrapUVs = src.renderSettingsForceDisableUnwrapUVs;
            dest.renderSettingsMaxAutoResolution = src.renderSettingsMaxAutoResolution;
            dest.renderSettingsMinAutoResolution = src.renderSettingsMinAutoResolution;
            dest.renderSettingsUnloadScenes = src.renderSettingsUnloadScenes;
            dest.renderSettingsAdjustSamples = src.renderSettingsAdjustSamples;
            dest.renderSettingsGILODMode = src.renderSettingsGILODMode;
            dest.renderSettingsGILODModeEnabled = src.renderSettingsGILODModeEnabled;
            dest.renderSettingsCheckOverlaps = src.renderSettingsCheckOverlaps;
            dest.renderSettingsSkipOutOfBoundsUVs = src.renderSettingsSkipOutOfBoundsUVs;
            dest.renderSettingsHackEmissiveBoost = src.renderSettingsHackEmissiveBoost;
            dest.renderSettingsHackIndirectBoost = src.renderSettingsHackIndirectBoost;
            dest.renderSettingsTempPath = src.renderSettingsTempPath;
            dest.renderSettingsOutPath = src.renderSettingsOutPath;
            dest.renderSettingsUseScenePath = src.renderSettingsUseScenePath;
            dest.renderSettingsHackAOIntensity = src.renderSettingsHackAOIntensity;
            dest.renderSettingsHackAOSamples = src.renderSettingsHackAOSamples;
            dest.renderSettingsHackAORadius = src.renderSettingsHackAORadius;
            dest.renderSettingsShowAOSettings = src.renderSettingsShowAOSettings;
            dest.renderSettingsShowTasks = src.renderSettingsShowTasks;
            dest.renderSettingsShowTasks2 = src.renderSettingsShowTasks2;
            dest.renderSettingsShowPaths = src.renderSettingsShowPaths;
            dest.renderSettingsShowNet = src.renderSettingsShowNet;
            dest.renderSettingsOcclusionProbes = src.renderSettingsOcclusionProbes;
            dest.renderSettingsTexelsPerMap = src.renderSettingsTexelsPerMap;
            dest.renderSettingsTexelsColor = src.renderSettingsTexelsColor;
            dest.renderSettingsTexelsMask = src.renderSettingsTexelsMask;
            dest.renderSettingsTexelsDir = src.renderSettingsTexelsDir;
            dest.renderSettingsShowDirWarning = src.renderSettingsShowDirWarning;
            dest.renderSettingsRenderDirMode = src.renderSettingsRenderDirMode;
            dest.renderSettingsShowCheckerSettings = src.renderSettingsShowCheckerSettings;
            dest.renderSettingsSamplesWarning = src.renderSettingsSamplesWarning;
            dest.renderSettingsSuppressPopups = src.renderSettingsSuppressPopups;
            dest.renderSettingsPrefabWarning = src.renderSettingsPrefabWarning;
            dest.renderSettingsSplitByScene = src.renderSettingsSplitByScene;
            dest.renderSettingsSplitByTag = src.renderSettingsSplitByTag;
            dest.renderSettingsUVPaddingMax = src.renderSettingsUVPaddingMax;
            dest.renderSettingsPostPacking = src.renderSettingsPostPacking;
            dest.renderSettingsHoleFilling = src.renderSettingsHoleFilling;
            dest.renderSettingsBeepOnFinish = src.renderSettingsBeepOnFinish;
            dest.renderSettingsExportTerrainAsHeightmap = src.renderSettingsExportTerrainAsHeightmap;
            dest.renderSettingsRTXMode = src.renderSettingsRTXMode;
            dest.renderSettingsLightProbeMode = src.renderSettingsLightProbeMode;
            dest.renderSettingsClientMode = src.renderSettingsClientMode;
            dest.renderSettingsServerAddress = src.renderSettingsServerAddress;
            dest.renderSettingsUnwrapper = src.renderSettingsUnwrapper;
            dest.renderSettingsDenoiserType = src.renderSettingsDenoiserType;
            dest.renderSettingsExportTerrainTrees = src.renderSettingsExportTerrainTrees;
            dest.renderSettingsShowPerf = src.renderSettingsShowPerf;
            dest.renderSettingsSampleDiv = src.renderSettingsSampleDiv;
            dest.renderSettingsBatchPoints = src.renderSettingsBatchPoints;
            dest.renderSettingsCompressVolumes = src.renderSettingsCompressVolumes;
            dest.renderSettingsRTPVExport = src.renderSettingsRTPVExport;
            dest.renderSettingsRTPVSceneView = src.renderSettingsRTPVSceneView;
            dest.renderSettingsRTPVHDR = src.renderSettingsRTPVHDR;
            dest.renderSettingsRTPVWidth = src.renderSettingsRTPVWidth;
            dest.renderSettingsRTPVHeight = src.renderSettingsRTPVHeight;
            dest.renderSettingsAtlasPacker = src.renderSettingsAtlasPacker;
            dest.renderSettingsAutoAtlas = src.renderSettingsAutoAtlas;
        }

        public static void CopySettings(ftGlobalStorage src, ftLightmapsStorage dest)
        {
            dest.renderSettingsBounces = src.renderSettingsBounces;
            dest.renderSettingsGISamples = src.renderSettingsGISamples;
            dest.renderSettingsGIBackFaceWeight = src.renderSettingsGIBackFaceWeight;
            dest.renderSettingsTileSize = src.renderSettingsTileSize;
            dest.renderSettingsPriority = src.renderSettingsPriority;
            dest.renderSettingsTexelsPerUnit = src.renderSettingsTexelsPerUnit;
            dest.renderSettingsForceRefresh = src.renderSettingsForceRefresh;
            dest.renderSettingsForceRebuildGeometry = src.renderSettingsForceRebuildGeometry;
            dest.renderSettingsPerformRendering = src.renderSettingsPerformRendering;
            dest.renderSettingsUserRenderMode = src.renderSettingsUserRenderMode;
            dest.renderSettingsDistanceShadowmask = src.renderSettingsDistanceShadowmask;
            dest.renderSettingsSettingsMode = src.renderSettingsSettingsMode;
            dest.renderSettingsFixSeams = src.renderSettingsFixSeams;
            dest.renderSettingsDenoise = src.renderSettingsDenoise;
            dest.renderSettingsDenoise2x = src.renderSettingsDenoise2x;
            dest.renderSettingsEncode = src.renderSettingsEncode;
            dest.renderSettingsEncodeMode = src.renderSettingsEncodeMode;
            dest.renderSettingsOverwriteWarning = src.renderSettingsOverwriteWarning;
            dest.renderSettingsAutoAtlas = src.renderSettingsAutoAtlas;
            dest.renderSettingsUnwrapUVs = src.renderSettingsUnwrapUVs;
            dest.renderSettingsForceDisableUnwrapUVs = src.renderSettingsForceDisableUnwrapUVs;
            dest.renderSettingsMaxAutoResolution = src.renderSettingsMaxAutoResolution;
            dest.renderSettingsMinAutoResolution = src.renderSettingsMinAutoResolution;
            dest.renderSettingsUnloadScenes = src.renderSettingsUnloadScenes;
            dest.renderSettingsAdjustSamples = src.renderSettingsAdjustSamples;
            dest.renderSettingsGILODMode = src.renderSettingsGILODMode;
            dest.renderSettingsGILODModeEnabled = src.renderSettingsGILODModeEnabled;
            dest.renderSettingsCheckOverlaps = src.renderSettingsCheckOverlaps;
            dest.renderSettingsSkipOutOfBoundsUVs = src.renderSettingsSkipOutOfBoundsUVs;
            dest.renderSettingsHackEmissiveBoost = src.renderSettingsHackEmissiveBoost;
            dest.renderSettingsHackIndirectBoost = src.renderSettingsHackIndirectBoost;
            dest.renderSettingsTempPath = src.renderSettingsTempPath;
            dest.renderSettingsOutPath = src.renderSettingsOutPath;
            dest.renderSettingsUseScenePath = src.renderSettingsUseScenePath;
            dest.renderSettingsHackAOIntensity = src.renderSettingsHackAOIntensity;
            dest.renderSettingsHackAOSamples = src.renderSettingsHackAOSamples;
            dest.renderSettingsHackAORadius = src.renderSettingsHackAORadius;
            dest.renderSettingsShowAOSettings = src.renderSettingsShowAOSettings;
            dest.renderSettingsShowTasks = src.renderSettingsShowTasks;
            dest.renderSettingsShowTasks2 = src.renderSettingsShowTasks2;
            dest.renderSettingsShowPaths = src.renderSettingsShowPaths;
            dest.renderSettingsShowNet = src.renderSettingsShowNet;
            dest.renderSettingsOcclusionProbes = src.renderSettingsOcclusionProbes;
            dest.renderSettingsTexelsPerMap = src.renderSettingsTexelsPerMap;
            dest.renderSettingsTexelsColor = src.renderSettingsTexelsColor;
            dest.renderSettingsTexelsMask = src.renderSettingsTexelsMask;
            dest.renderSettingsTexelsDir = src.renderSettingsTexelsDir;
            dest.renderSettingsShowDirWarning = src.renderSettingsShowDirWarning;
            dest.renderSettingsRenderDirMode = src.renderSettingsRenderDirMode;
            dest.renderSettingsShowCheckerSettings = src.renderSettingsShowCheckerSettings;
            dest.renderSettingsSamplesWarning = src.renderSettingsSamplesWarning;
            dest.renderSettingsSuppressPopups = src.renderSettingsSuppressPopups;
            dest.renderSettingsPrefabWarning = src.renderSettingsPrefabWarning;
            dest.renderSettingsSplitByScene = src.renderSettingsSplitByScene;
            dest.renderSettingsSplitByTag = src.renderSettingsSplitByTag;
            dest.renderSettingsUVPaddingMax = src.renderSettingsUVPaddingMax;
            dest.renderSettingsPostPacking = src.renderSettingsPostPacking;
            dest.renderSettingsHoleFilling = src.renderSettingsHoleFilling;
            dest.renderSettingsBeepOnFinish = src.renderSettingsBeepOnFinish;
            dest.renderSettingsExportTerrainAsHeightmap = src.renderSettingsExportTerrainAsHeightmap;
            dest.renderSettingsRTXMode = src.renderSettingsRTXMode;
            dest.renderSettingsLightProbeMode = src.renderSettingsLightProbeMode;
            dest.renderSettingsClientMode = src.renderSettingsClientMode;
            dest.renderSettingsServerAddress = src.renderSettingsServerAddress;
            dest.renderSettingsUnwrapper = src.renderSettingsUnwrapper;
            dest.renderSettingsDenoiserType = src.renderSettingsDenoiserType;
            dest.renderSettingsExportTerrainTrees = src.renderSettingsExportTerrainTrees;
            dest.renderSettingsShowPerf = src.renderSettingsShowPerf;
            dest.renderSettingsSampleDiv = src.renderSettingsSampleDiv;
            dest.renderSettingsBatchPoints = src.renderSettingsBatchPoints;
            dest.renderSettingsCompressVolumes = src.renderSettingsCompressVolumes;
            dest.renderSettingsRTPVExport = src.renderSettingsRTPVExport;
            dest.renderSettingsRTPVSceneView = src.renderSettingsRTPVSceneView;
            dest.renderSettingsRTPVHDR = src.renderSettingsRTPVHDR;
            dest.renderSettingsRTPVWidth = src.renderSettingsRTPVWidth;
            dest.renderSettingsRTPVHeight = src.renderSettingsRTPVHeight;
            dest.renderSettingsAtlasPacker = src.renderSettingsAtlasPacker;
            dest.renderSettingsAutoAtlas = src.renderSettingsAutoAtlas;
        }
#endif

    // List of baked lightmaps
    public List<Texture2D> maps = new List<Texture2D>();
    public List<Texture2D> masks = new List<Texture2D>();
    public List<Texture2D> dirMaps = new List<Texture2D>();
    public List<Texture2D> rnmMaps0 = new List<Texture2D>();
    public List<Texture2D> rnmMaps1 = new List<Texture2D>();
    public List<Texture2D> rnmMaps2 = new List<Texture2D>();
    public List<int> mapsMode = new List<int>();

    // new props
    public List<Renderer> bakedRenderers = new List<Renderer>();
    public List<int> bakedIDs = new List<int>();
    public List<Vector4> bakedScaleOffset = new List<Vector4>();
#if UNITY_EDITOR
    public List<int> bakedVertexOffset = new List<int>();
#endif
    public List<Mesh> bakedVertexColorMesh = new List<Mesh>();

    public List<Renderer> nonBakedRenderers = new List<Renderer>();

    public List<Light> bakedLights = new List<Light>();
    public List<int> bakedLightChannels = new List<int>();

#if USE_TERRAINS
    public List<Terrain> bakedRenderersTerrain = new List<Terrain>();
    public List<int> bakedIDsTerrain = new List<int>();
    public List<Vector4> bakedScaleOffsetTerrain = new List<Vector4>();
#endif

    public List<string> assetList = new List<string>();
    public List<int> uvOverlapAssetList = new List<int>(); // -1 = no UV1, 0 = no overlap, 1 = overlap

    public int[] idremap;

    public bool usesRealtimeGI;

    public Texture2D emptyDirectionTex;

    public bool anyVolumes = false;
    public bool compressedVolumes = false;

#if UNITY_EDITOR
    [System.Serializable]
    public class SectorData
    {
        public string name;

        public List<Texture2D> maps = new List<Texture2D>();
        public List<Texture2D> masks = new List<Texture2D>();
        public List<Texture2D> dirMaps = new List<Texture2D>();
        public List<Texture2D> rnmMaps0 = new List<Texture2D>();
        public List<Texture2D> rnmMaps1 = new List<Texture2D>();
        public List<Texture2D> rnmMaps2 = new List<Texture2D>();
        public List<int> mapsMode = new List<int>();

        public List<Renderer> bakedRenderers = new List<Renderer>();
        public List<int> bakedIDs = new List<int>();
        public List<Vector4> bakedScaleOffset = new List<Vector4>();
        public List<Mesh> bakedVertexColorMesh = new List<Mesh>();

#if USE_TERRAINS
        public List<Terrain> bakedRenderersTerrain = new List<Terrain>();
        public List<int> bakedIDsTerrain = new List<int>();
        public List<Vector4> bakedScaleOffsetTerrain = new List<Vector4>();
#endif

        public List<Renderer> nonBakedRenderers = new List<Renderer>();
    }

    public List<SectorData> sectors = new List<SectorData>();
#endif

    void Awake()
    {
        ftLightmaps.RefreshScene(gameObject.scene, this);
    }

    void Start()
    {
        // Unity can for some reason alter lightmapIndex after the scene is loaded in a multi-scene setup, so fix that
        ftLightmaps.RefreshScene2(gameObject.scene, this);//, appendOffset);
    }

    void OnDestroy()
    {
        ftLightmaps.UnloadScene(this);
    }
}
