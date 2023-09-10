using UnityEngine;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class ftGlobalStorage : ScriptableObject
{

#if UNITY_EDITOR

    [System.Serializable]
    public struct AdjustedMesh
    {
        //[SerializeField]
        //public string assetPath;

        [SerializeField]
        public List<string> meshName;

        [SerializeField]
        public List<int> padding;

        [SerializeField]
        public List<int> unwrapper;
    };

    [System.Serializable]
    public struct TagData
    {
        [SerializeField]
        public int tag;

        [SerializeField]
        public int renderMode;

        [SerializeField]
        public int renderDirMode;

        [SerializeField]
        public int bitmask;

        [SerializeField]
        public bool computeSSS;

        [SerializeField]
        public int sssSamples;

        [SerializeField]
        public float sssDensity;

        [SerializeField]
        public Color sssColor;

        [SerializeField]
        public bool transparentSelfShadow;
    };

    [System.Serializable]
    public enum Unwrapper
    {
        Default,
        xatlas
    };

    [System.Serializable]
    public enum AtlasPacker
    {
        Default,
        xatlas
    }

    [System.Serializable]
    public enum DenoiserType
    {
        Optix5 = 5, // "Legacy denoiser"
        Optix6 = 6, // Default denoiser
        Optix7 = 7, // New denoiser
        OpenImageDenoise = 100
    };

    // UV adjustment

    [SerializeField]
    public List<string> modifiedAssetPathList = new List<string>();

    [SerializeField]
    public List<int> modifiedAssetPaddingHash = new List<int>();

    // Legacy
    [SerializeField]
    public List<Mesh> modifiedMeshList = new List<Mesh>();
    [SerializeField]
    public List<int> modifiedMeshPaddingList = new List<int>();

    [SerializeField]
    public List<AdjustedMesh> modifiedAssets = new List<AdjustedMesh>();

    // UV overlap marks

    [SerializeField]
    public List<string> assetList = new List<string>();

    [SerializeField]
    public List<int> uvOverlapAssetList = new List<int>(); // -1 = no UV1, 0 = no overlap, 1 = overlap

    [SerializeField]
    public bool xatlasWarningShown = false;

    [SerializeField]
    public bool foundCompatibleSetup = false;

    [SerializeField]
    public string gpuName = "";

    [SerializeField]
    public bool runsNonRTX = true;

    [SerializeField]
    public bool runsOptix5 = true;

    [SerializeField]
    public bool runsOptix6 = true;

    [SerializeField]
    public bool runsOptix7 = true;

    [SerializeField]
    public bool runsOIDN = true;

    [SerializeField]
    public bool alwaysEnableRTX = false;

    [SerializeField]
    public bool checkerPreviewOn = false;

    [SerializeField]
    public bool rtSceneViewPreviewOn = false;

    // Defaults
    [SerializeField]
    public int renderSettingsBounces = 5;
    [SerializeField]
    public int renderSettingsGISamples = 16;
    [SerializeField]
    public float renderSettingsGIBackFaceWeight = 0;
    [SerializeField]
    public int renderSettingsTileSize = 512;
    [SerializeField]
    public float renderSettingsPriority = 2;
    [SerializeField]
    public float renderSettingsTexelsPerUnit = 20;
    [SerializeField]
    public bool renderSettingsForceRefresh = true;
    [SerializeField]
    public bool renderSettingsForceRebuildGeometry = true;
    [SerializeField]
    public bool renderSettingsPerformRendering = true;
    [SerializeField]
    public int renderSettingsUserRenderMode = 0;
    [SerializeField]
    public bool renderSettingsDistanceShadowmask = false;
    [SerializeField]
    public int renderSettingsSettingsMode = 0;
    [SerializeField]
    public bool renderSettingsFixSeams = true;
    [SerializeField]
    public bool renderSettingsDenoise = true;
    [SerializeField]
    public bool renderSettingsDenoise2x = false;
    [SerializeField]
    public bool renderSettingsEncode = true;
    [SerializeField]
    public int renderSettingsEncodeMode = 0;
    [SerializeField]
    public bool renderSettingsOverwriteWarning = false;
    [SerializeField]
    public bool renderSettingsAutoAtlas = true;
    [SerializeField]
    public bool renderSettingsUnwrapUVs = true;
    [SerializeField]
    public bool renderSettingsForceDisableUnwrapUVs = false;
    [SerializeField]
    public int renderSettingsMaxAutoResolution = 4096;
    [SerializeField]
    public int renderSettingsMinAutoResolution = 16;
    [SerializeField]
    public bool renderSettingsUnloadScenes = true;
    [SerializeField]
    public bool renderSettingsAdjustSamples = true;
    [SerializeField]
    public int renderSettingsGILODMode = 2;
    [SerializeField]
    public bool renderSettingsGILODModeEnabled = false;
    [SerializeField]
    public bool renderSettingsCheckOverlaps = false;
    [SerializeField]
    public bool renderSettingsSkipOutOfBoundsUVs = true;
    [SerializeField]
    public float renderSettingsHackEmissiveBoost = 1;
    [SerializeField]
    public float renderSettingsHackIndirectBoost = 1;
    [SerializeField]
    public string renderSettingsTempPath = "";
    [SerializeField]
    public string renderSettingsOutPath = "";
    [SerializeField]
    public bool renderSettingsUseScenePath = false;
    [SerializeField]
    public float renderSettingsHackAOIntensity = 0;
    [SerializeField]
    public int renderSettingsHackAOSamples = 16;
    [SerializeField]
    public float renderSettingsHackAORadius = 1;
    [SerializeField]
    public bool renderSettingsShowAOSettings = false;
    [SerializeField]
    public bool renderSettingsShowTasks = true;
    [SerializeField]
    public bool renderSettingsShowTasks2 = false;
    [SerializeField]
    public bool renderSettingsShowPaths = true;
    [SerializeField]
    public bool renderSettingsShowNet = true;
    [SerializeField]
    public bool renderSettingsOcclusionProbes = false;
    [SerializeField]
    public bool renderSettingsTexelsPerMap = false;
    [SerializeField]
    public float renderSettingsTexelsColor = 1;
    [SerializeField]
    public float renderSettingsTexelsMask = 1;
    [SerializeField]
    public float renderSettingsTexelsDir = 1;
    [SerializeField]
    public bool renderSettingsShowDirWarning = true;
    [SerializeField]
    public int renderSettingsRenderDirMode = 0;
    [SerializeField]
    public bool renderSettingsShowCheckerSettings = false;
    [SerializeField]
    public bool renderSettingsSamplesWarning = true;
    [SerializeField]
    public bool renderSettingsSuppressPopups = false;
    [SerializeField]
    public bool renderSettingsPrefabWarning = true;
    [SerializeField]
    public bool renderSettingsSplitByScene = false;
    [SerializeField]
    public bool renderSettingsSplitByTag = false;
    [SerializeField]
    public bool renderSettingsUVPaddingMax = false;
    [SerializeField]
    public bool renderSettingsPostPacking = true;
    [SerializeField]
    public bool renderSettingsHoleFilling = false;
    [SerializeField]
    public bool renderSettingsBeepOnFinish = false;
    [SerializeField]
    public bool renderSettingsExportTerrainAsHeightmap = true;
    [SerializeField]
    public bool renderSettingsRTXMode = false;
    [SerializeField]
    public int renderSettingsLightProbeMode = 1;
    [SerializeField]
    public bool renderSettingsClientMode = false;
    [SerializeField]
    public string renderSettingsServerAddress = "127.0.0.1";
    [SerializeField]
    public int renderSettingsUnwrapper = 0;
    [SerializeField]
    public int renderSettingsDenoiserType = (int)DenoiserType.OpenImageDenoise;
    [SerializeField]
    public bool renderSettingsExportTerrainTrees = false;
    [SerializeField]
    public bool renderSettingsShowPerf = true;
    [SerializeField]
    public int renderSettingsSampleDiv = 1;
    //[SerializeField]
    //public bool renderSettingsLegacyDenoiser = false;
    [SerializeField]
    public AtlasPacker renderSettingsAtlasPacker = AtlasPacker.Default;
    [SerializeField]
    public bool renderSettingsBatchPoints = true;
    [SerializeField]
    public bool renderSettingsCompressVolumes = false;
    [SerializeField]
    public bool renderSettingsRTPVExport = true;
    [SerializeField]
    public bool renderSettingsRTPVSceneView = false;
    [SerializeField]
    public bool renderSettingsRTPVHDR = false;
    [SerializeField]
    public int renderSettingsRTPVWidth = 640;
    [SerializeField]
    public int renderSettingsRTPVHeight = 360;

    // Tag overrides
    [SerializeField]
    public List<TagData> tagOverrides = new List<TagData>();

    // Temp

    public Dictionary<string, int> modifiedMeshMap;
    //public string modifiedMeshPaddingMapAssetName;
    public List<int> modifiedMeshPaddingArray;
    public List<int> modifiedMeshUnwrapperArray;

    // For parallel import
    public List<string> texSettingsKey;
    public List<Vector2> texSettingsVal;

    public void InitModifiedMeshMap(string assetPath) {

        modifiedMeshMap = new Dictionary<string, int>();

        var index = modifiedAssetPathList.IndexOf(assetPath);
        if (index < 0) return;
        var m = modifiedAssets[index];
        for(int j=0; j<m.meshName.Count; j++)
        {
            modifiedMeshMap[m.meshName[j]] = j;//m.padding[j];
        }

        modifiedMeshPaddingArray = m.padding;
        modifiedMeshUnwrapperArray = m.unwrapper;

        //modifiedMeshPaddingMapAssetName = assetPath;
    }

    public void ConvertFromLegacy()
    {
        for(int a=0; a<modifiedAssetPathList.Count; a++)
        {
            while(modifiedAssets.Count <= a)
            {
                var str = new AdjustedMesh();
                str.meshName = new List<string>();
                str.padding = new List<int>();
                modifiedAssets.Add(str);
            }
            var assetPath = modifiedAssetPathList[a];
            for(int i=0; i<modifiedMeshList.Count; i++) {
                var m = modifiedMeshList[i];
                if (m == null) continue;
                var mpath = AssetDatabase.GetAssetPath(m);
                if (mpath != assetPath) continue;

                modifiedAssets[a].meshName.Add(m.name);
                modifiedAssets[a].padding.Add(modifiedMeshPaddingList[i]);
            }
        }
        modifiedMeshList = new List<Mesh>();
        modifiedMeshPaddingList = new List<int>();
    }

    public int CalculatePaddingHash(int id)
    {
        string s = "";
        var list = modifiedAssets[id].padding;
        for(int i=0; i<list.Count; i++) s += list[i]+"_";
        return s.GetHashCode();
    }

    public TagData DefaultTagData()
    {
        var d = new TagData();
        d.renderMode = 1000; // auto
        d.renderDirMode = 1000; // auto
        d.computeSSS = false;
        d.sssSamples = 16;
        d.sssDensity = 10;
        d.sssColor = Color.white;
        d.transparentSelfShadow = false;
        d.bitmask = 1;
        return d;
    }

#if UNITY_2017_1_OR_NEWER
    public void SyncModifiedAsset(int index)
    {
        var importer = AssetImporter.GetAtPath(modifiedAssetPathList[index]) as ModelImporter;
        if (importer == null)
        {
            Debug.LogError("Can't get importer for " + modifiedAssetPathList[index]);
            return;
        }
        var data = modifiedAssets[index];
        var str = JsonUtility.ToJson(data);
        var props = importer.extraUserProperties;

        // check if Bakery properties already present
        int propID = -1;
        for(int i=0; i<props.Length; i++)
        {
            if (props[i].Substring(0,7) == "#BAKERY")
            {
                propID = i;
                break;
            }
        }

        if (propID < 0)
        {
            // keep existing properties
            var newProps = new string[props.Length + 1];
            for(int i=0; i<props.Length; i++) newProps[i] = props[i];
            props = newProps;
            propID = props.Length - 1;
        }

        props[propID] = "#BAKERY" + str;

        importer.extraUserProperties = props;
    }
#endif

    public void ClearAssetModifications(int index)
    {
        var importer = AssetImporter.GetAtPath(modifiedAssetPathList[index]) as ModelImporter;
        if (importer == null)
        {
            Debug.LogError("Can't get importer for " + modifiedAssetPathList[index]);
            return;
        }

        modifiedAssetPathList.RemoveAt(index);
        modifiedAssets.RemoveAt(index);
        modifiedAssetPaddingHash.RemoveAt(index);
        EditorUtility.SetDirty(this);

#if UNITY_2017_1_OR_NEWER
        var props = importer.extraUserProperties;
        if (props == null)
        {
            Debug.LogError("extraUserProperties is null");
            return;
        }
        var newProps = new List<string>();
        for(int i=0; i<props.Length; i++)
        {
            var prop = props[i];
            if (prop.Substring(0,7) != "#BAKERY")
            {
                newProps.Add(prop);
            }
        }
        importer.extraUserProperties = newProps.ToArray();
#endif

        importer.SaveAndReimport();
    }

#endif

}

