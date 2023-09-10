#if UNITY_EDITOR
#define USE_TERRAINS

// Disable 'obsolete' warnings
#pragma warning disable 0618

// Run Bakery exes via CreateProcess instead of mono. Mono seems to have problems with apostrophes in paths.
// Bonus point: working dir == DLL dir, so moving the folder works.
#define LAUNCH_VIA_DLL
//#define COMPRESS_VOLUME_RGBM

using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using System.Text.RegularExpressions;
using System.Reflection;

public class ftRenderLightmap : EditorWindow//ScriptableWizard
{
    public static bool ftInitialized = false;
    public static bool ftSceneDirty = true;

    public static ftRenderLightmap instance;

    public enum RenderMode
    {
        FullLighting = 0,
        Indirect = 1,
        Shadowmask = 2,
        Subtractive = 3,
        AmbientOcclusionOnly = 4
    };

    public enum RenderDirMode
    {
        None = 0,
        BakedNormalMaps = 1,
        DominantDirection = 2,
        RNM = 3,
        SH = 4,
        MonoSH = 6
    };

    public enum SettingsMode
    {
        Simple = 0,
        Advanced = 1,
        Experimental = 2
    };

    public enum LightProbeMode
    {
        Legacy = 0,
        L1 = 1
    };

    public enum GILODMode
    {
        Auto = 0,
        ForceOn = 1,
        ForceOff = 2
    };

    class Convex
    {
        public Vector3[] vertices;
        public Plane[] planes;
    };

    class LightBounds
    {
        public float cutoff;
        public int bitmask;
        public int shadowmaskGroupID;
        public Vector3 center;
        public BakeryPointLight point;

        public LightBounds(BakeryPointLight p)
        {
            cutoff = p.cutoff;
            bitmask = p.bitmask;
            shadowmaskGroupID = p.shadowmaskGroupID;
            center = p.transform.position;
            point = p;
        }

        public LightBounds(BakeryLightMesh p)
        {
            cutoff = p.cutoff;
            bitmask = p.bitmask;
            shadowmaskGroupID = 0;
            center = p.transform.position;
        }
    };

    static bool askedTangentSH = false;

    [DllImport ("simpleProgressBar", CallingConvention=CallingConvention.Cdecl)]
    public static extern int simpleProgressBarShow(string header, string msg, float percent, float step, bool onTop);

    [DllImport ("simpleProgressBar", CallingConvention=CallingConvention.Cdecl)]
    public static extern bool simpleProgressBarCancelled();

    [DllImport ("simpleProgressBar", CallingConvention=CallingConvention.Cdecl)]
    public static extern void simpleProgressBarEnd();

    [DllImport ("halffloat2vb", CallingConvention=CallingConvention.Cdecl)]
    public static extern int halffloat2vb([MarshalAs(UnmanagedType.LPWStr)]string inputFilename, System.IntPtr values, int dataType);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern System.IntPtr RunLocalProcess([MarshalAs(UnmanagedType.LPWStr)]string commandline, bool setWorkDir);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern System.IntPtr RunLocalProcessVisible([MarshalAs(UnmanagedType.LPWStr)]string commandline);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern bool IsProcessFinished(System.IntPtr proc);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int GetProcessReturnValueAndClose(System.IntPtr proc);

#if UNITY_2018_3_OR_NEWER
    [DllImport("user32.dll")]
    static extern System.IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    static extern int SetForegroundWindow(System.IntPtr hwnd);

    [DllImport("user32.dll")]
    static extern System.IntPtr GetParent(System.IntPtr hwnd);

    [DllImport("user32.dll")]
    static extern int GetWindowText(System.IntPtr hwnd, StringBuilder text, int count);

    System.IntPtr unityEditorHWND;
#endif

#if UNITY_2017_3_OR_NEWER
    const LightmapEditorSettings.Lightmapper BUILTIN_RADIOSITY = LightmapEditorSettings.Lightmapper.Enlighten;
    const LightmapEditorSettings.Lightmapper BUILTIN_PT = LightmapEditorSettings.Lightmapper.ProgressiveCPU;
#else
    #if UNITY_2017_2_OR_NEWER
        const LightmapEditorSettings.Lightmapper BUILTIN_RADIOSITY = LightmapEditorSettings.Lightmapper.Radiosity;
        const LightmapEditorSettings.Lightmapper BUILTIN_PT = LightmapEditorSettings.Lightmapper.PathTracer;
    #endif
#endif

    public static int bounces = 5;
    public int giSamples = 16;
    static public float giBackFaceWeight = 0;
    public static int tileSize = 512;
    public float priority = 2;
    public float texelsPerUnit = 20;
    public static bool forceRefresh = true;
    bool forceRebuildGeometry = true;
    bool performRendering = true;
    public RenderMode userRenderMode = RenderMode.FullLighting;
    public static bool isDistanceShadowmask;
    public static RenderDirMode renderDirMode;
    public static LightProbeMode lightProbeMode = LightProbeMode.L1;
    public static ftGlobalStorage.Unwrapper unwrapper = ftGlobalStorage.Unwrapper.Default;
    public static ftGlobalStorage.DenoiserType denoiserType = ftGlobalStorage.DenoiserType.OpenImageDenoise;
    public SettingsMode settingsMode = SettingsMode.Simple;
    public static GILODMode giLodMode = GILODMode.ForceOff;
    public static bool giLodModeEnabled = false;
    static bool revertReflProbesValue = false;
    static bool reflProbesValue = true;
    public static bool restoreFromGlobalSector = false;
    public static float hackEmissiveBoost = 1;
    public static float hackIndirectBoost = 1;
    public static float hackAOIntensity = 0;
    public static int hackAOSamples = 16;
    public static float hackAORadius = 1;
    public static bool showAOSettings = false;
    public static bool showTasks = false;
    public static bool showTasks2 = false;
    public static bool showPaths = false;
    public static bool showNet = false;
    public static bool showPerf = true;
    //public static bool showCompression = false;
    //public static bool useUnityForLightProbes = false;
    public static bool useUnityForOcclsusionProbes = false;
    public static bool showDirWarning = true;
    public static bool showCheckerSettings = false;
    public static bool showChecker = false;
    static bool usesRealtimeGI = false;
    static int lastBakeTime;
    public static bool beepOnFinish;
    public static bool useScenePath = true;
    public static bool removeDuplicateLightmaps = false;
    public static bool clientMode = false;
    public static int sampleDivisor = 1;

    public bool exeMode = true;//false;
    public bool deferredMode = true; // defer calls to ftrace and denoiser to unload unity scenes
    public bool unloadScenesInDeferredMode = false;
    public static bool adjustSamples = true;
    public static bool checkOverlaps = false;
    public static bool samplesWarning = true;
    public static bool prefabWarning = true;
    public static bool suppressPopups = false;
    public static bool compressedGBuffer = true;
    public static bool compressedOutput = true;
    static List<System.Diagnostics.ProcessStartInfo> deferredCommands;
    static Dictionary<int, List<string>> deferredCommandsFallback;
    static Dictionary<int, BakeryLightmapGroupPlain> deferredCommandsRebake;
    static Dictionary<int, int> deferredCommandsLODGen;
    static Dictionary<int, Vector3> deferredCommandsGIGen;
    static Dictionary<int, BakeryLightmapGroupPlain> deferredCommandsHalf2VB;
    static Dictionary<int, bool> deferredCommandsUVGB;
    static List<string> deferredFileSrc;
    static List<string> deferredFileDest;
    static List<string> deferredCommandDesc;

    public const string ftraceExe6 = "ftraceRTX.exe";
    public const string ftraceExe1 = "ftrace.exe";
    static string ftraceExe = ftraceExe1;
    static bool rtxMode = false;

    public static BakerySector curSector;
    static string curSectorName;

    public static int passedFilterFlag = 0;

    enum AdjustUVMode
    {
        DontChange,
        Adjust,
        ForceDisableAdjust
    }

    static string[] adjustUVOptions = new string[] {"Don't change", "Adjust UV padding", "Remove UV adjustments"};

    public static event System.EventHandler OnPreFullRender;
    public static event System.EventHandler OnPreReflectionProbeRender;       // AMW
    public static event System.EventHandler<ProbeEventArgs> OnPreRenderProbe;
    public static event System.EventHandler OnFinishedProbes;
    public static event System.EventHandler OnFinishedFullRender;
    public static event System.EventHandler OnFinishedReflectionProbes;

    public class ProbeEventArgs : System.EventArgs
    {
        public Vector3 pos { get; set; }
    }

    public static LayerMask forceProbeVisibility;

    // Every LMID -> every channel -> every mask
    static List<List<List<string>>> lightmapMasks;
    static List<List<List<string>>> lightmapMaskLMNames;
    static List<List<List<Light>>> lightmapMaskLights;
    static List<List<List<bool>>> lightmapMaskDenoise;
#if UNITY_2017_3_OR_NEWER
#else
    static List<Light> maskedLights;
    PropertyInfo inspectorModeInfo;
#endif
    static List<bool> lightmapHasColor;
    static List<int> lightmapHasMask; // number of channels used
    static List<bool> lightmapHasDir;
    static List<bool> lightmapHasRNM;
    Scene sceneSavedTestScene;
    bool sceneWasSaved = false;

    public bool fixSeams = true;
    public bool denoise = true;
    public bool denoise2x = false;
    public bool encode = true;

    public int padding = 16;

    public int dilate = 16;

    //public bool bc6h = false;
    int encodeMode = 0;

    public bool selectedOnly = false;
    bool probesOnlyL1 = false;
    public static bool fullSectorRender = false;

    public static bool verbose = true;
    public static bool showProgressBar = true;

    public int lightProbeRenderSize = 128;
    public int lightProbeReadSize = 16;
    public int lightProbeMaxCoeffs = 9;

    public static ftLightmapsStorage storage;
    public static Dictionary<Scene, ftLightmapsStorage> storages;

    static bool tryFixingSceneView = true;

    // set via experimental UI now
    //static bool legacyDenoiser = false;
    //static bool oidnDenoiser = false;
    static bool foundCompatibleSetup = false;

    const bool alternativeDenoiseDir = true;

    const uint deviceMask = 0xFFFFFFFF;

    List<ReflectionProbe> reflectionProbes;

    public ftLightmapsStorage renderSettingsStorage;

    BakeryLightmapGroup currentGroup;
    LightingDataAsset newAssetLData;

    public static bool hasAnyProbes = false;
    public static bool hasAnyVolumes = false;
    public static bool hasAnyShadowmasks = false;
    static int maxSamplesPerPointLightBatch = 1024;

    public static bool compressVolumes = false;

    Vector2 scrollPos;

    public static ftGlobalStorage gstorage;
    static BakeryProjectSettings pstorage;

    public static string scenePath = "";
    public static string scenePathQuoted = "";
#if !LAUNCH_VIA_DLL
    static string dllPath;
#endif
    public static string outputPath = "BakeryLightmaps";
    public static string outputPathFull = "";

    BakeryLightMesh[] All;
    BakeryPointLight[] AllP;
    BakerySkyLight[] All2;
    BakeryDirectLight[] All3;

    const int PASS_LDR = 1;
    const int PASS_FLOAT = 2;
    const int PASS_HALF = 4;
    const int PASS_MASK = 8;
    const int PASS_SECONDARY_HALF = 16;
    const int PASS_MASK1 = 32;
    const int PASS_DIRECTION = 64;
    const int PASS_RNM0 = 128;
    const int PASS_RNM1 = 256;
    const int PASS_RNM2 = 512;
    const int PASS_RNM3 = 1024;

    Dictionary<string, bool> lmnameComposed;

    static GUIStyle foldoutStyle;

    static BakeryVolume[] lastFoundBakeableVolumes = null;

    List<BakeryLightmapGroupPlain> groupListPlain;
    List<BakeryLightmapGroupPlain> groupListGIContributingPlain;

    int[] uvBuffOffsets;
    int[] uvBuffLengths;
    float[] uvSrcBuff;
    float[] uvDestBuff;
    int[] lmrIndicesOffsets;
    int[] lmrIndicesLengths;
    int[] lmrIndicesBuff;
    int[] lmGroupLODResFlags;
    int[] lmGroupMinLOD;
    int[] lmGroupLODMatrix;

    public static Material matCubemapToStrip;

    Dictionary<int, int> shadowmaskGroupIDToChannel;

    static List<GameObject> overlappingLights;

    static LightingDataAsset emptyLDataAsset;

#if !LAUNCH_VIA_DLL
    public static void PatchPath()
    {
        string currentPath = System.Environment.GetEnvironmentVariable("PATH", System.EnvironmentVariableTarget.Process);
        dllPath = System.Environment.CurrentDirectory + Path.DirectorySeparatorChar + "Assets" + Path.DirectorySeparatorChar + "Editor" + Path.DirectorySeparatorChar + "x64";
        if(!currentPath.Contains(dllPath))
        {
            System.Environment.SetEnvironmentVariable("PATH", currentPath + Path.PathSeparator + dllPath, System.EnvironmentVariableTarget.Process);
        }
    }

    static ftRenderLightmap()
    {
        PatchPath();
    }
#endif

    void ValidateFileAttribs(string file)
    {
        var attribs = File.GetAttributes(file);
        if ((attribs & FileAttributes.ReadOnly) != 0)
        {
            File.SetAttributes(file, attribs & ~FileAttributes.ReadOnly);
        }
    }

    static List<string> loadedScenes;
    static List<bool> loadedScenesEnabled;
    static List<bool> loadedScenesActive;
    static Scene loadedDummyScene;
    static bool scenesUnloaded = false;
    static public void UnloadScenes()
    {
        EditorSceneManager.MarkAllScenesDirty();
        EditorSceneManager.SaveOpenScenes();

        loadedScenes = new List<string>();
        loadedScenesEnabled = new List<bool>();
        loadedScenesActive = new List<bool>();
        var sceneCount = EditorSceneManager.sceneCount;
        var activeScene = EditorSceneManager.GetActiveScene();
        for(int i=0; i<sceneCount; i++)
        {
            var s = EditorSceneManager.GetSceneAt(i);
            loadedScenes.Add(s.path);
            loadedScenesEnabled.Add(s.isLoaded);
            loadedScenesActive.Add(s == activeScene);
        }

        loadedDummyScene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        SceneManager.SetActiveScene(loadedDummyScene);
        RenderSettings.skybox = null;
        scenesUnloaded = true;
    }

    public bool TestSystemSpecs()
    {
        if (SystemInfo.graphicsShaderLevel < 30)
        {
            DebugLogError("Bakery requires Shader Model 3.0 or higher to work. Make sure you are not currently using graphics emulation of old shader models.");
            return false;
        }

        /*
        if (SystemInfo.graphicsDeviceType != GraphicsDeviceType.Direct3D11)
        {
            DebugLogError("Bakery requires Unity editor to be running in DX11 mode during the bake.");
            return false;
        }
        */

        if (!Directory.Exists(scenePath))
        {
            var defaultPath = System.Environment.GetEnvironmentVariable("TEMP", System.EnvironmentVariableTarget.Process) + "\\frender";

            ProgressBarEnd();
            bool cont = true;
            if (verbose)
            {
                cont = EditorUtility.DisplayDialog("Bakery", "Chosen temp path cannot be found:\n\n" + scenePath + "\n\nYou can cancel and set a different path in Advanced Settings or just use the default one:\n\n" + defaultPath + "\n", "Use default", "Cancel");
            }
            else
            {
                Debug.LogError("Chosen temp path was not found and set to default");
            }
            if (cont)
            {
                scenePath = defaultPath;
                ftBuildGraphics.scenePath = scenePath;
                scenePathQuoted = "\"" + scenePath + "\"";
            }
            else
            {
                return false;
            }
        }

        if (gstorage != null)
        {
            // last optimal settings detection ran on another GPU
            if (gstorage.gpuName != SystemInfo.graphicsDeviceName)
            {
                foundCompatibleSetup = false; // ask again
            }
            else
            {
                if (!rtxMode && !gstorage.runsNonRTX)
                {
                    if (gstorage.alwaysEnableRTX)
                    {
                        DebugLogInfo("Automatically enabled RTX");
                        rtxMode = true;
                        ftraceExe = ftraceExe6;
                        ftBuildGraphics.exportTerrainAsHeightmap = false;
                        SaveRenderSettings();
                    }
                    else
                    {
                        int choice = EditorUtility.DisplayDialogComplex("Bakery", "This scene has RTX disabled. It is recommended to enable it on your GPU.", "Enable", "Always enable", "Don't enable");
                        if (choice < 2)
                        {
                            // Enable or Always Enable
                            rtxMode = true;
                            ftraceExe = ftraceExe6;
                            ftBuildGraphics.exportTerrainAsHeightmap = false;
                            SaveRenderSettings();

                            if (choice == 1)
                            {
                                // Always Enable
                                gstorage.alwaysEnableRTX = true;
                                EditorUtility.SetDirty(gstorage);
                            }
                        }
                    }
                }

                if (denoise)
                {
                    if (denoiserType == ftGlobalStorage.DenoiserType.Optix5 && !gstorage.runsOptix5)
                    {
                        int choice = EditorUtility.DisplayDialogComplex("Bakery", "This scene has denoiser set to OptiX 5, but your GPU does not seem to support it. Please change the denoiser or re-run Bakery -> Utilities -> Detect optimal settings.", "OK", "Ignore", "Ignore forever");
                        if (choice == 0)
                        {
                            return false;
                        }
                        else if (choice == 2)
                        {
                            gstorage.runsOptix5 = true;
                            EditorUtility.SetDirty(gstorage);
                        }
                    }
                    else if (denoiserType == ftGlobalStorage.DenoiserType.Optix6 && !gstorage.runsOptix6)
                    {
                        int choice = EditorUtility.DisplayDialogComplex("Bakery", "This scene has denoiser set to OptiX 6, but your GPU does not seem to support it. Please change the denoiser or re-run Bakery -> Utilities -> Detect optimal settings.", "OK", "Ignore", "Ignore forever");
                        if (choice == 0)
                        {
                            return false;
                        }
                        else if (choice == 2)
                        {
                            gstorage.runsOptix6 = true;
                            EditorUtility.SetDirty(gstorage);
                        }
                    }
                    else if (denoiserType == ftGlobalStorage.DenoiserType.Optix7 && !gstorage.runsOptix7)
                    {
                        int choice = EditorUtility.DisplayDialogComplex("Bakery", "This scene has denoiser set to OptiX 7, but your GPU does not seem to support it. Please change the denoiser or re-run Bakery -> Utilities -> Detect optimal settings.", "OK", "Ignore", "Ignore forever");
                        if (choice == 0)
                        {
                            return false;
                        }
                        else if (choice == 2)
                        {
                            gstorage.runsOptix7 = true;
                            EditorUtility.SetDirty(gstorage);
                        }
                    }
                    else if (denoiserType == ftGlobalStorage.DenoiserType.OpenImageDenoise && !gstorage.runsOIDN)
                    {
                        int choice = EditorUtility.DisplayDialogComplex("Bakery", "This scene has denoiser set to OpenImageDenoise, but you CPU does not seem to support it. Please change the denoiser or re-run Bakery -> Utilities -> Detect optimal settings.", "OK", "Ignore", "Ignore forever");
                        if (choice == 0)
                        {
                            return false;
                        }
                        else if (choice == 2)
                        {
                            gstorage.runsOIDN = true;
                            EditorUtility.SetDirty(gstorage);
                        }
                    }
                }
            }
        }

        return true;
    }

    void ValidateOutputPath()
    {
        // Remove slashes from the end of the path
        while (outputPath.Length > 0 && (outputPath[outputPath.Length-1] == '/' || outputPath[outputPath.Length-1] == '\\'))
        {
            outputPath = outputPath.Substring(0, outputPath.Length-1);
        }
        var outDir = Application.dataPath + "/" + outputPath;
        if (!Directory.Exists(outDir)) Directory.CreateDirectory(outDir);
        outputPathFull = outputPath;

        if (curSector != null)
        {
            curSectorName = curSector.name;
            outputPathFull += "/" + curSectorName;
            outDir += "/" + curSectorName;
            if (!Directory.Exists(outDir)) Directory.CreateDirectory(outDir);
        }
        else
        {
            curSectorName = "";
        }
    }

    public static double GetTime()
    {
        return (System.DateTime.Now.Ticks / System.TimeSpan.TicksPerMillisecond) / 1000.0;
    }

    public static double GetTimeMs()
    {
        return System.DateTime.Now.Ticks / System.TimeSpan.TicksPerMillisecond;
    }

    static public void LoadScenes()
    {
        var sceneCount = loadedScenes.Count;
        for(int i=0; i<sceneCount; i++)
        {
            EditorSceneManager.OpenScene(loadedScenes[i], loadedScenesEnabled[i] ? OpenSceneMode.Additive : OpenSceneMode.AdditiveWithoutLoading);
        }
        if (loadedDummyScene.isLoaded) EditorSceneManager.UnloadSceneAsync(loadedDummyScene);
        scenesUnloaded = false;
    }

    bool ServerGetData()
    {
        var storageGO = ftLightmaps.FindInScene("!ftraceLightmaps", EditorSceneManager.GetActiveScene());
        if (storageGO == null) return false;
        var storage = storageGO.GetComponent<ftLightmapsStorage>();
        if (storage == null) return false;
        var list = storage.serverGetFileList;
        if (list == null) return false;

        lightmapHasColor = storage.lightmapHasColor;
        lightmapHasMask = storage.lightmapHasMask;
        lightmapHasDir = storage.lightmapHasDir;
        lightmapHasRNM = storage.lightmapHasRNM;

        ftClient.ServerGetData(list);
        return true;
    }

#if LAUNCH_VIA_DLL
    public static int lastReturnValue = 0;
    public static IEnumerator ProcessCoroutine(string app, string args, bool setWorkDir = true)
    {
        var exeProcess = RunLocalProcess(app+" "+args, setWorkDir);
        if (exeProcess == (System.IntPtr)null)
        {
            DebugLogError(app + " launch failed (see console for details)");
            userCanceled = false;
            ProgressBarEnd();
            yield break;
        }
        while(!IsProcessFinished(exeProcess))
        {
            yield return null;
            userCanceled = simpleProgressBarCancelled();
            if (userCanceled)
            {
                ProgressBarEnd();
                yield break;
            }
        }
        lastReturnValue = GetProcessReturnValueAndClose(exeProcess);
    }
#endif

    int GenerateVBTraceTexLOD(int id)
    {
        // Write vbTraceTex for LMGroup
        var vbtraceTexPosNormalArray = ftBuildGraphics.vbtraceTexPosNormalArray;
        var vbtraceTexUVArray = ftBuildGraphics.vbtraceTexUVArray;
        var vbtraceTexUVArrayLOD = ftBuildGraphics.vbtraceTexUVArrayLOD;

        var flodInfo = new BinaryReader(File.Open(scenePath + "/lods" + id + ".bin", FileMode.Open, FileAccess.Read));
        flodInfo.BaseStream.Seek(0, SeekOrigin.End);
        var numLMs = flodInfo.BaseStream.Position;
        flodInfo.BaseStream.Seek(0, SeekOrigin.Begin);
        if (lmGroupLODResFlags == null || lmGroupLODResFlags.Length != numLMs)
        {
            lmGroupLODResFlags = new int[numLMs];
        }
        var lodLevels = new int[numLMs];
        for(int i=0; i<numLMs; i++)
        {
            lodLevels[i] = (int)flodInfo.ReadByte();
            if (lodLevels[i] > 0 && lodLevels[i] < 30)
            {
                //int minLOD = lmGroupMinLOD[id];
                int minLOD = lmGroupMinLOD[i];
                if (lodLevels[i] > minLOD) lodLevels[i] = minLOD;
                lmGroupLODResFlags[i] |= 1 << (lodLevels[i] - 1);
            }
            lmGroupLODMatrix[id * numLMs + i] = lodLevels[i];
            //Debug.LogError("GenerateVBTraceTexLOD: " + id+" to "+i+" = "+lodLevels[i]+" ("+lmGroupLODResFlags[i]+", "+numLMs+")");
        }
        flodInfo.Close();

        var fvbtraceTex2 = new BinaryWriter(File.Open(scenePath + "/vbtraceTex" + id + ".bin", FileMode.Create));
        var numTraceVerts = vbtraceTexUVArray.Count/2;
        for(int k=0; k<numTraceVerts; k++)
        {
            fvbtraceTex2.Write(vbtraceTexPosNormalArray[k * 6]);
            fvbtraceTex2.Write(vbtraceTexPosNormalArray[k * 6 + 1]);
            fvbtraceTex2.Write(vbtraceTexPosNormalArray[k * 6 + 2]);
            fvbtraceTex2.Write(vbtraceTexPosNormalArray[k * 6 + 3]);
            fvbtraceTex2.Write(vbtraceTexPosNormalArray[k * 6 + 4]);
            fvbtraceTex2.Write(vbtraceTexPosNormalArray[k * 6 + 5]);

            int id2 = (int)(vbtraceTexUVArray[k * 2]/10);
            //if ((int)(vbtraceTexUVArray[k * 2]/10) == i)
            if (id2 < 0 || lodLevels[id2] == 0)
            {
                // own lightmap is full resoltion
                fvbtraceTex2.Write(vbtraceTexUVArray[k * 2]);
                fvbtraceTex2.Write(vbtraceTexUVArray[k * 2 + 1]);
            }
            else
            {
                // other lightmaps use LODs
                fvbtraceTex2.Write(vbtraceTexUVArrayLOD[k * 2]);
                fvbtraceTex2.Write(vbtraceTexUVArrayLOD[k * 2 + 1]);
            }
        }
        fvbtraceTex2.Close();
        return 0;
    }

    int SampleCount(int samples)
    {
        if (samples == 0) return 0;
        return System.Math.Max(samples / sampleDivisor,1);
    }

    bool GroupAffectedByGroup(int curSceneLodLevel, int otherSceneLodLevel)
    {
        if (curSceneLodLevel < 0)
        {
            if (otherSceneLodLevel > 0) return false; // non-LOD sees itself and LOD0
        }
        else
        {
            //if (otherSceneLodLevel >= 0 && otherSceneLodLevel != curSceneLodLevel) return false; // LOD sees itself and non-LOD
            // actually LOD sees non-LOD and other affecting objects we previously calculated
            if (otherSceneLodLevel >= 0)
            {
                var visLists = ftBuildGraphics.lodLevelsVisibleInLodLevel;
                if (visLists != null)
                {
                    List<int> visList;
                    if (visLists.TryGetValue(curSceneLodLevel, out visList))
                    {
                        if (visList != null)
                        {
                            if (visList.IndexOf(otherSceneLodLevel) < 0) return false;
                        }
                    }
                }
            }
        }
        return true;
    }

    void GenerateGIParameters(int id, string nm, int bounce, int bounces, bool useDir, int sceneLodLevel)
    {
        var fgi = new BinaryWriter(File.Open(scenePath + (deferredMode ? "/gi_" + nm + bounce + ".bin" : "/gi.bin"), FileMode.Create));
        fgi.Write(SampleCount(giSamples));
        fgi.Write(giBackFaceWeight);
        fgi.Write(bounce == bounces-1 ? "" : "uvalbedo_" + nm + (compressedGBuffer ? ".lz4" : ".dds"));

        int count = 0;
        foreach(var lmgroup2 in groupListGIContributingPlain)
        {
            if (lmgroup2.probes) continue; // nothing is ever affected by probes
            if (!GroupAffectedByGroup(sceneLodLevel, lmgroup2.sceneLodLevel)) continue;
            count++;
        }
        fgi.Write(count);

        foreach(var lmgroup2 in groupListGIContributingPlain)
        {
            if (lmgroup2.probes) continue; // nothing is ever affected by probes
            if (!GroupAffectedByGroup(sceneLodLevel, lmgroup2.sceneLodLevel)) continue;
            fgi.Write(lmgroup2.id);

            /*if (giLodModeEnabled)
            {
                var lod = lmGroupLODMatrix[id * groupListPlain.Count + lmgroup2.id];
                if (lod == 0)
                {
                    fgi.Write(lmgroup2.name + "_diffuse_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                }
                else if (lod > 0 && lod < 127)
                {
                    //Debug.LogError("GenerateGIParameters: " + id+" to "+lmgroup2.id+" = "+lod+" ("+lmGroupLODResFlags[lmgroup2.id]+", "+groupListPlain.Count+")");
                    fgi.Write(lmgroup2.name + "_diffuse_HDR_LOD" + lod + (compressedOutput ? ".lz4" : ".dds"));
                }
                else
                {
                    fgi.Write("");
                }
            }
            else
            {*/
                fgi.Write(lmgroup2.name + "_diffuse_HDR" + (compressedOutput ? ".lz4" : ".dds"));
            //}
        }
        if (useDir) fgi.Write(bounce == bounces - 1 ? (nm + "_lights_Dir" + (compressedOutput ? ".lz4" : ".dds")) : "");
        fgi.Close();
    }

    float Pack4BytesToFloat(int r, int g, int b, int a)
    {
        // 6 bits precision

        // Move to 0-63 range
        r /= 4;
        g /= 4;
        b /= 4;
        a /= 4;

        return (r << 18) | (g << 12) | (b << 6) | a;
    }

    float Pack3BytesToFloat(int r, int g, int b)
    {
        // 8 bits precision
        var packed = (r << 16) | (g << 8) | b;
        return (packed) / (float)(1 << 24);
    }

    void WriteString(BinaryWriter flist, string str)
    {
        flist.Write(str.Length);
        for(int i=0; i<str.Length; i++)
        {
            flist.Write(str[i]);
        }
        byte zeroByte = 0;
        flist.Write(zeroByte);
    }

    Convex GetSpotConvex(Transform lbT, float angle, float range)
    {
        //var lbT = lb.transform;

        // radius computed same way as in BakeryPointLight gizmo drawing code
        //float angle = lb.spotAngle;
        float angle2 = (180 - angle) * Mathf.Deg2Rad * 0.5f;
        float x = 1 / Mathf.Sin(angle2);
        x = Mathf.Sqrt(x * x - 1);
        float radius = x * range;

        var bfar = lbT.position + lbT.forward * range;
        var bright = lbT.right * radius;
        var bup = lbT.up * radius;

        var bvertices = new Vector3[5];
        bvertices[0] = lbT.position;
        bvertices[1] = (bfar - bright) - bup;
        bvertices[2] = (bfar + bright) - bup;
        bvertices[3] = (bfar + bright) + bup;
        bvertices[4] = (bfar - bright) + bup;

        var bplanes = new Plane[5];
        bplanes[0] = new Plane(bvertices[1], bvertices[4], bvertices[3]); // cap
        bplanes[1] = new Plane(bvertices[0], bvertices[1], bvertices[2]);
        bplanes[2] = new Plane(bvertices[0], bvertices[2], bvertices[3]);
        bplanes[3] = new Plane(bvertices[0], bvertices[3], bvertices[4]);
        bplanes[4] = new Plane(bvertices[0], bvertices[4], bvertices[1]);

        var bconvex = new Convex();
        bconvex.vertices = bvertices;
        bconvex.planes = bplanes;

        return bconvex;
    }

    bool ConvexIntersect(Convex a, Convex b)
    {
        // all B verts must be on the same side of at least one plane of A
        for(int p=0; p<a.planes.Length; p++)
        {
            bool outside = true;
            for(int v=0; v<b.vertices.Length; v++)
            {
                outside = !a.planes[p].GetSide(b.vertices[v]);
                if (!outside) break; // intersects or inside
            }
            if (outside) return false;
        }
        return true;
    }

    bool ConvexSphereIntersect(Convex a, Vector3 bpos, float bradius)
    {
        // sphere must be outside of any plane with distance >= radius
        for(int p=0; p<a.planes.Length; p++)
        {
            float d = -a.planes[p].GetDistanceToPoint(bpos);
            if (d > bradius) return false;
        }
        return true;
    }

    int GenerateVertexBakedMeshes(int LMID, string lmname, bool hasShadowMask, bool hasDir, bool hasSH, bool monoSH)
    {
        int errCode = 0;
        int errCode2 = 0;
        int errCode3 = 0;
        int errCode4 = 0;
        int errCode5 = 0;
        int errCode6 = 0;

        //var vertexOffsetLengths = new List<int>();
        int totalVertexCount = 0;
        for(int i=0; i<storage.bakedIDs.Count; i++)
        {
            if (storage.bakedIDs[i] != LMID) continue;
            var mr = storage.bakedRenderers[i];
            //var vertexOffset = storage.bakedVertexOffset[i];

            //vertexOffsetLengths.Add(vertexOffset);
            var sharedMesh = ftBuildGraphics.GetSharedMesh(mr);
            int vertexCount = sharedMesh.vertexCount;
            //vertexOffsetLengths.Add(vertexCount);

            totalVertexCount += vertexCount;
        }

        if (totalVertexCount == 0) return 0;

        AssetDatabase.StartAssetEditing();

        int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)totalVertexCount));
        atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)tileSize) * tileSize;

        var vertColors = new byte[atlasTexSize * atlasTexSize * 4];
        byte[] vertColorsMask = null;
        byte[] vertColorsDir = null;
        byte[] vertColorsSHL1x = null;
        byte[] vertColorsSHL1y = null;
        byte[] vertColorsSHL1z = null;
        if (hasShadowMask) vertColorsMask = new byte[atlasTexSize * atlasTexSize * 4];
        if (hasDir) vertColorsDir = new byte[atlasTexSize * atlasTexSize * 4];
        if (hasSH)
        {
            vertColorsSHL1x = new byte[atlasTexSize * atlasTexSize * 4];
            vertColorsSHL1y = new byte[atlasTexSize * atlasTexSize * 4];
            vertColorsSHL1z = new byte[atlasTexSize * atlasTexSize * 4];
        }

        var sceneCount = SceneManager.sceneCount;

        GCHandle handle = GCHandle.Alloc(vertColors, GCHandleType.Pinned);
        GCHandle handleMask = new GCHandle();
        GCHandle handleDir = new GCHandle();
        GCHandle handleL1x = new GCHandle();
        GCHandle handleL1y = new GCHandle();
        GCHandle handleL1z = new GCHandle();
        if (hasShadowMask) handleMask = GCHandle.Alloc(vertColorsMask, GCHandleType.Pinned);
        if (hasDir) handleDir = GCHandle.Alloc(vertColorsDir, GCHandleType.Pinned);
        if (hasSH)
        {
            handleL1x = GCHandle.Alloc(vertColorsSHL1x, GCHandleType.Pinned);
            handleL1y = GCHandle.Alloc(vertColorsSHL1y, GCHandleType.Pinned);
            handleL1z = GCHandle.Alloc(vertColorsSHL1z, GCHandleType.Pinned);
        }
        try
        {
            System.IntPtr pointer = handle.AddrOfPinnedObject();
            System.IntPtr pointerMask = (System.IntPtr)0;
            System.IntPtr pointerDir = (System.IntPtr)0;
            System.IntPtr pointerL1x = (System.IntPtr)0;
            System.IntPtr pointerL1y = (System.IntPtr)0;
            System.IntPtr pointerL1z = (System.IntPtr)0;
            if (hasShadowMask) pointerMask = handleMask.AddrOfPinnedObject();
            if (hasDir) pointerDir = handleDir.AddrOfPinnedObject();
            if (hasSH)
            {
                pointerL1x = handleL1x.AddrOfPinnedObject();
                pointerL1y = handleL1y.AddrOfPinnedObject();
                pointerL1z = handleL1z.AddrOfPinnedObject();
            }

            errCode = halffloat2vb(scenePath + "\\" + lmname + (hasSH ? "_final_L0" : "_final_HDR") + (compressedOutput ? ".lz4" : ".dds"), pointer, 0);

            if (hasShadowMask)
                errCode2 = halffloat2vb(scenePath + "\\" + lmname + "_Mask" + (compressedOutput ? ".lz4" : ".dds"), pointerMask, 1);
            if (hasDir)
                errCode3 = halffloat2vb(scenePath + "\\" + lmname + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds"), pointerDir, 1);

            if (hasSH)
            {
                errCode4 = halffloat2vb(scenePath + "\\" + lmname + "_final_L1x" + (compressedOutput ? ".lz4" : ".dds"), pointerL1x, 1);
                errCode5 = halffloat2vb(scenePath + "\\" + lmname + "_final_L1y" + (compressedOutput ? ".lz4" : ".dds"), pointerL1y, 1);
                errCode6 = halffloat2vb(scenePath + "\\" + lmname + "_final_L1z" + (compressedOutput ? ".lz4" : ".dds"), pointerL1z, 1);
            }

            if (errCode == 0 && errCode2 == 0 && errCode3 == 0 && errCode4 == 0 && errCode5 == 0 && errCode6 == 0)
            {
                for(int i=0; i<storage.bakedIDs.Count; i++)
                {
                    if (storage.bakedIDs[i] != LMID) continue;
                    var mr = storage.bakedRenderers[i];
                    var vertexOffset = storage.bakedVertexOffset[i];

                    var mesh = ftBuildGraphics.GetSharedMesh(mr);
                    int vertexCount = mesh.vertexCount;

                    var colorBuff = new Color32[vertexCount];
                    for(int j=0; j<vertexCount; j++)
                    {
                        colorBuff[j] = new Color32(vertColors[(vertexOffset + j) * 4],
                                                   vertColors[(vertexOffset + j) * 4 + 1],
                                                   vertColors[(vertexOffset + j) * 4 + 2],
                                                   vertColors[(vertexOffset + j) * 4 + 3]);
                    }

                    var newMesh = new Mesh();
                    newMesh.vertices = mesh.vertices;
                    newMesh.colors32 = colorBuff;

                    //float packScale = 254.0f / 255.0f;
                    //maskBuff[j] = new Vector2(r+(g/255.0f)*packScale, b+(a/255.0f)*packScale);

                    /*
                    uv2
                        x: shadowmask
                        y: dir/L1x
                    uv3
                        x: L1y
                        y: L1z
                    */

                    if (hasShadowMask || hasDir || hasSH)
                    {
                        var buff = new Vector2[vertexCount];
                        byte sr = 0, sg = 0, sb = 0, sa = 0;
                        byte dr = 0, dg = 0, db = 0;//, da = 0;
                        for(int j=0; j<vertexCount; j++)
                        {
                            if (hasShadowMask)
                            {
                                sr = vertColorsMask[(vertexOffset + j) * 4];
                                sg = vertColorsMask[(vertexOffset + j) * 4 + 1];
                                sb = vertColorsMask[(vertexOffset + j) * 4 + 2];
                                sa = vertColorsMask[(vertexOffset + j) * 4 + 3];
                            }
                            if (hasDir)
                            {
                                dr = vertColorsDir[(vertexOffset + j) * 4];
                                dg = vertColorsDir[(vertexOffset + j) * 4 + 1];
                                db = vertColorsDir[(vertexOffset + j) * 4 + 2];
                                //da = vertColorsDir[(vertexOffset + j) * 4 + 3];
                            }
                            else if (hasSH && monoSH)
                            {
                                const float rweight = 0.33333f;//0.2125f;
                                const float gweight = 0.33333f;//0.7154f;
                                const float bweight = 0.33333f;//0.0721f;
                                dr = (byte)(vertColorsSHL1x[(vertexOffset + j) * 4] * rweight + vertColorsSHL1x[(vertexOffset + j) * 4 + 1] * gweight + vertColorsSHL1x[(vertexOffset + j) * 4 + 2] * bweight);
                                dg = (byte)(vertColorsSHL1y[(vertexOffset + j) * 4] * rweight + vertColorsSHL1y[(vertexOffset + j) * 4 + 1] * gweight + vertColorsSHL1y[(vertexOffset + j) * 4 + 2] * bweight);
                                db = (byte)(vertColorsSHL1z[(vertexOffset + j) * 4] * rweight + vertColorsSHL1z[(vertexOffset + j) * 4 + 1] * gweight + vertColorsSHL1z[(vertexOffset + j) * 4 + 2] * bweight);
                            }
                            else if (hasSH)
                            {
                                dr = vertColorsSHL1x[(vertexOffset + j) * 4];
                                dg = vertColorsSHL1x[(vertexOffset + j) * 4 + 1];
                                db = vertColorsSHL1x[(vertexOffset + j) * 4 + 2];
                            }
                            buff[j] = new Vector2(Pack4BytesToFloat(sr,sg,sb,sa), Pack3BytesToFloat(dr,dg,db));
                        }
                        newMesh.uv2 = buff;
                    }

                    if (hasSH && !monoSH)
                    {
                        var buff = new Vector2[vertexCount];
                        byte r1,g1,b1;
                        byte r2,g2,b2;
                        for(int j=0; j<vertexCount; j++)
                        {
                            r1 = vertColorsSHL1y[(vertexOffset + j) * 4];
                            g1 = vertColorsSHL1y[(vertexOffset + j) * 4 + 1];
                            b1 = vertColorsSHL1y[(vertexOffset + j) * 4 + 2];

                            r2 = vertColorsSHL1z[(vertexOffset + j) * 4];
                            g2 = vertColorsSHL1z[(vertexOffset + j) * 4 + 1];
                            b2 = vertColorsSHL1z[(vertexOffset + j) * 4 + 2];

                            buff[j] = new Vector2(Pack3BytesToFloat(r1,g1,b1), Pack3BytesToFloat(r2,g2,b2));
                        }
                        newMesh.uv3 = buff;
                    }

                    //newMesh.triangles = mesh.triangles; // debug only!

                    for(int s=0; s<sceneCount; s++)
                    {
                        var scene = EditorSceneManager.GetSceneAt(s);
                        if (!scene.isLoaded) continue;
                        var st = storages[scene];
                        st.bakedVertexColorMesh[i] = newMesh;
                    }

                    var outPath = "Assets/" + outputPathFull + "/" + lmname + i + ".asset";
                    if (File.Exists(outPath)) ValidateFileAttribs(outPath);
                    AssetDatabase.CreateAsset(newMesh, outPath);
                }
                AssetDatabase.SaveAssets();
            }
            else
            {
                Debug.LogError("hf2vb: " + errCode + " " + errCode2 + " " + errCode3 + " " + errCode4 + " " + errCode5 + " " + errCode6);
            }
        }
        finally
        {
            if (handle.IsAllocated) handle.Free();
            if (handleMask.IsAllocated) handleMask.Free();
            if (handleDir.IsAllocated) handleDir.Free();
            if (handleL1x.IsAllocated) handleL1x.Free();
            if (handleL1y.IsAllocated) handleL1y.Free();
            if (handleL1z.IsAllocated) handleL1z.Free();
        }

        AssetDatabase.StopAssetEditing();

        return errCode;
    }

    public void RenderReflectionProbesButton(bool showMsgWindows = true)
    {
        ValidateOutputPath();
        restoreFromGlobalSector = false;
        userCanceled = false;
        if (Application.isPlaying) return;
        progressFunc = RenderReflProbesFunc();
        EditorApplication.update += RenderReflProbesUpdate;
        verbose = showMsgWindows;
        bakeInProgress = true;
        showProgressBar = true;
    }

    public void RenderLightProbesButton(bool showMsgWindows = true)
    {
        ValidateOutputPath();
        restoreFromGlobalSector = false; // changes to true after global sector is initialized
        userCanceled = false;
        fullSectorRender = false;
        if (Application.isPlaying) return;
        if (!TestSystemSpecs()) return;
        if (lightProbeMode == LightProbeMode.Legacy)
        {
            progressFunc = RenderLightProbesFunc();
            EditorApplication.update += RenderLightProbesUpdate;
            verbose = showMsgWindows;
            bakeInProgress = true;
        }
        else if (lightProbeMode == LightProbeMode.L1)
        {
            selectedOnly = false;
            probesOnlyL1 = true;
            progressFunc = RenderLightmapFunc();
            EditorApplication.update += RenderLightmapUpdate;
            verbose = showMsgWindows;
            bakeInProgress = true;
        }
        showProgressBar = true;
    }

    public void RenderButton(bool showMsgWindows = true)
    {
        ValidateOutputPath();

        restoreFromGlobalSector = true;
        userCanceled = false;
        if (Application.isPlaying) return;
        if (!TestSystemSpecs()) return;
        verbose = showMsgWindows;

        if (clientMode)
        {
            if (!ftClient.connectedToServer)
            {
                DebugLogError("Network rendering is enabled, but the server is disconnected.");
                return;
            }
            if (ftClient.lastServerErrorCode == ftClient.SERVERERROR_BUSY)
            {
                DebugLogError("Server is busy.");
                return;
            }
        }
        else
        {
            if (!foundCompatibleSetup && verbose)
            {
                if (gstorage != null) gstorage.foundCompatibleSetup = true;
                foundCompatibleSetup = true;
                int answer = EditorUtility.DisplayDialogComplex("Bakery", "Would you like to automatically detect optimal settings for your hardware? You can also do it later via Bakery/Utilities/Detect optimal settings", "Yes", "No", "Never");
                if (answer == 0)
                {
                    ftDetectSettings.DetectCompatSettings();
                    return;
                }
                else if (answer == 2)
                {
                    gstorage.foundCompatibleSetup = foundCompatibleSetup = true;
                    gstorage.gpuName = SystemInfo.graphicsDeviceName;
                    EditorUtility.SetDirty(gstorage);
                }
            }
        }

        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();

        if (pstorage.deletePreviousLightmapsBeforeBake)
        {
            ftClearMenu.ClearBakedData(ftClearMenu.SceneClearingMode.nothing, true);
        }

        if (OnPreFullRender != null)
        {
            OnPreFullRender.Invoke(this, null);
        }

#if UNITY_2018_3_OR_NEWER
        unityEditorHWND = GetForegroundWindow();
        var wnd = GetParent(unityEditorHWND);
        while(wnd != (System.IntPtr)0)
        {
            unityEditorHWND = wnd;
            wnd = GetParent(unityEditorHWND);
        }

        var titleBuff = new StringBuilder(256);
        if (GetWindowText(unityEditorHWND, titleBuff, 256) > 0)
        {
            DebugLogInfo("Editor window: " + titleBuff.ToString());
        }
        else
        {
            DebugLogInfo("Unable to get Editor window name");
        }
#endif

        selectedOnly = false;
        probesOnlyL1 = false;
        fullSectorRender = curSector != null;
        hasAnyVolumes = true; // possibly - ftBuildGraphics will figure it out
        hasAnyShadowmasks = false;
        progressFunc = RenderLightmapFunc();
        EditorApplication.update += RenderLightmapUpdate;
        bakeInProgress = true;
        showProgressBar = true;
    }

    string Float2String(float val)
    {
        return ("" + val).Replace(",", "."); // newer Unity versions can break float formatting by incorrectly applying regional settings
    }

    public static string progressBarText;
    public static float progressBarPercent = 0;
    float progressBarStep = 0;
    public static bool progressBarEnabled = false;
    public static bool userCanceled = false; // can be used externally to check if the bake progress was cancelled
    int progressSteps, progressStepsDone;
    IEnumerator progressFunc;
    public static bool bakeInProgress = false;
    void ProgressBarInit(string startText)
    {
        ProgressBarSetStep(0);
        progressBarText = startText;
        progressBarEnabled = true;
        if (showProgressBar) simpleProgressBarShow("Bakery", progressBarText, progressBarPercent, progressBarStep, false);
    }
    void ProgressBarSetStep(float step)
    {
        progressBarStep = step;
    }
    void ProgressBarShow(string text, float percent, bool onTop)
    {
        progressBarText = text;
        progressBarPercent = percent;
        if (showProgressBar) simpleProgressBarShow("Bakery", progressBarText, progressBarPercent, progressBarStep, onTop);
        userCanceled = simpleProgressBarCancelled();
    }
    public static void ProgressBarEnd(bool freeAreas = true)
    {
        if (freeAreas) ftBuildGraphics.FreeTemporaryAreaLightMeshes();
        if (scenesUnloaded) LoadScenes();

        if (revertReflProbesValue)
        {
            QualitySettings.realtimeReflectionProbes = reflProbesValue;
            revertReflProbesValue = false;
        }

        if (userCanceled && restoreFromGlobalSector && ftRenderLightmap.instance != null)
        {
            if (ftRenderLightmap.instance.unloadScenesInDeferredMode)
            {
                MergeSectorsDeferred();
            }
            else
            {
                MergeSectors();
            }
        }

        progressBarEnabled = false;
        if (showProgressBar) simpleProgressBarEnd();
    }
    void OnInspectorUpdate()
    {
        Repaint();
    }
    string twoChars(int i)
    {
        if (i < 10) return "0" + i;
        return "" + i;
    }
    void OnGUI()
    {
        if (progressBarEnabled)
        {
            return;
        }

        #if UNITY_2018_2_OR_NEWER && !UNITY_2019_1_OR_NEWER
                // Jittery window fix by farfelu
                if (EditorGUIUtility.pixelsPerPoint == 1.25f)
                {
                    this.minSize = new Vector2(252, this.minSize.y);
                }
        #endif

        if (tryFixingSceneView)
        {
            FindGlobalStorage();
            if (gstorage != null)
            {
                // Fix checker preview being incorrectly set for scene view
                if (gstorage.checkerPreviewOn && !showChecker)
                {
                    var sceneView = SceneView.lastActiveSceneView;
                    if (sceneView != null)
                    {
                        sceneView.SetSceneViewShaderReplace(null, null);
                        gstorage.checkerPreviewOn = false;
                        if (ftAtlasPreview.instance != null) ftAtlasPreview.instance.OnGUI();
                        EditorUtility.SetDirty(gstorage);
                    }
                }

                if (gstorage.rtSceneViewPreviewOn)
                {
                    var sceneView = SceneView.lastActiveSceneView;
                    if (sceneView != null)
                    {
                        sceneView.SetSceneViewShaderReplace(null, null);
                        gstorage.rtSceneViewPreviewOn = false;
                        if (ftAtlasPreview.instance != null) ftAtlasPreview.instance.OnGUI();
                        EditorUtility.SetDirty(gstorage);
                    }
                }
            }
            tryFixingSceneView = false;
        }

        int y = 0;

        var headerStyle = EditorStyles.label;
        var numberBoxStyle = EditorStyles.numberField;
        var textBoxStyle = EditorStyles.textField;

#if UNITY_2019_3_OR_NEWER
        if (EditorGUIUtility.isProSkin)
        {
            headerStyle = new GUIStyle(EditorStyles.whiteLabel);
        }
        else
        {
            headerStyle = new GUIStyle(EditorStyles.label);
        }
        headerStyle.alignment = TextAnchor.UpperLeft;
        headerStyle.padding = new RectOffset(0,0,5,0);

        numberBoxStyle = new GUIStyle(numberBoxStyle);
        numberBoxStyle.alignment = TextAnchor.MiddleLeft;
        numberBoxStyle.contentOffset = new Vector2(0, -1);

        textBoxStyle = new GUIStyle(textBoxStyle);
        textBoxStyle.alignment = TextAnchor.MiddleLeft;
        textBoxStyle.contentOffset = new Vector2(0, -1);
#endif

        if (foldoutStyle == null)
        {
            foldoutStyle = new GUIStyle(EditorStyles.foldout);
            //foldoutStyle.fontStyle = FontStyle.Bold;
        }

        if (PlayerSettings.colorSpace != ColorSpace.Linear)
        {
            y += 15;
            GUI.BeginGroup(new Rect(10, y, 300, 120), "[Gamma color space detected]", headerStyle); y += 30;
#if UNITY_2019_3_OR_NEWER
            int by = 20;
#else
            int by = 15;
#endif
            if (GUI.Button(new Rect(15, by, 200, 20), "Switch project to linear"))
            {
                if (EditorUtility.DisplayDialog("Bakery", "Linear color space is essential for getting realistic results. Switching the project may force Unity to reimport assets. It can take some time, depending on project size. Continue?", "OK", "Cancel"))
                {
                    PlayerSettings.colorSpace = ColorSpace.Linear;
                }
            }
            GUI.EndGroup();
            y += 10;
        }

        var aboutRect = new Rect(10, y+5, 250, 20);
        var linkStyle = new GUIStyle();
        linkStyle.richText = true;
        var clr = GUI.contentColor;
        GUI.contentColor = Color.blue;
        GUI.Label(aboutRect, new GUIContent("<color=#5073c9ff><b>Bakery - GPU Lightmapper by Mr F</b></color>", "Version 1.95. Click to go to Bakery Wiki"), linkStyle);
        GUI.Label(aboutRect, new GUIContent("<color=#5073c9ff><b>____________________________</b></color>", "Go to Bakery Wiki"), linkStyle);
        if (Event.current.type == EventType.MouseUp && aboutRect.Contains(Event.current.mousePosition))
        {
            Application.OpenURL("https://geom.io/bakery/wiki/");
        }
        GUI.contentColor = clr;
        y += 15;

        bool simpleWindowIsTooSmall = position.height < 300;

        float scrollHeight = 0;
        if (settingsMode >= SettingsMode.Advanced || simpleWindowIsTooSmall)
        {
            scrollHeight = 620+y+(showAOSettings ? 65 : 15)+(showPaths ? 70 : 0) + (userRenderMode==RenderMode.Shadowmask ? 20 : 0) + 40;
            if (showPerf) scrollHeight += 160;
#if UNITY_2019_3_OR_NEWER
            scrollHeight += 30;
#endif
            scrollHeight += 40;// + (showCompression ? 25*3 : 0);
            scrollHeight += 60;
            scrollHeight += showTasks2 ? 55+30 : 5;
            scrollHeight += showTasks ? (settingsMode == SettingsMode.Experimental ? 140 : 100) : 0;
            scrollHeight += 20;
            scrollHeight += ftBuildGraphics.texelsPerUnitPerMap ? 120 : 0;
            scrollHeight += showCheckerSettings ? 30+20 : 30;
            scrollHeight += (showCheckerSettings && showChecker) ? 20 : 0;
            scrollHeight += (renderDirMode == RenderDirMode.RNM || renderDirMode == RenderDirMode.SH || renderDirMode == RenderDirMode.MonoSH) ? (showDirWarning ? 60 : 10) : 0;
            if (ftBuildGraphics.unwrapUVs) scrollHeight += 20;
            if (settingsMode == SettingsMode.Advanced) scrollHeight += 100;
            if (settingsMode == SettingsMode.Simple) scrollHeight = this.minSize.y - 30;
            if (settingsMode == SettingsMode.Experimental)
            {
                scrollHeight += 240;
                if (ftBuildGraphics.atlasPacker == ftGlobalStorage.AtlasPacker.xatlas) scrollHeight += 60;
                if (ftBuildGraphics.unwrapUVs) scrollHeight += 30;
                if (denoise) scrollHeight += 20;
                if (showNet) scrollHeight += clientMode ? 120 : 30;
            }
            scrollPos = GUI.BeginScrollView(new Rect(0, 10+y, 270, position.height-20), scrollPos, new Rect(0,10+y,200,scrollHeight));
        }

        if (settingsMode >= SettingsMode.Advanced)
        {
            this.minSize = new Vector2(position.height >= scrollHeight ? 250 : 270, 700);
        }
        this.maxSize = new Vector2(this.minSize.x, settingsMode >= SettingsMode.Advanced ? 820 : this.minSize.y + 1);

        GUI.contentColor = new Color(clr.r, clr.g, clr.b, 0.5f);
        int hours = lastBakeTime / (60*60);
        int minutes = (lastBakeTime / 60) % 60;
        int seconds = lastBakeTime % 60;
        GUI.Label(new Rect(105, y+10, 130, 20), "Last bake: "+twoChars(hours)+"h "+twoChars(minutes)+"m "+twoChars(seconds)+"s", EditorStyles.miniLabel);
        GUI.contentColor = clr;

        GUI.BeginGroup(new Rect(10, 10+y, 300, 340), "Settings mode", headerStyle);
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        var opts = new GUILayoutOption[1];
        opts[0] = GUILayout.Width(225);
        settingsMode = (SettingsMode)EditorGUILayout.EnumPopup(settingsMode, opts);
        y += 40;
        //EditorGUILayout.Space();
        //EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        userRenderMode = (RenderMode)EditorGUILayout.EnumPopup(userRenderMode, opts);
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        renderDirMode = (RenderDirMode)EditorGUILayout.EnumPopup(renderDirMode, opts);

        if (settingsMode >= SettingsMode.Advanced)
        {
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            //EditorGUILayout.Space();
            lightProbeMode = (LightProbeMode)EditorGUILayout.EnumPopup(lightProbeMode, opts);
        }

        if (settingsMode == SettingsMode.Experimental)
        {
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            ftBuildGraphics.atlasPacker = (ftGlobalStorage.AtlasPacker)EditorGUILayout.EnumPopup(ftBuildGraphics.atlasPacker, opts);
        }

        if (settingsMode >= SettingsMode.Advanced)
        {
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.Space();

            var uvMode = AdjustUVMode.DontChange;
            if (ftBuildGraphics.unwrapUVs)
            {
                uvMode = AdjustUVMode.Adjust;
            }
            else if (ftBuildGraphics.forceDisableUnwrapUVs)
            {
                uvMode = AdjustUVMode.ForceDisableAdjust;
            }

            uvMode = (AdjustUVMode)EditorGUILayout.Popup((int)uvMode, adjustUVOptions, opts);

            if (uvMode == AdjustUVMode.DontChange)
            {
                ftBuildGraphics.unwrapUVs = false;
                ftBuildGraphics.forceDisableUnwrapUVs = false;
            }
            else if (uvMode == AdjustUVMode.Adjust)
            {
                ftBuildGraphics.unwrapUVs = true;
                ftBuildGraphics.forceDisableUnwrapUVs = false;
            }
            else
            {
                ftBuildGraphics.unwrapUVs = false;
                ftBuildGraphics.forceDisableUnwrapUVs = true;
            }
        }

        if (settingsMode == SettingsMode.Experimental && ftBuildGraphics.unwrapUVs)
        {
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            //EditorGUILayout.Space();
            var prev = unwrapper;
            unwrapper = (ftGlobalStorage.Unwrapper)EditorGUILayout.EnumPopup(unwrapper, opts);
            if (unwrapper != prev)
            {
                if (unwrapper == ftGlobalStorage.Unwrapper.xatlas)
                {
                    FindGlobalStorage();
                    if (gstorage != null && !gstorage.xatlasWarningShown)
                    {
                        gstorage.xatlasWarningShown = true;
                        EditorUtility.SetDirty(gstorage);
                        if (!EditorUtility.DisplayDialog("Bakery", "xatlas may provide better UV unwrapping for models with 'Generate lightmap UVs' if 'Adjust UV padding' is enabled in Bakery.\nBut there are several limitations:\n\nTo share a baked scene unwrapped with xatlas, Editor/x64/Bakery/scripts/xatlas folder must be included.\n\nxatlas is native library, so currently any PC opening a baked scene in Unity editor must be on x64 Windows.\n", "Use xatlas", "Cancel"))
                        {
                            unwrapper = ftGlobalStorage.Unwrapper.Default;
                        }
                    }
                }
            }
        }

        if (settingsMode >= SettingsMode.Advanced)
        {
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            denoiserType = (ftGlobalStorage.DenoiserType)EditorGUILayout.EnumPopup(denoiserType, opts);
        }

        GUI.EndGroup();

        GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "Render mode", headerStyle);
        y += 40;

        //bool prevVal = bakeWithNormalMaps;
        //bakeWithNormalMaps = GUI.Toggle(new Rect(2, 40, 200, 20), bakeWithNormalMaps, new GUIContent("Bake with normal maps", "Bake normal map effect into lightmaps"));
        //y += 20;

        GUI.EndGroup();

        GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "Directional mode", headerStyle);
        y += 40;

        GUI.EndGroup();

        if (settingsMode >= SettingsMode.Advanced)
        {
#if UNITY_2019_3_OR_NEWER
#else
            y -= 4;
#endif
            GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "Light probe mode", headerStyle);
            y += 40;
            GUI.EndGroup();
        }

        if (settingsMode == SettingsMode.Experimental)
        {
#if UNITY_2019_3_OR_NEWER
#else
            y -= 3;
#endif
            GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "Atlas packer", headerStyle);
            y += 40;
            GUI.EndGroup();
        }

        if (settingsMode >= SettingsMode.Advanced)
        {
#if UNITY_2019_3_OR_NEWER
#else
            if (settingsMode == SettingsMode.Advanced) y -= 3;
#endif
            GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "Asset UV processing", headerStyle);
            y += 40;
            GUI.EndGroup();
        }

        if (settingsMode == SettingsMode.Experimental && ftBuildGraphics.unwrapUVs)
        {
#if UNITY_2019_3_OR_NEWER
#else
            y -= 3;
#endif
            GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "Unwrapper", headerStyle);
            y += 40;
            GUI.EndGroup();
        }

        if (settingsMode >= SettingsMode.Advanced)
        {
#if UNITY_2019_3_OR_NEWER
#else
            y -= 3;
#endif
            GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "Denoiser", headerStyle);
            y += 40;
#if UNITY_2019_3_OR_NEWER
            y += 3;
#endif
            GUI.EndGroup();
        }

#if UNITY_2017_1_OR_NEWER
        if (userRenderMode == RenderMode.Shadowmask)
        {
            GUI.BeginGroup(new Rect(10, 10+y, 300, 120), "", headerStyle);
            var prevVal = isDistanceShadowmask;
            isDistanceShadowmask = GUI.Toggle(new Rect(2, 0, 200, 20), isDistanceShadowmask, new GUIContent("Distance shadowmask", "Use complete real-time shadows close to camera."));
            if (isDistanceShadowmask != prevVal)
            {
                QualitySettings.shadowmaskMode = isDistanceShadowmask ? ShadowmaskMode.DistanceShadowmask : ShadowmaskMode.Shadowmask;
            }
            y += 25;
            GUI.EndGroup();
        }
#endif

        if (renderDirMode == RenderDirMode.RNM || renderDirMode == RenderDirMode.SH || renderDirMode == RenderDirMode.MonoSH)
        {
            showDirWarning = EditorGUI.Foldout(new Rect(10,y+10,220,20), showDirWarning, "Directional mode info", foldoutStyle);
            if (showDirWarning)
            {
                var str = renderDirMode + " maps require special shader";
                EditorGUI.HelpBox(new Rect(15,y+30,220,40), str, MessageType.Info);
                y += 45;
            }
            y += 20;
        }

        if (settingsMode < SettingsMode.Advanced)
        {
            this.minSize = new Vector2(250, 310+20-40 + y + 45 + 40 + 20 + (showTasks2 ? 40+50 : 0) +
                (userRenderMode == RenderMode.AmbientOcclusionOnly ? (showAOSettings ? 20 : -40) : 0));
        }

        y += 10;
        if (settingsMode >= SettingsMode.Advanced)
        {
            showTasks = EditorGUI.Foldout(new Rect(10, y, 300, 20), showTasks, "Lightmapping tasks", foldoutStyle);
            y += 20;

            if (showTasks)
            {
                int xx = 20;
                int yy = y;// - 20;
                //GUI.BeginGroup(new Rect(10, y, 300, 160+20), "Lightmapping tasks", headerStyle);
                if (settingsMode == SettingsMode.Experimental)
                {
                    forceRebuildGeometry = GUI.Toggle(new Rect(xx, yy, 200, 20), forceRebuildGeometry, new GUIContent("Export geometry and maps", "Exports geometry, textures and lightmap properties to Bakery format. This is required, but if you already rendered the scene, and if no changes to meshes/maps/lightmap resolution took place, you may disable this checkbox to skip this step."));
                    yy += 20;
                }
                //ftBuildGraphics.unwrapUVs = GUI.Toggle(new Rect(xx, yy, 200, 20), ftBuildGraphics.unwrapUVs, new GUIContent("Adjust UV padding", "For meshes with 'Generate lightmap UVs' checkbox enabled, adjusts UVs further to have proper padding between UV islands for each mesh. Model-wide Pack Margin in importer settings is ignored."));
                //yy += 20;
                y -= 20;

                adjustSamples = GUI.Toggle(new Rect(xx, yy, 200, 20), adjustSamples, new GUIContent("Adjust sample positions", "Find the best sample positions to prevent lighting leaks."));
                yy += 20;
                unloadScenesInDeferredMode = GUI.Toggle(new Rect(xx, yy, 200, 20), unloadScenesInDeferredMode, new GUIContent("Unload scenes before render", "Unloads Unity scenes before baking to free up video memory."));
                yy += 20;
                if (settingsMode == SettingsMode.Experimental)
                {
                    forceRefresh = GUI.Toggle(new Rect(xx, yy, 200, 20), forceRefresh, new GUIContent("Update unmodified lights", "Update lights that didn't change since last rendering. You can disable this checkbox to skip these lights. Note that it only tracks changes to light objects. If scene geometry changed, then you still need to update all lights."));
                    yy += 20;
                    performRendering = GUI.Toggle(new Rect(xx, yy, 200, 20), performRendering, new GUIContent("Update modified lights and GI", "Update lights that did change since last rendering, plus GI."));
                    yy += 20;
                }
                denoise = GUI.Toggle(new Rect(xx, yy, 200, 20), denoise, new GUIContent("Denoise", "Apply denoising algorithm to lightmaps."));
                yy += 20;
                if (settingsMode == SettingsMode.Experimental && denoise)
                {
                    denoise2x = GUI.Toggle(new Rect(xx, yy, 200, 20), denoise2x, new GUIContent("Denoise: fix bright edges", "Sometimes the neural net used for denoising may produce bright edges around shadows, like if a sharpening effect was applied. If this option is enabled, Bakery will try to filter them away."));
                    yy += 20;
                    y += 20;
                }
                fixSeams = GUI.Toggle(new Rect(xx, yy, 200, 20), fixSeams, new GUIContent("Fix UV seams", "If enabled, will attempt to blend seams on lightmaps created by UV discontinuities. Useful for smooth geometry, including Unity's default sphere."));
                //GUI.EndGroup();
                y += (settingsMode == SettingsMode.Experimental ? (135 + 5) : (135 + 30) - 80);
                y += 20;
            }
        }

        GUI.BeginGroup(new Rect(10, y, 300, 380), "Auto-atlasing", headerStyle);

        int ay = 20;

        if (settingsMode >= SettingsMode.Advanced)
        {
            ftBuildGraphics.splitByTag = GUI.Toggle(new Rect(10, ay, 200, 20), ftBuildGraphics.splitByTag, new GUIContent("Split by baked tag", "Respect 'Baked Tag' in Lightmap Parameters assigned to each mesh renderer. Objects with different tags will always use separate atlases."));
            ay += 20;
            y += 20;
            ftBuildGraphics.splitByScene = GUI.Toggle(new Rect(10, ay, 200, 20), ftBuildGraphics.splitByScene, new GUIContent("Split by scene", "Bake separate lightmap atlases for every scene. Useful to limit the amount of textures loaded when scenes are streamed."));
            ay += 20;
            y += 20;
            if (settingsMode >= SettingsMode.Experimental)
            {
                if (ftBuildGraphics.atlasPacker == ftGlobalStorage.AtlasPacker.xatlas)
                {
                    ftBuildGraphics.postPacking = GUI.Toggle(new Rect(10, ay, 200, 20), ftBuildGraphics.postPacking, new GUIContent("Post-packing", "Try to minimize final atlas count by combining different LODs, terrains and regular meshes in one texture."));
                    ay += 20;
                    y += 20;
                }
            }

            if (settingsMode >= SettingsMode.Advanced)
            {
                if (ftBuildGraphics.atlasPacker == ftGlobalStorage.AtlasPacker.xatlas)
                {
                    ftBuildGraphics.holeFilling = GUI.Toggle(new Rect(10, ay, 200, 20), ftBuildGraphics.holeFilling, new GUIContent("Hole filling", "Fill holes while packing UV layouts to optimize atlas usage. If disabled, layouts are packed as bounding rectangles."));
                    ay += 20;
                    y += 20;
                }
            }

            if (settingsMode >= SettingsMode.Experimental)
            {
                if (ftBuildGraphics.unwrapUVs)
                {
                    ftBuildGraphics.uvPaddingMax = GUI.Toggle(new Rect(10, ay, 200, 20), ftBuildGraphics.uvPaddingMax, new GUIContent("UV padding: increase only", "When finding optimal UV padding for given resolution, the value will never get smaller comparing to previously baked scenes. This is useful when the same model is used across multiple scenes with different lightmap resolution."));
                    ay += 20;
                    y += 20;
                }
            }
        }

        GUI.Label(new Rect(10, ay, 100, 15), new GUIContent("Texels per unit:", "Approximate amount of lightmap texels per unit allocated for lightmapped objects (without Bakery LMGroup component). Affects the amount and resolution of generated lightmaps.\n\nExample values:\n- Large outdoor area (e.g. a city): 1-5\n- Medium outdoor area (e.g. a few alleys): 10-20\n- High quality interior: 100"));
        texelsPerUnit = EditorGUI.FloatField(new Rect(110, ay, 110, 15), texelsPerUnit, numberBoxStyle);
        ftBuildGraphics.texelsPerUnit = texelsPerUnit;
        ay += 20;

        GUI.Label(new Rect(10, ay, 100, 15), new GUIContent("Max resolution:"));
        ay += 20;
        GUI.Label(new Rect(10, ay, 100, 15), ""+ftBuildGraphics.maxAutoResolution);
        ftBuildGraphics.maxAutoResolution = 1 << (int)GUI.HorizontalSlider(new Rect(50, ay, 170, 15), Mathf.Ceil(Mathf.Log(ftBuildGraphics.maxAutoResolution)/Mathf.Log(2)), 8, 12);
        ay += 20;

        if (settingsMode >= SettingsMode.Advanced)
        {
            GUI.Label(new Rect(10, ay, 100, 15), new GUIContent("Min resolution:"));
            ay += 20;
            GUI.Label(new Rect(10, ay, 100, 15), ""+ftBuildGraphics.minAutoResolution);
            ftBuildGraphics.minAutoResolution = 1 << (int)GUI.HorizontalSlider(new Rect(50, ay, 170, 15), Mathf.Log(ftBuildGraphics.minAutoResolution)/Mathf.Log(2), 4, 12);
            y += 40;
            ay += 20;
        }

        if (settingsMode >= SettingsMode.Advanced)
        {
            ftBuildGraphics.texelsPerUnitPerMap = EditorGUI.Foldout(new Rect(0, ay, 230, 20), ftBuildGraphics.texelsPerUnitPerMap, "Scale per map type", foldoutStyle);
            ay += 20;
            if (ftBuildGraphics.texelsPerUnitPerMap)
            {
                GUI.Label(new Rect(10, ay, 150, 20), new GUIContent("Main lightmap scale:"));
                ay += 20;
                float actualDiv = 1 << (int)((1.0f - ftBuildGraphics.mainLightmapScale) * 6);
                GUI.Label(new Rect(10, ay, 85, 15), "1/"+ actualDiv);
                ftBuildGraphics.mainLightmapScale = GUI.HorizontalSlider(new Rect(50, ay, 170, 15), ftBuildGraphics.mainLightmapScale, 0, 1);
                ay += 20;

                GUI.Label(new Rect(10, ay, 150, 20), new GUIContent("Shadowmask scale:"));
                ay += 20;
                actualDiv = 1 << (int)((1.0f - ftBuildGraphics.maskLightmapScale) * 6);
                GUI.Label(new Rect(10, ay, 85, 15), "1/"+ actualDiv);
                ftBuildGraphics.maskLightmapScale = GUI.HorizontalSlider(new Rect(50, ay, 170, 15), ftBuildGraphics.maskLightmapScale, 0, 1);
                ay += 20;

                GUI.Label(new Rect(10, ay, 150, 20), new GUIContent("Direction scale:"));
                ay += 20;
                actualDiv = 1 << (int)((1.0f - ftBuildGraphics.dirLightmapScale) * 6);
                GUI.Label(new Rect(10, ay, 85, 15), "1/"+ actualDiv);
                ftBuildGraphics.dirLightmapScale = GUI.HorizontalSlider(new Rect(50, ay, 170, 15), ftBuildGraphics.dirLightmapScale, 0, 1);
                ay += 20;

                y += 120;
            }
            y += 20;

            showCheckerSettings = EditorGUI.Foldout(new Rect(0, ay, 230, 20), showCheckerSettings, "Checker preview", foldoutStyle);
            ay += 20;
            if (showCheckerSettings)
            {
                var prevValue = ftSceneView.enabled;
                showChecker = GUI.Toggle(new Rect(10, ay, 230, 20), ftSceneView.enabled, new GUIContent("Show checker", "Renders a checkerboard pattern on top of visible objects to demonstrate lightmap texel size in the Scene view. Useful for making sure that you are using adequate values for 'Texels per unit' and other resolution-affecting settings before you bake.\n\nNote: Does not currently show correct texel sizes for Terrains."));
                if (showChecker != prevValue)
                {
                    ftSceneView.ToggleChecker();
                    if (ftAtlasPreview.instance != null) ftAtlasPreview.instance.OnGUI();
                }
                ay += 20;
                y += 20;
                if (showChecker)
                {
                    if (GUI.Button(new Rect(10, ay, 220/2, 20), "Refresh checker"))
                    {
                        ftSceneView.RefreshChecker();
                        if (ftAtlasPreview.instance != null)
                        {
                            ftAtlasPreview.instance.update = true;
                            ftAtlasPreview.instance.OnGUI();
                            ftAtlasPreview.instance.Repaint();
                        }
                    }
                    //ay += 20;
                    //y += 20;
                    if (GUI.Button(new Rect(10+220/2, ay, 220/2, 20), "Atlas preview"))
                    {
                        if (ftAtlasPreview.instance == null)
                        {
                            GetWindow<ftAtlasPreview>();
                        }
                        else
                        {
                            ftAtlasPreview.instance.Close();
                        }
                    }
                    ay += 20;
                    y += 20;
                }
            }
            y += 20;
        }

        GUI.EndGroup();
        y += 45 + 40;

        if (userRenderMode != RenderMode.AmbientOcclusionOnly)
        {
            y += 5;
            GUI.BeginGroup(new Rect(10, y, 300, 300), "Global Illumination", headerStyle);

            GUI.Label(new Rect(10, 20, 70, 15), new GUIContent("Bounces:", "How many times light ray bounces off surfaces. Lower values are faster to render, while higher values ensure light reaches highly occluded places like interiors, caves, etc."));
            var textBounces = GUI.TextField(new Rect(70, 20, 25, 15), "" + bounces, textBoxStyle);
            textBounces = Regex.Replace(textBounces, "[^0-9]", "");
            System.Int32.TryParse(textBounces, out bounces);
            bounces = (int)GUI.HorizontalSlider(new Rect(100, 20, 120, 15), bounces, 0, 5);

            GUI.Label(new Rect(10, 20+20, 70, 15), new GUIContent("Samples:", "Quality of GI. More samples produce cleaner lighting with less noise."));
            var textGISamples = GUI.TextField(new Rect(70, 20+20, 25, 15), "" + giSamples, textBoxStyle);
            textGISamples = Regex.Replace(textGISamples, "[^0-9]", "");
            System.Int32.TryParse(textGISamples, out giSamples);
            giSamples = (int)GUI.HorizontalSlider(new Rect(100, 20+20, 120, 15), giSamples, 1, 64);
        }
        else
        {
            GUI.BeginGroup(new Rect(10, y-60, 300, 300), "", headerStyle);
        }

        GUI.EndGroup();
        if (userRenderMode != RenderMode.AmbientOcclusionOnly) y += 60;

        if (settingsMode == SettingsMode.Simple && userRenderMode == RenderMode.AmbientOcclusionOnly)
        {
            showAOSettings = true;
            showAOSettings = EditorGUI.Foldout(new Rect(10, y, 300, 20), showAOSettings, "Ambient occlusion");
            if (showAOSettings)
            {
                int xx = 15;
                int yy = y + 10;
                int ww = 110;

                GUI.Label(new Rect(10+xx, 15+yy, 100, 15), new GUIContent("Intensity:", "AO visibility. Disabled if set to 0."));
                hackAOIntensity = EditorGUI.FloatField(new Rect(95+xx, 15+yy, ww, 15), hackAOIntensity, numberBoxStyle);

                GUI.Label(new Rect(10+xx, 30+yy, 100, 15), new GUIContent("Radius:", "AO radius."));
                hackAORadius = EditorGUI.FloatField(new Rect(95+xx, 30+yy, ww, 15), hackAORadius, numberBoxStyle);

                GUI.Label(new Rect(10+xx, 45+yy, 100, 15), new GUIContent("Samples:", "Affects the quality of AO."));
                hackAOSamples = EditorGUI.IntField(new Rect(95+xx, 45+yy, ww, 15), hackAOSamples, numberBoxStyle);

                y += 60;
            }
            y += 20;
        }
        else if (settingsMode >= SettingsMode.Advanced)
        {
            //showHacks = EditorGUI.Foldout(new Rect(10, y, 300, 300), showHacks, "Hacks");
            //y += 20;
            //if (showHacks)
            {
                GUI.BeginGroup(new Rect(10, y, 300, 300), "Hacks", headerStyle);

                int yy = 20;
                GUI.Label(new Rect(10, yy, 100, 15), new GUIContent("Emissive boost:", "Multiplies light from emissive surfaces."));
                hackEmissiveBoost = EditorGUI.FloatField(new Rect(110, yy, 110, 15), hackEmissiveBoost, numberBoxStyle);
                yy += 20;

                GUI.Label(new Rect(10, yy, 100, 15), new GUIContent("Indirect boost:", "Multiplies indirect intensity for all lights."));
                hackIndirectBoost = EditorGUI.FloatField(new Rect(110, yy, 110, 15), hackIndirectBoost, numberBoxStyle);
                yy += 20;

                GUI.Label(new Rect(10, yy, 120, 20), new GUIContent("Backface GI:", "How much light is emitted via back faces from 0 (black) to 1 (equals to front face)."));
                giBackFaceWeight = EditorGUI.FloatField(new Rect(110, yy, 110, 15), giBackFaceWeight, numberBoxStyle);
                yy += 20;

                showAOSettings = EditorGUI.Foldout(new Rect(10, yy, 300, 20), showAOSettings, "Ambient occlusion");
                yy += 20;
                y += 15+40;
                if (showAOSettings)
                {
                    int xx = 15;
                    yy = 45+40;
                    int ww = 110;

                    GUI.Label(new Rect(10+xx, 15+yy, 100, 15), new GUIContent("Intensity:", "AO visibility. Disabled if set to 0."));
                    hackAOIntensity = EditorGUI.FloatField(new Rect(95+xx, 15+yy, ww, 15), hackAOIntensity, numberBoxStyle);

                    GUI.Label(new Rect(10+xx, 30+yy, 100, 15), new GUIContent("Radius:", "AO radius."));
                    hackAORadius = EditorGUI.FloatField(new Rect(95+xx, 30+yy, ww, 15), hackAORadius, numberBoxStyle);

                    GUI.Label(new Rect(10+xx, 45+yy, 100, 15), new GUIContent("Samples:", "Affects the quality of AO."));
                    hackAOSamples = EditorGUI.IntField(new Rect(95+xx, 45+yy, ww, 15), hackAOSamples, numberBoxStyle);

                    y += 50;
                }

                GUI.EndGroup();
                y += 50;
            }

            showPerf = EditorGUI.Foldout(new Rect(10, y, 300, 20), showPerf, "Performance", foldoutStyle);
            y += 20;
            if (showPerf)
            {
                int xx = 10;

                var prev = rtxMode;
                rtxMode =
                    GUI.Toggle(new Rect(xx, y, 200, 20), rtxMode,
                        new GUIContent(" RTX mode", "Enables RTX hardware acceleration. Requires supported hardware.\n\nNote:\n- Minimum supported driver version is 418.\n- Drivers can emulate RTX mode on most non-RTX cards, but the result will be slower.\n- RTX mode must be enabled on Ampere (3xxx) cards."));
                if (prev != rtxMode)
                {
                    ftraceExe = rtxMode ? ftraceExe6 : ftraceExe1;
                    if (rtxMode) ftBuildGraphics.exportTerrainAsHeightmap = false;
                }
                y += 20;

                ftBuildGraphics.exportTerrainTrees =
                    GUI.Toggle(new Rect(xx, y, 200, 20), ftBuildGraphics.exportTerrainTrees,
                        new GUIContent(" Export terrain trees", "If enabled, painted terrain trees will affect lighting. Trees themselves will not be baked.\n\nNote that the highest possible LOD level is used for every tree during baking. It is not recommended to use this option for rendering multi-kilometer forests with highly detailed models."));
                y += 20;

                prev = ftBuildGraphics.exportTerrainAsHeightmap;
                //if (settingsMode >= SettingsMode.Experimental)
                //{
                    ftBuildGraphics.exportTerrainAsHeightmap =
                        GUI.Toggle(new Rect(xx, y, 200, 20), ftBuildGraphics.exportTerrainAsHeightmap,
                            new GUIContent(" Terrain optimization", "If enabled, terrains use a separate ray tracing technique to take advantage of their heightfield geometry. If disabled, they are treated like any other mesh.\n\nNote: This is currently incompatible with painted terrain holes. Disable it to make them work."));
                    if (prev != ftBuildGraphics.exportTerrainAsHeightmap)
                    {
                        if (ftBuildGraphics.exportTerrainAsHeightmap)
                        {
                            rtxMode = false;
                            ftraceExe = ftraceExe1;
                        }
                    }
                    y += 20;
                //}

                if (settingsMode >= SettingsMode.Experimental)
                {
#if UNITY_2020_1_OR_NEWER
                    compressVolumes =
                        GUI.Toggle(new Rect(xx, y, 200, 20), compressVolumes,
                            new GUIContent(" Compress volumes", "Apply texture compression to volume 3D textures and switch Bakery shaders to a corresponding sampling mode. Not recommended for very low resolution volumes. Volume size may be increased to be a multiple of 4."));
#else
                    GUI.enabled = false;
                    compressVolumes =
                        GUI.Toggle(new Rect(xx, y, 200, 20), compressVolumes,
                            new GUIContent(" Compress volumes", "(Requires Unity 2020.1 or newer) Apply texture compression to volume 3D textures and switch Bakery shaders to a corresponding sampling mode. Not recommended for very low resolution volumes. Volume size may be increased to be a multiple of 4."));
                    GUI.enabled = true;
#endif
                    y += 20;
                }

                GUI.Label(new Rect(10, y, 150, 20), new GUIContent("Samples multiplier", "Multiplies all shadow and GI samples by the specified factor. Use this to quickly change between draft and final quality."));
                y += 20;
                GUI.Label(new Rect(10, y, 85, 15), "1/"+ sampleDivisor);
                const int maxSampleDivisor = 8;
                sampleDivisor = (int)GUI.HorizontalSlider(new Rect(50, y, 170, 15), (float)(maxSampleDivisor - (sampleDivisor-1)), 1, maxSampleDivisor);
                sampleDivisor = maxSampleDivisor - (sampleDivisor-1);
                y += 20;

                /*GUI.BeginGroup(new Rect(xx, y, 300, 120), "GI VRAM optimization", headerStyle);
                y += 20;
                GUI.EndGroup();
                giLodMode = (GILODMode)EditorGUI.EnumPopup(new Rect(xx, y, 225, 25), giLodMode);
                y += 20;*/

                GUI.BeginGroup(new Rect(xx, y, 300, 300), "Tile size", headerStyle);
                GUI.Label(new Rect(10, 20, 70, 15), new GUIContent("" + tileSize, "Lightmaps are split into smaller tiles and each tile is processed by the GPU without interruputions. Changing the tile size therefore balances between system responsiveness and baking speed. Because the GPU is shared by all running processes, baking with a big tile size can make everything slow, but also gets the job done faster."));
                tileSize = 1 << (int)GUI.HorizontalSlider(new Rect(50, 20, 170, 15), Mathf.Log(tileSize)/Mathf.Log(2), 5, 12);
                GUI.EndGroup();
                y += 45;
            }
        }


        if (settingsMode >= SettingsMode.Advanced)
        {

        }
        else
        {
            GUI.BeginGroup(new Rect(10, y, 300, 300), "GPU priority", headerStyle);
            string priorityName = "";
            if (tileSize > 512)
            {
                if ((int)priority!=3) priority = 3; // >= 1024 very high
                priorityName = "Very high";
            }
            else if (tileSize > 256)
            {
                if ((int)priority!=2) priority = 2; // >= 512 high
                priorityName = "High";
            }
            else if (tileSize > 64)
            {
                if ((int)priority!=1) priority = 1; // >= 128 low
                priorityName = "Low";
            }
            else
            {
                if ((int)priority!=0) priority = 0; // == 32 very low
                priorityName = "Very low";
            }
            GUI.Label(new Rect(10, 20, 75, 20), new GUIContent("" + priorityName, "Balance between system responsiveness and baking speed. Because the GPU is shared by all running processes, baking on high priority can make everything slow, but also gets the job done faster."));
            priority = GUI.HorizontalSlider(new Rect(80, 20, 140, 15), priority, 0, 3);
            if ((int)priority == 0)
            {
                tileSize = 32;
            }
            else if ((int)priority == 1)
            {
                tileSize = 128;
            }
            else if ((int)priority == 2)
            {
                tileSize = 512;
            }
            else
            {
                tileSize = 1024;
            }
            GUI.EndGroup();
            y += 50;
        }

        if (scenePath == "") scenePath = System.Environment.GetEnvironmentVariable("TEMP", System.EnvironmentVariableTarget.Process) + "\\frender";
        if (settingsMode >= SettingsMode.Advanced)
        {
            showPaths = EditorGUI.Foldout(new Rect(10, y, 230, 20), showPaths, "Output options", foldoutStyle);
            y += 20;

            if (showPaths)
            {
                if (GUI.Button(new Rect(10, y, 230, 40), new GUIContent("Temp path:\n" + scenePath, "Specify a folder where temporary data will be stored. Using a SSD can speed up rendering a bit comparing to HDD.")))
                {
                    scenePath = EditorUtility.OpenFolderPanel("Select temp folder", scenePath, "frender");
                }
                y += 50;

                useScenePath = EditorGUI.ToggleLeft( new Rect( 10, y, 230, 20 ), new GUIContent( "Use scene named output path", "Create the lightmaps in a subfolder named the same as the scene" ), useScenePath );
                y += 25;
                if ( !useScenePath ) {
                    GUI.Label(new Rect(10, y, 100, 16), new GUIContent("Output path:", "Specify a folder where lightmaps data will be stored (relative to Assets)."));
                    outputPath = EditorGUI.TextField(new Rect(85, y, 155, 18), outputPath, textBoxStyle);
                    y += 25;
                } else {
                    // AMW - don't override the outputPath if we currently have the temp scene open.
                    // this seemed to happen during lightprobe bakes and the lightprobes would end up in the _tempScene path
                    string currentScenePath = EditorSceneManager.GetActiveScene().path;
                    if ( currentScenePath.ToLower().Contains( "_tempscene.unity" ) == false ) {
                        outputPath = currentScenePath;
                        if ( string.IsNullOrEmpty( outputPath ) ) {
                            outputPath = "BakeryLightmaps";
                        } else {
                            // strip "Assets/" and the file extension
                            if (outputPath.Length > 7 && outputPath.Substring(0,7).ToLower() == "assets/") outputPath = outputPath.Substring(7);
                            if (outputPath.Length > 6 && outputPath.Substring(outputPath.Length-6).ToLower() == ".unity")
                                                                                        outputPath = outputPath.Substring(0, outputPath.Length-6);
                        }
                    }
                }
            }
        }

        if (settingsMode >= SettingsMode.Experimental)
        {
            showNet = EditorGUI.Foldout(new Rect(10, y, 230, 20), showNet, "Network baking", foldoutStyle);
            y += 20;

            if (showNet)
            {
                clientMode = EditorGUI.ToggleLeft( new Rect( 10, y, 230, 20 ), new GUIContent( "Bake on remote server", "Enable network baking" ), clientMode );
                y += 20;
                if (clientMode)
                {
                    GUI.Label(new Rect(10, y, 100, 16), new GUIContent("IP address:", "Server address where ftServer.exe is launched."));
                    ftClient.serverAddress = EditorGUI.TextField(new Rect(85, y, 155, 18), ftClient.serverAddress, textBoxStyle);
                    y += 20;

                    if (ftClient.lastServerMsgIsError) ftClient.Disconnect();

                    if (!ftClient.connectedToServer)
                    {
                        if (GUI.Button(new Rect(10, y, 230, 30), "Connect to server"))
                        {
                            ftClient.ConnectToServer();
                        }
                    }
                    else
                    {
                        ftClient.Update();
                        if (GUI.Button(new Rect(10, y, ftClient.serverGetDataMode ? 230 : (230/2), 30), "Disconnect"))
                        {
                            ftClient.Disconnect();
                            ftClient.lastServerMsg = "Server: no data";
                            ftClient.lastServerMsgIsError = false;
                            ftClient.lastServerErrorCode = 0;
                        }
                        if (!ftClient.serverGetDataMode)
                        {
                            if (ftClient.serverMustRefreshData)
                            {
                                CollectStorages();
                                var groupList = new List<BakeryLightmapGroup>();
                                var groupListGIContributing = new List<BakeryLightmapGroup>();
                                CollectGroups(groupList, groupListGIContributing, false);
                                ftClient.serverMustRefreshData = false;
                                var apply = ApplyBakedData();
                                while(apply.MoveNext()) {}
                            }
                            if (GUI.Button(new Rect(230/2+10, y, 230/2, 30), "Get data"))
                            {
                                if (ftClient.lastServerScene.Length == 0)
                                {
                                    DebugLogError("No baked scene was found on the server.");
                                }
                                else if (ftClient.lastServerScene != EditorSceneManager.GetActiveScene().name)
                                {
                                    DebugLogError("Current active scene doesn't match the one on the server.");
                                }
                                else if (ftClient.serverGetDataMode)
                                {
                                    DebugLogInfo("Data is being downloaded");
                                }
                                else
                                {
                                    if (!ServerGetData())
                                    {
                                        DebugLogError("Failed to find the list of files to download.");
                                    }
                                }
                            }
                        }
                    }

                    y += 30;

                    var msg = ftClient.lastServerMsg;
                    if (ftClient.lastServerScene.Length > 0) msg += "\nScene: "+ftClient.lastServerScene;
                    if (ftClient.serverGetDataMode) msg += "\nDownloading: " + System.Math.Min(ftClient.serverGetFileIterator+1, ftClient.serverGetFileList.Count) + "/" + ftClient.serverGetFileList.Count;
                    EditorGUI.HelpBox(new Rect(15,y+5,220,40), msg, ftClient.lastServerMsgIsError ? MessageType.Error : MessageType.Info);
                    y += 40;
                }
                y += 10;
            }
        }

        ftBuildGraphics.scenePath = scenePath;
        scenePathQuoted = "\"" + scenePath + "\"";

        /*if (settingsMode >= SettingsMode.Advanced)
        {
            showCompression = EditorGUI.Foldout(new Rect(10, y, 230, 20), showCompression, "Compression", foldoutStyle);
            y += 20;
            if (showCompression)
            {
                int xx = 10;
                float prevWidth = EditorGUIUtility.labelWidth;
                EditorGUIUtility.labelWidth = 45f;
                lightmapCompressionColor = (TextureImporterFormat)EditorGUI.EnumPopup( new Rect( xx, y, 240-xx, 20 ), new GUIContent( "Color:", "Set the default compression for the lightmap textures" ), lightmapCompressionColor );
                y += 25;
                //EditorGUIUtility.labelWidth = 85f;
                lightmapCompressionMask = (TextureImporterFormat)EditorGUI.EnumPopup( new Rect( xx, y, 240-xx, 20 ), new GUIContent( "Mask:", "Set the default compression for the lightmap textures" ), lightmapCompressionMask );
                y += 25;
                //EditorGUIUtility.labelWidth = 65f;
                lightmapCompressionDir = (TextureImporterFormat)EditorGUI.EnumPopup( new Rect( xx, y, 240-xx, 20 ), new GUIContent( "Dir:", "Set the default compression for the lightmap textures" ), lightmapCompressionDir );
                EditorGUIUtility.labelWidth = prevWidth;
                y += 25;
            }
        }*/

        /*if (settingsMode == SettingsMode.Experimental)
        {
            GUI.BeginGroup(new Rect(10, y, 300, 300), "Output texture type", headerStyle);
            encodeMode = GUI.SelectionGrid(new Rect(10, 20, 210, 20), encodeMode,  selStrings, 2);
            GUI.EndGroup();
            y += 50;
        }*/
        ftBuildGraphics.overwriteExtensionCheck = ".hdr";//bc6h ? ".asset" : ".hdr";

        if (settingsMode >= SettingsMode.Advanced)
        {
            curSector = EditorGUI.ObjectField(new Rect(10, y, 230, 16), curSector, typeof(BakerySector), true) as BakerySector;
            y += 25;
        }


        if (GUI.Button(new Rect(10, y, 230, 30), "Render"))
        {
            RenderButton(!suppressPopups);
        }
        y += 35;

        if (settingsMode >= SettingsMode.Experimental)
        {
            if (GUI.Button(new Rect(10, y, 230, 30), "Render Selected Groups"))
            {
                if (!Application.isPlaying)
                {
                    ValidateOutputPath();
                    if (!TestSystemSpecs()) return;
                    selectedOnly = true;
                    probesOnlyL1 = false;
                    fullSectorRender = false;
                    hasAnyVolumes = true; // possibly - ftBuildGraphics will figure it out
                    hasAnyShadowmasks = false;
                    progressFunc = RenderLightmapFunc();
                    EditorApplication.update += RenderLightmapUpdate;
                    bakeInProgress = true;
                }
            }
            y += 35;
        }

        if (GUI.Button(new Rect(10, y, 230, 30), "Render Light Probes"))
        {
            RenderLightProbesButton();
        }
        y += 35;

        if (GUI.Button(new Rect(10, y, 230, 30), "Render Reflection Probes"))
        {
            RenderReflectionProbesButton();
        }
        y += 35;

        if (GUI.Button(new Rect(10, y, 230, 30), "Update Skybox Probe"))
        {
            if (!Application.isPlaying)
            {
                ValidateOutputPath();
                DynamicGI.UpdateEnvironment();

                var rgo = new GameObject();
                var r = rgo.AddComponent<ReflectionProbe>();
                r.resolution = 256;
                r.clearFlags = UnityEngine.Rendering.ReflectionProbeClearFlags.Skybox;
                r.cullingMask = 0;
                r.mode = UnityEngine.Rendering.ReflectionProbeMode.Custom;

                var assetName = GenerateLightingDataAssetName();
                var outName = "Assets/" + outputPath + "/" + assetName + "_sky.exr";
                if (File.Exists(outName)) ValidateFileAttribs(outName);
                Lightmapping.BakeReflectionProbe(r, outName);

                AssetDatabase.Refresh();
                RenderSettings.customReflection = AssetDatabase.LoadAssetAtPath(outName, typeof(Cubemap)) as Cubemap;
                RenderSettings.defaultReflectionMode = UnityEngine.Rendering.DefaultReflectionMode.Custom;
                DestroyImmediate(rgo);
            }
        }
        y += 30;

        if (settingsMode >= SettingsMode.Experimental)
        {
            //showTasks2 = EditorGUI.Foldout(new Rect(10, y-5, 300, 20), showTasks2, "Light probe tasks", foldoutStyle);
            //y += 20 - (showTasks2 ? 10 : 5);
            //if (showTasks2)
            {
                var prevValue = usesRealtimeGI;
                usesRealtimeGI = GUI.Toggle(new Rect(10, y+5, 230, 20), usesRealtimeGI, new GUIContent("Combine with Enlighten real-time GI", "When the 'Render' button is pressed, Enlighten real-time GI will be calculated first. Bakery will bake regular lightmaps afterwards. Both static and real-time GI will be combined."));
                if (prevValue != usesRealtimeGI)
                {
                    //Lightmapping.realtimeGI = usesRealtimeGI;
                }
                y += 20;
            }
        }

        //if (settingsMode >= SettingsMode.Advanced)
        {
            useUnityForOcclsusionProbes = GUI.Toggle(new Rect(10, y+5, 230, 20), useUnityForOcclsusionProbes, new GUIContent("Occlusion probes", "When the 'Render Light Probes' button is pressed, lets Unity bake occlusion probes using its own (currently selected) built-in lightmapper. Occlusion probes prevent dynamic objects from getting lit in shadowed areas. There is currently no way to use custom occlusion probes in Unity, so it has to call its own lightmappers to do the job."));
            y += 25;
        }

        if (settingsMode >= SettingsMode.Advanced)
        {
            beepOnFinish = GUI.Toggle(new Rect(10, y, 230, 20), beepOnFinish, new GUIContent("Beep on finish", "Play a sound when the bake has finished."));
            y += 25;
        }

        showTasks2 = EditorGUI.Foldout(new Rect(10, y, 300, 20), showTasks2, "Warnings", foldoutStyle);
        y += 12+2;
        if (showTasks2)
        {
            suppressPopups = GUI.Toggle(new Rect(10, y, 200, 20), suppressPopups, new GUIContent("Suppress all popups", "Don't show any dialog boxes after pressing Render."));
            if (suppressPopups) GUI.enabled = false;
            y += 15;
            checkOverlaps = GUI.Toggle(new Rect(10, y, 200, 20), checkOverlaps, new GUIContent("UV validation", "Checks for any incorrect, missing or overlapping UVs."));
            y += 15;
            ftBuildGraphics.memoryWarning = GUI.Toggle(new Rect(10, y, 200, 20), ftBuildGraphics.memoryWarning, new GUIContent("Video memory check", "Calculates the approximate amount of required video memory (VRAM) and asks to continue."));
            y += 15;
            ftBuildGraphics.overwriteWarning = GUI.Toggle(new Rect(10, y, 200, 20), ftBuildGraphics.overwriteWarning, new GUIContent("Overwrite check", "Checks and asks if any existing lightmaps are going to be overwritten."));
            y += 15;
            samplesWarning = GUI.Toggle(new Rect(10, y, 200, 20), samplesWarning, new GUIContent("Sample count check", "Checks if the sample values for lights/GI/AO are within a reasonable range."));
            y += 15;
            prefabWarning = GUI.Toggle(new Rect(10, y, 200, 20), prefabWarning, new GUIContent("Lightmapped prefab validation", "Checks if any prefabs are going to be overwritten and if there is anything preventing from baking them."));
            if (suppressPopups) GUI.enabled = true;
        }

        if (settingsMode >= SettingsMode.Advanced || simpleWindowIsTooSmall)
        {
            GUI.EndScrollView();
        }

        if (ftLightmaps.mustReloadRenderSettings)
        {
            ftLightmaps.mustReloadRenderSettings = false;
            OnEnable();
            if (showChecker)
            {
                ftSceneView.ToggleChecker();
            }
        }

        SaveRenderSettings();
    }

    public void SaveRenderSettings()
    {
        var scenePathToSave = scenePath;
        if (scenePathToSave == System.Environment.GetEnvironmentVariable("TEMP", System.EnvironmentVariableTarget.Process) + "\\frender")
        {
            scenePathToSave = "";
        }

        if (renderSettingsStorage == null) return;

        FindGlobalStorage();
        if (gstorage != null)
        {
            if (gstorage.renderSettingsTempPath != scenePathToSave)
            {
                gstorage.renderSettingsTempPath = scenePathToSave;
                EditorUtility.SetDirty(gstorage);
            }
        }

        if (
            renderSettingsStorage.renderSettingsBounces != bounces ||
            renderSettingsStorage.renderSettingsGISamples != giSamples ||
            renderSettingsStorage.renderSettingsGIBackFaceWeight != giBackFaceWeight ||
            renderSettingsStorage.renderSettingsTileSize != tileSize ||
            renderSettingsStorage.renderSettingsPriority != priority ||
            renderSettingsStorage.renderSettingsTexelsPerUnit != texelsPerUnit ||
            renderSettingsStorage.renderSettingsForceRefresh != forceRefresh ||
            renderSettingsStorage.renderSettingsForceRebuildGeometry != forceRebuildGeometry ||
            renderSettingsStorage.renderSettingsPerformRendering != performRendering ||
            renderSettingsStorage.renderSettingsUserRenderMode != (int)userRenderMode ||
            renderSettingsStorage.renderSettingsSettingsMode != (int)settingsMode ||
            renderSettingsStorage.renderSettingsFixSeams != fixSeams ||
            renderSettingsStorage.renderSettingsDenoise != denoise ||
            renderSettingsStorage.renderSettingsDenoise2x != denoise2x ||
            renderSettingsStorage.renderSettingsEncode != encode ||
            renderSettingsStorage.renderSettingsEncodeMode != encodeMode ||
            renderSettingsStorage.renderSettingsOverwriteWarning != ftBuildGraphics.overwriteWarning ||
            renderSettingsStorage.renderSettingsAutoAtlas != ftBuildGraphics.autoAtlas ||
            renderSettingsStorage.renderSettingsUnwrapUVs != ftBuildGraphics.unwrapUVs ||
            renderSettingsStorage.renderSettingsForceDisableUnwrapUVs != ftBuildGraphics.forceDisableUnwrapUVs ||
            renderSettingsStorage.renderSettingsMaxAutoResolution != ftBuildGraphics.maxAutoResolution ||
            renderSettingsStorage.renderSettingsMinAutoResolution != ftBuildGraphics.minAutoResolution ||
            renderSettingsStorage.renderSettingsUnloadScenes != unloadScenesInDeferredMode ||
            renderSettingsStorage.renderSettingsAdjustSamples != adjustSamples ||
            renderSettingsStorage.renderSettingsGILODMode != (int)giLodMode ||
            renderSettingsStorage.renderSettingsGILODModeEnabled != giLodModeEnabled ||
            renderSettingsStorage.renderSettingsCheckOverlaps != checkOverlaps ||
            renderSettingsStorage.renderSettingsOutPath != outputPath ||
            renderSettingsStorage.renderSettingsUseScenePath != useScenePath ||
            //renderSettingsStorage.renderSettingsTempPath != scenePathToSave ||
            renderSettingsStorage.renderSettingsHackEmissiveBoost != hackEmissiveBoost ||
            renderSettingsStorage.renderSettingsHackIndirectBoost != hackIndirectBoost ||
            renderSettingsStorage.renderSettingsHackAOIntensity != hackAOIntensity ||
            renderSettingsStorage.renderSettingsHackAORadius != hackAORadius ||
            renderSettingsStorage.renderSettingsHackAOSamples != hackAOSamples ||
            renderSettingsStorage.renderSettingsShowAOSettings != showAOSettings ||
            renderSettingsStorage.renderSettingsShowTasks != showTasks ||
            renderSettingsStorage.renderSettingsShowTasks2 != showTasks2 ||
            renderSettingsStorage.renderSettingsShowPaths != showPaths ||
            renderSettingsStorage.renderSettingsShowNet != showNet ||
            renderSettingsStorage.renderSettingsShowPerf != showPerf ||
            //renderSettingsStorage.renderSettingsShowCompression != showCompression ||
            renderSettingsStorage.renderSettingsTexelsPerMap != ftBuildGraphics.texelsPerUnitPerMap ||
            renderSettingsStorage.renderSettingsTexelsColor != ftBuildGraphics.mainLightmapScale ||
            renderSettingsStorage.renderSettingsTexelsMask != ftBuildGraphics.maskLightmapScale ||
            renderSettingsStorage.renderSettingsTexelsDir != ftBuildGraphics.dirLightmapScale ||
            renderSettingsStorage.renderSettingsOcclusionProbes != useUnityForOcclsusionProbes ||
            renderSettingsStorage.renderSettingsBeepOnFinish != beepOnFinish ||
            renderSettingsStorage.renderSettingsDistanceShadowmask != isDistanceShadowmask ||
            renderSettingsStorage.renderSettingsShowDirWarning != showDirWarning ||
            renderSettingsStorage.renderSettingsRenderDirMode != (int)renderDirMode ||
            renderSettingsStorage.renderSettingsShowCheckerSettings != showCheckerSettings ||
            renderSettingsStorage.usesRealtimeGI != usesRealtimeGI ||
            renderSettingsStorage.renderSettingsSamplesWarning != samplesWarning ||
            renderSettingsStorage.renderSettingsSuppressPopups != suppressPopups ||
            renderSettingsStorage.renderSettingsPrefabWarning != prefabWarning ||
            renderSettingsStorage.renderSettingsSplitByScene != ftBuildGraphics.splitByScene ||
            renderSettingsStorage.renderSettingsSplitByTag != ftBuildGraphics.splitByTag ||
            renderSettingsStorage.renderSettingsExportTerrainAsHeightmap != ftBuildGraphics.exportTerrainAsHeightmap ||
            renderSettingsStorage.renderSettingsExportTerrainTrees != ftBuildGraphics.exportTerrainTrees ||
            renderSettingsStorage.renderSettingsRTXMode != rtxMode ||
            renderSettingsStorage.renderSettingsLightProbeMode != (int)lightProbeMode ||
            renderSettingsStorage.renderSettingsClientMode != clientMode ||
            renderSettingsStorage.renderSettingsServerAddress != ftClient.serverAddress ||
            renderSettingsStorage.renderSettingsUVPaddingMax != ftBuildGraphics.uvPaddingMax ||
            renderSettingsStorage.renderSettingsPostPacking != ftBuildGraphics.postPacking ||
            renderSettingsStorage.renderSettingsHoleFilling != ftBuildGraphics.holeFilling ||
            renderSettingsStorage.renderSettingsSampleDiv != sampleDivisor ||
            renderSettingsStorage.renderSettingsUnwrapper != (int)unwrapper ||
            renderSettingsStorage.renderSettingsDenoiserType != (int)denoiserType ||
            //renderSettingsStorage.renderSettingsLegacyDenoiser != legacyDenoiser ||
            renderSettingsStorage.renderSettingsAtlasPacker != ftBuildGraphics.atlasPacker ||
            renderSettingsStorage.renderSettingsCompressVolumes != compressVolumes ||
            renderSettingsStorage.renderSettingsSector != curSector
            )
        {
            Undo.RecordObject(renderSettingsStorage, "Change Bakery settings");
            renderSettingsStorage.renderSettingsBounces = bounces;
            renderSettingsStorage.renderSettingsGISamples = giSamples;
            renderSettingsStorage.renderSettingsGIBackFaceWeight = giBackFaceWeight;
            renderSettingsStorage.renderSettingsTileSize = tileSize;
            renderSettingsStorage.renderSettingsPriority = priority;
            renderSettingsStorage.renderSettingsTexelsPerUnit = texelsPerUnit;
            renderSettingsStorage.renderSettingsForceRefresh = forceRefresh;
            renderSettingsStorage.renderSettingsForceRebuildGeometry = forceRebuildGeometry;
            renderSettingsStorage.renderSettingsPerformRendering = performRendering;
            renderSettingsStorage.renderSettingsUserRenderMode = (int)userRenderMode;
            renderSettingsStorage.renderSettingsSettingsMode = (int)settingsMode;
            renderSettingsStorage.renderSettingsFixSeams = fixSeams;
            renderSettingsStorage.renderSettingsDenoise = denoise;
            renderSettingsStorage.renderSettingsDenoise2x = denoise2x;
            renderSettingsStorage.renderSettingsEncode = encode;
            renderSettingsStorage.renderSettingsEncodeMode = encodeMode;
            renderSettingsStorage.renderSettingsOverwriteWarning = ftBuildGraphics.overwriteWarning;
            renderSettingsStorage.renderSettingsAutoAtlas = ftBuildGraphics.autoAtlas;
            renderSettingsStorage.renderSettingsUnwrapUVs = ftBuildGraphics.unwrapUVs;
            renderSettingsStorage.renderSettingsForceDisableUnwrapUVs = ftBuildGraphics.forceDisableUnwrapUVs;
            renderSettingsStorage.renderSettingsMaxAutoResolution = ftBuildGraphics.maxAutoResolution;
            renderSettingsStorage.renderSettingsMinAutoResolution = ftBuildGraphics.minAutoResolution;
            renderSettingsStorage.renderSettingsUnloadScenes = unloadScenesInDeferredMode;
            renderSettingsStorage.renderSettingsAdjustSamples = adjustSamples;
            renderSettingsStorage.renderSettingsGILODMode = (int)giLodMode;
            renderSettingsStorage.renderSettingsGILODModeEnabled = giLodModeEnabled;
            renderSettingsStorage.renderSettingsCheckOverlaps = checkOverlaps;
            renderSettingsStorage.renderSettingsOutPath = outputPath;
            renderSettingsStorage.renderSettingsUseScenePath = useScenePath;
            //renderSettingsStorage.renderSettingsTempPath = scenePathToSave;
            renderSettingsStorage.renderSettingsHackEmissiveBoost = hackEmissiveBoost;
            renderSettingsStorage.renderSettingsHackIndirectBoost = hackIndirectBoost;
            renderSettingsStorage.renderSettingsHackAOIntensity = hackAOIntensity;
            renderSettingsStorage.renderSettingsHackAORadius = hackAORadius;
            renderSettingsStorage.renderSettingsHackAOSamples = hackAOSamples;
            renderSettingsStorage.renderSettingsShowAOSettings = showAOSettings;
            renderSettingsStorage.renderSettingsShowTasks = showTasks;
            renderSettingsStorage.renderSettingsShowTasks2 = showTasks2;
            renderSettingsStorage.renderSettingsShowPaths = showPaths;
            renderSettingsStorage.renderSettingsShowNet = showNet;
            renderSettingsStorage.renderSettingsShowPerf = showPerf;
            //renderSettingsStorage.renderSettingsShowCompression = showCompression;
            renderSettingsStorage.renderSettingsTexelsPerMap = ftBuildGraphics.texelsPerUnitPerMap;
            renderSettingsStorage.renderSettingsTexelsColor = ftBuildGraphics.mainLightmapScale;
            renderSettingsStorage.renderSettingsTexelsMask = ftBuildGraphics.maskLightmapScale;
            renderSettingsStorage.renderSettingsTexelsDir = ftBuildGraphics.dirLightmapScale;
            renderSettingsStorage.renderSettingsOcclusionProbes = useUnityForOcclsusionProbes;
            renderSettingsStorage.renderSettingsBeepOnFinish = beepOnFinish;
            renderSettingsStorage.renderSettingsDistanceShadowmask = isDistanceShadowmask;
            renderSettingsStorage.renderSettingsShowDirWarning = showDirWarning;
            renderSettingsStorage.renderSettingsRenderDirMode = (int)renderDirMode;
            renderSettingsStorage.renderSettingsShowCheckerSettings = showCheckerSettings;
            renderSettingsStorage.usesRealtimeGI = usesRealtimeGI;
            renderSettingsStorage.renderSettingsSamplesWarning = samplesWarning;
            renderSettingsStorage.renderSettingsSuppressPopups = suppressPopups;
            renderSettingsStorage.renderSettingsPrefabWarning = prefabWarning;
            renderSettingsStorage.renderSettingsSplitByScene = ftBuildGraphics.splitByScene;
            renderSettingsStorage.renderSettingsSplitByTag = ftBuildGraphics.splitByTag;
            renderSettingsStorage.renderSettingsExportTerrainAsHeightmap = ftBuildGraphics.exportTerrainAsHeightmap;
            renderSettingsStorage.renderSettingsExportTerrainTrees = ftBuildGraphics.exportTerrainTrees;
            renderSettingsStorage.renderSettingsRTXMode = rtxMode;
            renderSettingsStorage.renderSettingsLightProbeMode = (int)lightProbeMode;
            renderSettingsStorage.renderSettingsServerAddress = ftClient.serverAddress;
            renderSettingsStorage.renderSettingsClientMode = clientMode;
            renderSettingsStorage.renderSettingsUVPaddingMax = ftBuildGraphics.uvPaddingMax;
            renderSettingsStorage.renderSettingsPostPacking = ftBuildGraphics.postPacking;
            renderSettingsStorage.renderSettingsHoleFilling = ftBuildGraphics.holeFilling;
            renderSettingsStorage.renderSettingsSampleDiv = sampleDivisor;
            renderSettingsStorage.renderSettingsUnwrapper = (int)unwrapper;
            renderSettingsStorage.renderSettingsDenoiserType = (int)denoiserType;
            //renderSettingsStorage.renderSettingsLegacyDenoiser = (denoiserType == ftGlobalStorage.DenoiserType.Optix5);//legacyDenoiser;
            renderSettingsStorage.renderSettingsAtlasPacker = ftBuildGraphics.atlasPacker;
            renderSettingsStorage.renderSettingsCompressVolumes = compressVolumes;
            renderSettingsStorage.renderSettingsSector = curSector;
        }
    }

    void RenderLightProbesUpdate()
    {
        if (!progressFunc.MoveNext())
        {
            EditorApplication.update -= RenderLightProbesUpdate;
        }

    }

    void RenderReflProbesUpdate()
    {
        if (!progressFunc.MoveNext())
        {
            EditorApplication.update -= RenderReflProbesUpdate;
        }

    }

    static float AreaElement(float x, float y)
    {
        return Mathf.Atan2(x * y, Mathf.Sqrt(x * x + y * y + 1));
    }

    const float inv2SqrtPI = 0.28209479177387814347403972578039f; // 1.0f / (2.0f * Mathf.Sqrt(Mathf.PI))
    const float sqrt3Div2SqrtPI = 0.48860251190291992158638462283835f; // Mathf.Sqrt(3.0f) / (2.0f * Mathf.Sqrt(Mathf.PI))
    const float sqrt15Div2SqrtPI = 1.0925484305920790705433857058027f; // Mathf.Sqrt(15.0f) / (2 * Mathf.Sqrt(Mathf.PI))
    const float threeSqrt5Div4SqrtPI = 0.94617469575756001809268107088713f; // 3 * Mathf.Sqrt(5.0f) / (4*Mathf.Sqrt(Mathf.PI))
    const float sqrt15Div4SqrtPI = 0.54627421529603953527169285290135f; // Mathf.Sqrt(15.0f) / (4 * Mathf.Sqrt(Mathf.PI))
    const float oneThird = 1.0f / 3.0f;

    static void EvalSHBasis9(Vector3 dir, ref float[] basis)
    {
        float dx = -dir.x;
        float dy = -dir.y;
        float dz = dir.z;
        basis[0] = inv2SqrtPI *                                 (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL0 :         ftAdditionalConfig.irradianceConvolutionL0);
        basis[1] = - dy * sqrt3Div2SqrtPI *                     (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL1 :         ftAdditionalConfig.irradianceConvolutionL1);
        basis[2] =   dz * sqrt3Div2SqrtPI *                     (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL1 :         ftAdditionalConfig.irradianceConvolutionL1);
        basis[3] = - dx * sqrt3Div2SqrtPI *                     (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL1 :         ftAdditionalConfig.irradianceConvolutionL1);
        basis[4] =   dx * dy * sqrt15Div2SqrtPI *               (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL2_4_5_7 :   ftAdditionalConfig.irradianceConvolutionL2_4_5_7);
        basis[5] = - dy * dz * sqrt15Div2SqrtPI *               (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL2_4_5_7 :   ftAdditionalConfig.irradianceConvolutionL2_4_5_7);
        basis[6] =  (dz*dz-oneThird) * threeSqrt5Div4SqrtPI *   (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL2_6 :       ftAdditionalConfig.irradianceConvolutionL2_6);
        basis[7] = - dx * dz * sqrt15Div2SqrtPI *               (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL2_4_5_7 :   ftAdditionalConfig.irradianceConvolutionL2_4_5_7);
        basis[8] =  (dx*dx-dy*dy) * sqrt15Div4SqrtPI *          (pstorage.removeRinging ? ftAdditionalConfig.rr_irradianceConvolutionL2_8 :       ftAdditionalConfig.irradianceConvolutionL2_8);
    }

    public static BakeryVolume[] FindBakeableVolumes()
    {
        var vols = FindObjectsOfType<BakeryVolume>();
        var vols2 = new List<BakeryVolume>();
        Transform sectorTform = null;
        if (curSector != null) sectorTform = curSector.transform;
        for(int v=0; v<vols.Length; v++)
        {
            if (vols[v].enableBaking)
            {
                if (fullSectorRender)
                {
                    var parent = vols[v].transform.parent;
                    while(parent != null)
                    {
                        if (parent == sectorTform) vols2.Add(vols[v]); // only use volumes parented to current sector
                        parent = parent.parent;
                    }
                }
                else
                {
                    vols2.Add(vols[v]);
                }
            }
        }
        lastFoundBakeableVolumes = vols2.ToArray();
        return lastFoundBakeableVolumes;
    }

    public static int VolumeDimension(int x)
    {
        const float blockSize = 4.0f;
        if (ftRenderLightmap.compressVolumes) return (int)(Mathf.Ceil(x/blockSize)*blockSize);
        return x;
    }

    void LoadVolumes()
    {
        var vols = FindBakeableVolumes();
        if (vols.Length == 0) return;

        int numTotalProbes = 0;
        for(int v=0; v<vols.Length; v++)
        {
            numTotalProbes += VolumeDimension(vols[v].resolutionX) * VolumeDimension(vols[v].resolutionY) * VolumeDimension(vols[v].resolutionZ);
        }

        int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)numTotalProbes));
        atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)tileSize) * tileSize;

        BakeryLightmapGroup.RenderMode pVolumeMode = (BakeryLightmapGroup.RenderMode)pstorage.volumeRenderMode;
        bool shadowmask = (pVolumeMode == BakeryLightmapGroup.RenderMode.Auto && userRenderMode == RenderMode.Shadowmask)
                        || pVolumeMode == BakeryLightmapGroup.RenderMode.Shadowmask;
        if (!hasAnyShadowmasks) shadowmask = false;

        var l0 = new float[atlasTexSize * atlasTexSize * 4];
        var l1x = new float[atlasTexSize * atlasTexSize * 4];
        var l1y = new float[atlasTexSize * atlasTexSize * 4];
        var l1z = new float[atlasTexSize * atlasTexSize * 4];
        byte[] lshadows = null;
        if (shadowmask) lshadows = new byte[atlasTexSize * atlasTexSize * 4];
        var handle = GCHandle.Alloc(l0, GCHandleType.Pinned);
        var handleL1x = GCHandle.Alloc(l1x, GCHandleType.Pinned);
        var handleL1y = GCHandle.Alloc(l1y, GCHandleType.Pinned);
        var handleL1z = GCHandle.Alloc(l1z, GCHandleType.Pinned);
        GCHandle handleShadows = new GCHandle();
        if (shadowmask) handleShadows = GCHandle.Alloc(lshadows, GCHandleType.Pinned);
        var errCodes = new int[5];
        try
        {
            var pointer = handle.AddrOfPinnedObject();
            var pointerL1x = handleL1x.AddrOfPinnedObject();
            var pointerL1y = handleL1y.AddrOfPinnedObject();
            var pointerL1z = handleL1z.AddrOfPinnedObject();
            System.IntPtr pointerShadows = (System.IntPtr)0;
            if (shadowmask) pointerShadows = handleShadows.AddrOfPinnedObject();
            errCodes[0] = halffloat2vb(scenePath + "\\volumes_final_L0" + (compressedOutput ? ".lz4" : ".dds"), pointer, 2);
            errCodes[1] = halffloat2vb(scenePath + "\\volumes_final_L1x" + (compressedOutput ? ".lz4" : ".dds"), pointerL1x, 2);
            errCodes[2] = halffloat2vb(scenePath + "\\volumes_final_L1y" + (compressedOutput ? ".lz4" : ".dds"), pointerL1y, 2);
            errCodes[3] = halffloat2vb(scenePath + "\\volumes_final_L1z" + (compressedOutput ? ".lz4" : ".dds"), pointerL1z, 2);
            if (shadowmask)
            {
                errCodes[4] = halffloat2vb(scenePath + "\\volumes_mask" + (compressedOutput ? ".lz4" : ".dds"), pointerShadows, 1);
            }
            bool ok = true;
            for(int i=0; i<5; i++)
            {
                if (errCodes[i] != 0)
                {
                    Debug.LogError("hf2vb (" + i + "): " + errCodes[i]);
                    ok = false;
                }
            }
            if (ok)
            {
                int i = 0;
                int maskI = 0;
                bool actuallyCompressVolumes = false;
#if UNITY_2020_1_OR_NEWER
                actuallyCompressVolumes = compressVolumes;
#endif
                for(int v=0; v<vols.Length; v++)
                {
                    var vol = vols[v];
                    int rx = VolumeDimension(vol.resolutionX);
                    int ry = VolumeDimension(vol.resolutionY);
                    int rz = VolumeDimension(vol.resolutionZ);
                    int numProbes = rx*ry*rz;
                    int numProbesInSlice = rx*ry;
                    int lastProbeInSlice = numProbesInSlice - 1;
                    int compressedSliceSizeHDR = 0;
                    int compressedSliceSizeLDR = 0;
                    Color[] texData0 = null;
                    Color[] texData1 = null;
                    Color[] texData2 = null;
                    Color[] texData3 = null;
                    Texture2D texSliceHDR = null;
                    Texture2D texSliceLDR = null;
                    byte[] compressedTexData0 = null;
                    byte[] compressedTexData1 = null;
                    byte[] compressedTexData2 = null;
                    byte[] compressedTexData3 = null;
                    if (actuallyCompressVolumes)
                    {
                        // Per slice arrays
                        texData0 = new Color[numProbesInSlice];
                        texData1 = new Color[numProbesInSlice];
                        texData2 = new Color[numProbesInSlice];
                        texData3 = new Color[numProbesInSlice];
                    }
                    else
                    {
                        // Full 3D arrays
                        texData0 = new Color[numProbes];
                        texData1 = new Color[numProbes];
                        texData2 = new Color[numProbes];
                    }
                    #if COMPRESS_VOLUME_RGBM
                        TextureFormat compressedHDRFormat = TextureFormat.BC7;
                        TextureFormat uncompressedHDRFormat = TextureFormat.ARGB32;
                    #else
                        TextureFormat compressedHDRFormat = TextureFormat.BC6H;
                        TextureFormat uncompressedHDRFormat = TextureFormat.RGBAHalf;
                    #endif
                    for(int z=0; z<rz; z++)
                    {
                        for(int y=0; y<ry; y++)
                        {
                            for(int x=0; x<rx; x++)
                            {
                                float l0r = l0[i*4+0] * 2;
                                float l0g = l0[i*4+1] * 2;
                                float l0b = l0[i*4+2] * 2;

                                const float convL0 = ftAdditionalConfig.convL0;
                                const float convL1 = ftAdditionalConfig.convL1;

                                float l1xr;
                                float l1xg;
                                float l1xb;
                                float l1yr;
                                float l1yg;
                                float l1yb;
                                float l1zr;
                                float l1zg;
                                float l1zb;
                                // read as BGR (2,1,0)
                                if (vol.encoding == BakeryVolume.Encoding.RGBA8 || vol.encoding == BakeryVolume.Encoding.RGBA8Mono)
                                {
                                    l1xr = ((l1x[i*4+2] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;
                                    l1xg = ((l1x[i*4+1] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;
                                    l1xb = ((l1x[i*4+0] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;

                                    l1yr = ((l1y[i*4+2] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;
                                    l1yg = ((l1y[i*4+1] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;
                                    l1yb = ((l1y[i*4+0] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;

                                    l1zr = ((l1z[i*4+2] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;
                                    l1zg = ((l1z[i*4+1] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;
                                    l1zb = ((l1z[i*4+0] * 2.0f - 1.0f) * convL1) * 0.5f + 0.5f;

                                    if (vol.encoding == BakeryVolume.Encoding.RGBA8Mono)
                                    {
                                        // Single direction packed to tex1
                                        l1xr = (l1xr + l1xg + l1xb) * 0.3333333333f;
                                        l1xg = (l1yr + l1yg + l1yb) * 0.3333333333f;
                                        l1xb = (l1zr + l1zg + l1zb) * 0.3333333333f;

                                        l1yr = l1yg = l1yb = 0;
                                        l1zr = l1zg = l1zb = 0;
                                    }
                                }
                                else
                                {
                                    l1xr = (l1x[i*4+2] * 2.0f - 1.0f) * l0r*2 * convL1;
                                    l1xg = (l1x[i*4+1] * 2.0f - 1.0f) * l0g*2 * convL1;
                                    l1xb = (l1x[i*4+0] * 2.0f - 1.0f) * l0b*2 * convL1;

                                    l1yr = (l1y[i*4+2] * 2.0f - 1.0f) * l0r*2 * convL1;
                                    l1yg = (l1y[i*4+1] * 2.0f - 1.0f) * l0g*2 * convL1;
                                    l1yb = (l1y[i*4+0] * 2.0f - 1.0f) * l0b*2 * convL1;

                                    l1zr = (l1z[i*4+2] * 2.0f - 1.0f) * l0r*2 * convL1;
                                    l1zg = (l1z[i*4+1] * 2.0f - 1.0f) * l0g*2 * convL1;
                                    l1zb = (l1z[i*4+0] * 2.0f - 1.0f) * l0b*2 * convL1;

                                    if (actuallyCompressVolumes)
                                    {
                                        float il0r = 1.0f / l0r;
                                        float il0g = 1.0f / l0g;
                                        float il0b = 1.0f / l0b;

                                        l1xr = (l1xr * il0r) * 0.5f + 0.5f;
                                        l1xg = (l1xg * il0g) * 0.5f + 0.5f;
                                        l1xb = (l1xb * il0b) * 0.5f + 0.5f;

                                        l1yr = (l1yr * il0r) * 0.5f + 0.5f;
                                        l1yg = (l1yg * il0g) * 0.5f + 0.5f;
                                        l1yb = (l1yb * il0b) * 0.5f + 0.5f;

                                        l1zr = (l1zr * il0r) * 0.5f + 0.5f;
                                        l1zg = (l1zg * il0g) * 0.5f + 0.5f;
                                        l1zb = (l1zb * il0b) * 0.5f + 0.5f;
                                    }
                                }
                                l0r *= convL0;
                                l0g *= convL0;
                                l0b *= convL0;


                                if (actuallyCompressVolumes)
                                {
                                    int index = y*rx + x;
                                    #if COMPRESS_VOLUME_RGBM
                                        const float rgbmMul = 1.0f / 8.0f;
                                        l0r = Mathf.Sqrt(l0r) * rgbmMul;
                                        l0g = Mathf.Sqrt(l0g) * rgbmMul;
                                        l0b = Mathf.Sqrt(l0b) * rgbmMul;
                                        float a = Mathf.Max(Mathf.Max(Mathf.Max(l0r, l0g), l0b), 1.0f / 255);
                                        if (a > 1.0f) a = 1.0f;
                                        a = Mathf.Ceil(a * 255.0f) / 255.0f;
                                        float invA = 1.0f / a;
                                        l0r *= invA;
                                        l0g *= invA;
                                        l0b *= invA;
                                        texData0[index] = new Color(l0r, l0g, l0b, a);
                                    #else
                                        texData0[index] = new Color(l0r, l0g, l0b, 1.0f);
                                    #endif
                                    texData1[index] = new Color(l1xr, l1xg, l1xb, 1.0f);
                                    texData2[index] = new Color(l1yr, l1yg, l1yb, 1.0f);
                                    texData3[index] = new Color(l1zr, l1zg, l1zb, 1.0f);
                                    if (index == lastProbeInSlice)
                                    {
                                        // Would be nice if CompressTexture had separate src/dest args and we could reuse the textures...
                                        texSliceHDR = new Texture2D(rx, ry, uncompressedHDRFormat, false);

                                        // L0
                                        texSliceHDR.SetPixels(texData0);
                                        texSliceHDR.Apply();
                                        EditorUtility.CompressTexture(texSliceHDR, compressedHDRFormat,
#if UNITY_2019_3_OR_NEWER
                                            UnityEditor.TextureCompressionQuality.Best);
#else
                                            (int)UnityEngine.TextureCompressionQuality.Best);
#endif
                                        var sliceBytes = texSliceHDR.GetRawTextureData();
                                        if (compressedSliceSizeHDR == 0)
                                        {
                                            compressedTexData0 = new byte[sliceBytes.Length * rz];
                                            compressedSliceSizeHDR = sliceBytes.Length;
                                        }
                                        int coffset = compressedSliceSizeHDR * z;
                                        for(int c=0; c<compressedSliceSizeHDR; c++) compressedTexData0[coffset + c] = sliceBytes[c];
                                        DestroyImmediate(texSliceHDR);

                                        // L1x
                                        texSliceLDR = new Texture2D(rx, ry, TextureFormat.ARGB32, false);
                                        texSliceLDR.SetPixels(texData1);
                                        texSliceLDR.Apply();
                                        EditorUtility.CompressTexture(texSliceLDR, TextureFormat.BC7,
#if UNITY_2019_3_OR_NEWER
                                            UnityEditor.TextureCompressionQuality.Best);
#else
                                            (int)UnityEngine.TextureCompressionQuality.Best);
#endif
                                        sliceBytes = texSliceLDR.GetRawTextureData();
                                        if (compressedSliceSizeLDR == 0)
                                        {
                                            compressedTexData1 = new byte[sliceBytes.Length * rz];
                                            compressedTexData2 = new byte[sliceBytes.Length * rz];
                                            compressedTexData3 = new byte[sliceBytes.Length * rz];
                                            compressedSliceSizeLDR = sliceBytes.Length;
                                        }
                                        coffset = compressedSliceSizeLDR * z;
                                        for(int c=0; c<compressedSliceSizeLDR; c++) compressedTexData1[coffset + c] = sliceBytes[c];
                                        DestroyImmediate(texSliceLDR);

                                        // L1y
                                        texSliceLDR = new Texture2D(rx, ry, TextureFormat.ARGB32, false);
                                        texSliceLDR.SetPixels(texData2);
                                        texSliceLDR.Apply();
                                        EditorUtility.CompressTexture(texSliceLDR, TextureFormat.BC7,
#if UNITY_2019_3_OR_NEWER
                                            UnityEditor.TextureCompressionQuality.Best);
#else
                                            (int)UnityEngine.TextureCompressionQuality.Best);
#endif
                                        sliceBytes = texSliceLDR.GetRawTextureData();
                                        for(int c=0; c<compressedSliceSizeLDR; c++) compressedTexData2[coffset + c] = sliceBytes[c];
                                        DestroyImmediate(texSliceLDR);

                                        // L1z
                                        texSliceLDR = new Texture2D(rx, ry, TextureFormat.ARGB32, false);
                                        texSliceLDR.SetPixels(texData3);
                                        texSliceLDR.Apply();
                                        EditorUtility.CompressTexture(texSliceLDR, TextureFormat.BC7,
#if UNITY_2019_3_OR_NEWER
                                            UnityEditor.TextureCompressionQuality.Best);
#else
                                            (int)UnityEngine.TextureCompressionQuality.Best);
#endif
                                        sliceBytes = texSliceLDR.GetRawTextureData();
                                        for(int c=0; c<compressedSliceSizeLDR; c++) compressedTexData3[coffset + c] = sliceBytes[c];
                                        DestroyImmediate(texSliceLDR);
                                    }
                                }
                                else
                                {
                                    int index = z*ry*rx + y*rx + x;
                                    texData0[index] = new Color(l0r, l0g, l0b, l1zr);
                                    texData1[index] = new Color(l1xr, l1xg, l1xb, l1zg);
                                    texData2[index] = new Color(l1yr, l1yg, l1yb, l1zb);
                                }
                                i++;
                            }
                        }
                    }

                    // AMW - name volume based on the lightmapped prefab (if it exists) vs the scene
                    var lightmappedPrefab = vol.gameObject.GetComponentInParent<BakeryLightmappedPrefab>();
                    var volNamePrefix = ( lightmappedPrefab != null ) ? lightmappedPrefab.name : vol.gameObject.scene.name;
                    var outNameBase = "Assets/" + outputPath + "/" + volNamePrefix + "_" + vol.name;

                    //var outNameBase = "Assets/" + outputPath + "/" + vol.gameObject.scene.name + "_" + vol.name;

                    TextureFormat vformatHDR;
                    TextureFormat vformatLDR = TextureFormat.BC7;
                    if (actuallyCompressVolumes)
                    {
                        vformatHDR = vol.encoding == BakeryVolume.Encoding.Half4 ? compressedHDRFormat : TextureFormat.BC7;
                    }
                    else
                    {
                        vformatHDR = vol.encoding == BakeryVolume.Encoding.Half4 ? TextureFormat.RGBAHalf : TextureFormat.ARGB32;
                    }

                    var outName = outNameBase + "0.asset";
                    if (File.Exists(outName)) ValidateFileAttribs(outName);
                    var tex = new Texture3D(rx, ry, rz, vformatHDR, false);
                    tex.filterMode = FilterMode.Bilinear;
                    tex.wrapMode = TextureWrapMode.Clamp;
                    if (actuallyCompressVolumes)
                    {
#if UNITY_2020_1_OR_NEWER
                        tex.SetPixelData(compressedTexData0, 0, 0);
#endif
                    }
                    else
                    {
                        tex.SetPixels(texData0);
                    }
                    tex.Apply();
                    tex = CreateOrReplaceAsset(tex, outName);
                    vol.bakedTexture0 = tex;

                    outName = outNameBase + "1.asset";
                    if (File.Exists(outName)) ValidateFileAttribs(outName);
                    tex = new Texture3D(rx, ry, rz, actuallyCompressVolumes ? vformatLDR : vformatHDR, false);
                    tex.filterMode = FilterMode.Bilinear;
                    tex.wrapMode = TextureWrapMode.Clamp;
                    if (actuallyCompressVolumes)
                    {
#if UNITY_2020_1_OR_NEWER
                        tex.SetPixelData(compressedTexData1, 0, 0);
#endif
                    }
                    else
                    {
                        tex.SetPixels(texData1);
                    }
                    tex.Apply();
                    tex = CreateOrReplaceAsset(tex, outName);
                    vol.bakedTexture1 = tex;

                    outName = outNameBase + "2.asset";
                    if (File.Exists(outName)) ValidateFileAttribs(outName);
                    tex = new Texture3D(rx, ry, rz, actuallyCompressVolumes ? vformatLDR : vformatHDR, false);
                    tex.filterMode = FilterMode.Bilinear;
                    tex.wrapMode = TextureWrapMode.Clamp;
                    if (actuallyCompressVolumes)
                    {
#if UNITY_2020_1_OR_NEWER
                        tex.SetPixelData(compressedTexData2, 0, 0);
#endif
                    }
                    else
                    {
                        tex.SetPixels(texData2);
                    }
                    tex.Apply();
                    tex = CreateOrReplaceAsset(tex, outName);
                    vol.bakedTexture2 = tex;

                    if (actuallyCompressVolumes)
                    {
#if UNITY_2020_1_OR_NEWER
                        outName = outNameBase + "3.asset";
                        if (File.Exists(outName)) ValidateFileAttribs(outName);
                        tex = new Texture3D(rx, ry, rz, actuallyCompressVolumes ? vformatLDR : vformatHDR, false);
                        tex.filterMode = FilterMode.Bilinear;
                        tex.wrapMode = TextureWrapMode.Clamp;
                        tex.SetPixelData(compressedTexData3, 0, 0);
                        tex.Apply();
                        tex = CreateOrReplaceAsset(tex, outName);
                        vol.bakedTexture3 = tex;
#endif
                    }
                    else
                    {
                        vol.bakedTexture3 = null;
                    }

                    if (shadowmask)
                    {
                        var texData = new Color32[numProbes];
                        for(int z=0; z<rz; z++)
                        {
                            for(int y=0; y<ry; y++)
                            {
                                for(int x=0; x<rx; x++)
                                {
                                    int index = z*ry*rx + y*rx + x;
                                    if (vol.shadowmaskEncoding == BakeryVolume.ShadowmaskEncoding.A8)
                                    {
                                        byte sr = lshadows[maskI*4+0];
                                        texData[index] = new Color32(sr,sr,sr,sr);
                                    }
                                    else
                                    {
                                        byte sr = lshadows[maskI*4+0];
                                        byte sg = lshadows[maskI*4+1];
                                        byte sb = lshadows[maskI*4+2];
                                        byte sa = lshadows[maskI*4+3];
                                        if (vol.firstLightIsAlwaysAlpha)
                                        {
                                            texData[index] = new Color32(sg,sb,sa,sr);
                                        }
                                        else
                                        {
                                            texData[index] = new Color32(sr,sg,sb,sa);
                                        }
                                    }
                                    maskI++;
                                }
                            }
                        }


                        var vformat = (vol.shadowmaskEncoding == BakeryVolume.ShadowmaskEncoding.A8) ? TextureFormat.Alpha8 : TextureFormat.ARGB32;
                        outName = outNameBase + "_mask.asset";
                        if (File.Exists(outName)) ValidateFileAttribs(outName);
                        tex = new Texture3D(rx, ry, rz, vformat, false);
                        tex.filterMode = FilterMode.Bilinear;
                        tex.wrapMode = TextureWrapMode.Clamp;
                        tex.SetPixels32(texData);
                        tex.Apply();
                        tex = CreateOrReplaceAsset(tex, outName);
                        vol.bakedMask = tex;
                    }

                    AssetDatabase.SaveAssets();

                    if (vol.isGlobal) vol.OnEnable();

                    EditorUtility.SetDirty(vol);
                }
            }
        }
        finally
        {
            handle.Free();
            handleL1x.Free();
            handleL1y.Free();
            handleL1z.Free();
            if (shadowmask) handleShadows.Free();
        }
    }

    static Texture3D CreateOrReplaceAsset(Texture3D src, string path)
    {
        var dest = AssetDatabase.LoadAssetAtPath<Texture3D>(path);
        if (dest == null)
        {
            AssetDatabase.CreateAsset(src, path);
            dest = src;
        }
        else
        {
            EditorUtility.CopySerialized(src, dest);
            EditorUtility.SetDirty(dest);
        }
        return dest;
    }

    static Texture2D CreateOrReplaceAsset(Texture2D src, string path)
    {
        var dest = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
        if (dest == null)
        {
            AssetDatabase.CreateAsset(src, path);
            dest = src;
        }
        else
        {
            EditorUtility.CopySerialized(src, dest);
            EditorUtility.SetDirty(dest);
        }
        return dest;
    }

    public static void RestoreSceneManagerSetup(SceneSetup[] sceneSetups)
    {
        EditorSceneManager.RestoreSceneManagerSetup(sceneSetups);
    }

    static public void DebugLogError(string text)
    {
        userCanceled = true;
        ProgressBarEnd();
        if (verbose)
        {
            EditorUtility.DisplayDialog("Bakery error", text, "OK");
        }
        else
        {
            Debug.LogError(text);
        }
    }

    public static void DebugLogInfo(string info)
    {
        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();
        if ((pstorage.logLevel & (int)BakeryProjectSettings.LogLevel.Info) != 0) Debug.Log(info);
    }

    public static void DebugLogWarning(string info)
    {
        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();
        if ((pstorage.logLevel & (int)BakeryProjectSettings.LogLevel.Warning) != 0) Debug.LogWarning(info);
    }

    IEnumerator RenderReflProbesFunc()
    {
        ProgressBarInit("Rendering reflection probes...");

        // AMW
        if ( OnPreReflectionProbeRender != null )
        {
            OnPreReflectionProbeRender.Invoke( this, null );
        }

        // Put empty lighting data asset to scenes to prevent reflection probes bake trying to re-render everything
        int sceneCount = SceneManager.sceneCount;
        var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
        for(int s=0; s<sceneCount; s++)
        {
            var scene = EditorSceneManager.GetSceneAt(s);
            LightingDataAsset copiedAsset = null;
            string assetName;
            if (!scene.isLoaded) continue;
            if (Lightmapping.lightingDataAsset == null)
            {
                if (emptyLDataAsset == null) emptyLDataAsset =
                    AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "emptyLightingData.asset", typeof(LightingDataAsset)) as LightingDataAsset;

                if (emptyLDataAsset == null)
                {
                    Debug.LogError("Can't load emptyLightingData.asset");
                    continue;
                }

                if (copiedAsset == null)
                {
                    assetName = GenerateLightingDataAssetName();
                    var outName = "Assets/" + outputPath + "/" + assetName + "_probes.asset";
                    if (File.Exists(outName)) ValidateFileAttribs(outName);
                    if (AssetDatabase.CopyAsset(bakeryRuntimePath + "emptyLightingData.asset",  outName))
                    {
                        AssetDatabase.Refresh();
                        copiedAsset = AssetDatabase.LoadAssetAtPath(outName, typeof(LightingDataAsset)) as LightingDataAsset;
                        if (copiedAsset == null)
                        {
                            Debug.LogError("Can't load " + outName);
                            continue;
                        }
                    }
                    else
                    {
                        Debug.LogError("Can't copy emptyLightingData.asset");
                        continue;
                    }
                }

                Lightmapping.lightingDataAsset = copiedAsset;
                ftLightmaps.RefreshFull();
            }
        }

        var bakeFunc = typeof(Lightmapping).GetMethod("BakeAllReflectionProbesSnapshots",
            BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
        if (bakeFunc == null)
        {
            ProgressBarEnd();
            DebugLogError("Can't get BakeAllReflectionProbesSnapshots function");
            bakeInProgress = false;
            yield break;
        }
        bakeFunc.Invoke(null, null);

        // Revert lighting data assets
        /*for(int s=0; s<sceneCount; s++)
        {
            var scene = EditorSceneManager.GetSceneAt(s);
            if (!scene.isLoaded) continue;
            if (Lightmapping.lightingDataAsset == emptyLDataAsset)
            {
                Lightmapping.lightingDataAsset = null;
            }
        }*/

        EditorSceneManager.MarkAllScenesDirty();

        ProgressBarEnd();

        if (OnFinishedReflectionProbes != null)
        {
            OnFinishedReflectionProbes.Invoke(this, null);
        }

        bakeInProgress = false;
    }

    static string GetSunRenderMode(BakeryDirectLight light, bool allowSupersample)
    {
        if (allowSupersample && light.supersample) return "sunsupersample";
        return light.cloudShadow != null ? "suncloudshadow" : "sun"; // anyone uses cloudshadow? not supporting it with supersample for now
    }

    static string GetPointLightRenderMode(BakeryPointLight light)
    {
        string renderMode;
        if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cone)
        {
            renderMode = "conelight";
        }
        else if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cookie)
        {
            if (light.cookie == null)
            {
                Debug.LogError("No cookie texture is set for light " + light.name);
                renderMode = "pointlight";
            }
            else
            {
                renderMode = "cookielight";
            }
        }
        else if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cubemap || light.projMode == BakeryPointLight.ftLightProjectionMode.IES)
        {
            if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cubemap && light.cubemap == null)
            {
                Debug.LogError("No cubemap set for light " + light.name);
                renderMode = "pointlight";
            }
            else if (light.projMode == BakeryPointLight.ftLightProjectionMode.IES && light.iesFile == null)
            {
                Debug.LogError("No IES file is set for light " + light.name);
                renderMode = "pointlight";
            }
            else
            {
                renderMode = "cubemaplight";
            }
        }
        else
        {
            renderMode = "pointlight";
        }
        return renderMode;
    }

    static bool _ValidateCurrentScene()
    {
        var fname = scenePath + "/lastscene.txt";
        if (!File.Exists(fname)) return false;
        var cur = ftRenderLightmap.GenerateLightingDataAssetName();
        var last = File.ReadAllText(fname);
        return cur == last;
    }

    public static bool ValidateCurrentScene()
    {
        if (!_ValidateCurrentScene())
        {
            DebugLogError("Current scenes don't match last exported scenes. Make sure 'Export geometry and maps' is enabled.");
            userCanceled = true;
            return false;
        }
        return true;
    }

    public static string GenerateLightingDataAssetName()
    {
        var sceneCount = SceneManager.sceneCount;
        var assetName = "";
        var assetNameHashPart = "";
        for(int i=0; i<sceneCount; i++)
        {
            var s = EditorSceneManager.GetSceneAt(i);
            if (!s.isLoaded) continue;
            if (i == 0)
            {
                assetName += s.name;
            }
            else
            {
                assetNameHashPart += s.name;
                if (i < sceneCount - 1) assetNameHashPart += "__";
            }
        }
        assetName += "_" + assetNameHashPart.GetHashCode();
        return assetName;
    }

    LightingDataAsset ApplyLightingDataAsset(string newPath)
    {
        var newAsset = AssetDatabase.LoadAssetAtPath(newPath, typeof(LightingDataAsset)) as LightingDataAsset;
        int sceneCount = SceneManager.sceneCount;
        for(int i=0; i<sceneCount; i++)
        {
            var s = EditorSceneManager.GetSceneAt(i);
            if (!s.isLoaded) continue;
            SceneManager.SetActiveScene(s);
            Lightmapping.lightingDataAsset = newAsset;
        }
        return newAsset;
    }

#if UNITY_2017_3_OR_NEWER
#else
    Light AddTempShadowmaskLight(Light light, Scene scene)
    {
        var g = new GameObject();
        SceneManager.MoveGameObjectToScene(g, scene);
        var ulht2 = g.AddComponent<Light>();
        ulht2.type = light.type;
        ulht2.lightmapBakeType = LightmapBakeType.Mixed;
        ulht2.shadows = LightShadows.Soft;
        ulht2.range = light.range;
        ulht2.transform.position = light.transform.position;
        GameObjectUtility.SetStaticEditorFlags(g, StaticEditorFlags.LightmapStatic);
        return ulht2;
    }

    bool GetLightDataForPatching(Light lightTemp, Light lightReal, ref Dictionary<long,long> idMap, ref Dictionary<long,int> realID2Channel)
    {
        if (inspectorModeInfo == null)
            inspectorModeInfo = typeof(SerializedObject).GetProperty("inspectorMode", BindingFlags.NonPublic | BindingFlags.Instance);

        var so = new SerializedObject(lightReal);
        inspectorModeInfo.SetValue(so, InspectorMode.Debug, null);
        long realID = so.FindProperty("m_LocalIdentfierInFile").longValue;
        realID2Channel[realID] = so.FindProperty("m_BakingOutput").FindPropertyRelative("occlusionMaskChannel").intValue;

        so = new SerializedObject(lightTemp);
        inspectorModeInfo.SetValue(so, InspectorMode.Debug, null);
        long tempID = so.FindProperty("m_LocalIdentfierInFile").longValue;

        if (tempID == 0)
        {
            DebugLogError("tempID == 0");
            return false;
        }

        if (realID == 0)
        {
            DebugLogError("realID == 0");
            return false;
        }

        idMap[tempID] = realID;

        return true;
    }
#endif

    bool IsLightCompletelyBaked(bool bakeToIndirect, bool shadowmask, RenderMode rmode)
    {
        bool isBaked = ((rmode == RenderMode.FullLighting) ||
                        (rmode == RenderMode.Indirect && bakeToIndirect) ||
                        (rmode == RenderMode.Shadowmask && bakeToIndirect && !shadowmask));
        return isBaked;
    }

    void MarkLightAsCompletelyBaked(Light ulht)
    {
        var st = storages[ulht.gameObject.scene];
        if (!st.bakedLights.Contains(ulht))
        {
            st.bakedLights.Add(ulht);
            st.bakedLightChannels.Add(-1);
        }

#if UNITY_2017_3_OR_NEWER
        var output = new LightBakingOutput();
        output.isBaked = true;
        output.lightmapBakeType = LightmapBakeType.Baked;
        ulht.bakingOutput = output;
#endif
    }

    bool IsLightRealtime(bool bakeToIndirect, RenderMode rmode)
    {
        bool isRealtime = ((rmode == RenderMode.Indirect && !bakeToIndirect) ||
                           (rmode == RenderMode.Shadowmask && !bakeToIndirect));
        return isRealtime;
    }

    void MarkLightAsRealtime(Light ulht)
    {
#if UNITY_2017_3_OR_NEWER
        var output = new LightBakingOutput();
        output.isBaked = false;
        output.lightmapBakeType = LightmapBakeType.Realtime;
        output.mixedLightingMode = MixedLightingMode.IndirectOnly;
        output.occlusionMaskChannel = -1;
        output.probeOcclusionLightIndex = -1;
        ulht.bakingOutput = output;
#endif
    }

    bool IsLightSubtractive(bool bakeToIndirect, RenderMode rmode)
    {
        return rmode == RenderMode.Subtractive;
    }

    void MarkLightAsSubtractive(Light ulht)
    {
        var st = storages[ulht.gameObject.scene];
        if (!st.bakedLights.Contains(ulht))
        {
            st.bakedLights.Add(ulht);
            st.bakedLightChannels.Add(101);
        }

#if UNITY_2017_3_OR_NEWER
        var output = new LightBakingOutput();
        output.isBaked = true;
        output.lightmapBakeType = LightmapBakeType.Mixed;
        output.mixedLightingMode = MixedLightingMode.Subtractive;
        output.occlusionMaskChannel = -1;
        output.probeOcclusionLightIndex = -1;
        ulht.bakingOutput = output;
#else
        ulht.alreadyLightmapped = true;
        ulht.lightmapBakeType = LightmapBakeType.Mixed;
        var so = new SerializedObject(ulht);
        var sp = so.FindProperty("m_BakingOutput");
        sp.FindPropertyRelative("occlusionMaskChannel").intValue = 0;
        sp.FindPropertyRelative("lightmappingMask").intValue = 131076;
        so.ApplyModifiedProperties();

        if (!maskedLights.Contains(ulht)) maskedLights.Add(ulht);
#endif
    }

    void SceneSavedTest(Scene scene)
    {
        if (sceneSavedTestScene == scene) sceneWasSaved = true;
    }

    static int GetShadowmaskChannel(BakeryPointLight a)
    {
        int channelA = -1;
        if (!a.shadowmask) return channelA;
        var uA = a.GetComponent<Light>();
        if (uA != null)
        {
            var stA = storages[a.gameObject.scene];
            int indexA = stA.bakedLights.IndexOf(uA);
            if (indexA >= 0 && indexA < stA.bakedLightChannels.Count)
            {
                channelA = stA.bakedLightChannels[indexA];
            }
        }
        else if (a.shadowmask && a.bakeToIndirect) // full+shadowmask mode
        {
            channelA = a.maskChannel;
        }
        return channelA;
    }

    static int ComparePointLights(BakeryPointLight a, BakeryPointLight b)
    {
        int channelA = GetShadowmaskChannel(a);
        float compA = channelA * 10000 + ((a.bakeToIndirect && !a.shadowmask) ? 1000 : 0) + (a.legacySampling ? 100 : 0) + a.indirectIntensity;

        int channelB = GetShadowmaskChannel(b);
        float compB = channelB * 10000 + ((b.bakeToIndirect && !b.shadowmask) ? 1000 : 0) + (b.legacySampling ? 100 : 0) + b.indirectIntensity;

        return compB.CompareTo(compA);
    }

    public IEnumerator InitializeLightProbes(bool optional)
    {
        hasAnyProbes = true;
        var probeGroups = FindObjectsOfType(typeof(LightProbeGroup)) as LightProbeGroup[];
        if (probeGroups.Length == 0)
        {
            if (!optional) DebugLogError("Add at least one LightProbeGroup");
            hasAnyProbes = false;
            yield break;
        }
        else
        {
            int totalProbes = 0;
            for(int i=0; i<probeGroups.Length; i++)
            {
                totalProbes += probeGroups[i].probePositions.Length;
            }
            if (totalProbes == 0)
            {
                if (!optional) DebugLogError("Add at least one light probe");
                hasAnyProbes = false;
                yield break;
            }
        }

        ftBuildLights.InitMaps(true);
        if (useUnityForOcclsusionProbes)
        {
            var fgo = GameObject.Find("!ftraceLightmaps");
            if (fgo == null) {
                fgo = new GameObject();
                fgo.name = "!ftraceLightmaps";
                fgo.hideFlags = HideFlags.HideInHierarchy;
            }
            var store = fgo.GetComponent<ftLightmapsStorage>();
            if (store == null) {
                store = fgo.AddComponent<ftLightmapsStorage>();
            }

#if UNITY_2017_2_OR_NEWER
            if (LightmapEditorSettings.lightmapper == BUILTIN_RADIOSITY)
            {
                bool cont = true;
                if (verbose)
                {
                    cont = EditorUtility.DisplayDialog("Bakery", "Unity does not currently support external occlusion probes. You are going to generate them using Enlighten. This process can take an eternity of time. It is recommended to use Progressive to generate them instead.", "Use Progressive", "Continue anyway");
                }
                else
                {
                    Debug.LogError("Enlighten used to generate occlusion probes");
                }
                if (cont)
                {
                    LightmapEditorSettings.lightmapper = BUILTIN_PT;
                }
            }
            else
            {
                if (!store.enlightenWarningShown)
                {
                    if (verbose)
                    {
                        if (!EditorUtility.DisplayDialog("Bakery", "Unity does not currently support external occlusion probes. You are going to generate them using Progressive.\n", "Continue anyway", "Cancel"))
                        {
                            hasAnyProbes = false;
                            yield break;
                        }
                    }
                    else
                    {
                        Debug.LogError("Enlighten used to generate occlusion probes");
                    }
                }
            }
            if (!store.enlightenWarningShown)
            {
                store.enlightenWarningShown = true;
                EditorUtility.SetDirty(store);
            }
#else
            if (!store.enlightenWarningShown)
            {
                if (verbose)
                {
                    if (!EditorUtility.DisplayDialog("Bakery", "Unity does not currently support external occlusion probes. You are going to generate them using Enlighten or Progressive - whichever is enabled in the Lighting window.\nMake sure you have selected Progressive, as Enlighten can take an eternity of time.", "Continue anyway", "Cancel"))
                    {
                        hasAnyProbes = false;
                        yield break;
                    }
                    store.enlightenWarningShown = true;
                    EditorUtility.SetDirty(store);
                }
                else
                {
                    Debug.LogError("Enlighten used to generate occlusion probes");
                }
            }
#endif

            var staticObjects = new List<Renderer>();
            var staticObjectsScale = new List<float>();
#if USE_TERRAINS
            var staticObjectsTerrain = new List<Terrain>();
            var staticObjectsScaleTerrain = new List<float>();
#endif
            try
            {
                // Temporarily zero scale in lightmap to prevent Unity from generating its lightmaps
                // terrains?
                var objs = Resources.FindObjectsOfTypeAll(typeof(GameObject));
                foreach(GameObject obj in objs)
                {
                    if (obj == null) continue;
                    if (!obj.activeInHierarchy) continue;
                    var path = AssetDatabase.GetAssetPath(obj);
                    if (path != "") continue; // must belond to scene
                    //if ((obj.hideFlags & (HideFlags.DontSave|HideFlags.HideAndDontSave)) != 0) continue; // skip temp objects
                    //if (obj.tag == "EditorOnly") continue; // skip temp objects
                    //var areaLight = obj.GetComponent<BakeryLightMesh>();
                    //if (areaLight != null && !areaLight.selfShadow) continue;
                    var mr = ftBuildGraphics.GetValidRenderer(obj);
                    var mf = obj.GetComponent<MeshFilter>();
#if USE_TERRAINS
                    var tr = obj.GetComponent<Terrain>();
#endif
                    //if (((GameObjectUtility.GetStaticEditorFlags(obj) & StaticEditorFlags.LightmapStatic) == 0) && areaLight==null) continue; // skip dynamic
                    if ((GameObjectUtility.GetStaticEditorFlags(obj) & StaticEditorFlags.LightmapStatic) == 0) continue; // skip dynamic

                    var sharedMesh = ftBuildGraphics.GetSharedMesh(mr);

                    if (mr != null && mr.enabled && mf != null && sharedMesh != null)
                    {
                        var so = new SerializedObject(mr);
                        var prop = so.FindProperty("m_ScaleInLightmap");
                        var scaleInLm = prop.floatValue;
                        if (scaleInLm == 0) continue;
                        staticObjectsScale.Add(scaleInLm);
                        prop.floatValue = 0;
                        so.ApplyModifiedProperties();
                        staticObjects.Add(mr);
                    }

#if USE_TERRAINS
                    if (tr != null && tr.enabled)
                    {
                        var so = new SerializedObject(tr);
                        var prop = so.FindProperty("m_ScaleInLightmap");
                        var scaleInLm = prop.floatValue;
                        if (scaleInLm == 0) continue;
                        staticObjectsScaleTerrain.Add(scaleInLm);
                        prop.floatValue = 0;
                        so.ApplyModifiedProperties();
                        staticObjectsTerrain.Add(tr);
                    }
#endif
                }
            }
            catch
            {
                Debug.LogError("Failed rendering light probes");
                throw;
            }

            var lms = LightmapSettings.lightmaps;
            Texture2D firstLM = null;
            if (lms.Length > 0) firstLM = lms[0].lightmapColor;

            Lightmapping.BakeAsync();
            ProgressBarInit("Waiting for Unity to initialize the probes...");
            while(Lightmapping.isRunning)
            {
                userCanceled = simpleProgressBarCancelled();
                if (userCanceled)
                {
                    Lightmapping.Cancel();
                    ProgressBarEnd();
                    break;
                }
                yield return null;
            }
            ProgressBarEnd();

            lms = LightmapSettings.lightmaps;
            if (lms.Length == 1 && lms[0].lightmapColor != firstLM)
            {
                // During occlusion probe rendering Unity also generated useless tiny LMs - delete them to prevent lightmap array pollution
                if (lms[0].lightmapColor != null) AssetDatabase.DeleteAsset(AssetDatabase.GetAssetPath(lms[0].lightmapColor));
                if (lms[0].lightmapDir != null) AssetDatabase.DeleteAsset(AssetDatabase.GetAssetPath(lms[0].lightmapDir));
            }

            for(int i=0; i<staticObjects.Count; i++)
            {
                var so = new SerializedObject(staticObjects[i]);
                so.FindProperty("m_ScaleInLightmap").floatValue = staticObjectsScale[i];
                so.ApplyModifiedProperties();
            }
#if USE_TERRAINS
            for(int i=0; i<staticObjectsTerrain.Count; i++)
            {
                var so = new SerializedObject(staticObjectsTerrain[i]);
                so.FindProperty("m_ScaleInLightmap").floatValue = staticObjectsScaleTerrain[i];
                so.ApplyModifiedProperties();
            }
#endif
            ftLightmaps.RefreshFull();

            if (userCanceled) yield break;
        }

        int sceneCount = SceneManager.sceneCount;
        SceneSetup[] setup = null;
        Scene scene;
        string lmdataPath = null;
        string newPath = null;
        newAssetLData = null;
#if UNITY_2017_3_OR_NEWER
#else
        Dictionary<long,long> tempID2RealID = null;
        Dictionary<long,int> realID2Channel = null;
#endif

        reflProbesValue = QualitySettings.realtimeReflectionProbes;
        QualitySettings.realtimeReflectionProbes = true;
        revertReflProbesValue = true;

        if (!useUnityForOcclsusionProbes)
        {
            setup = EditorSceneManager.GetSceneManagerSetup();
        }

        if (!useUnityForOcclsusionProbes)
        {
            if (verbose)
            {
                if (!EditorSceneManager.EnsureUntitledSceneHasBeenSaved("Please save all scenes before rendering"))
                {
                    yield break;
                }
            }
            else
            {
                EditorSceneManager.SaveOpenScenes();
            }
            var assetName = GenerateLightingDataAssetName();

            scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Additive);
            SceneManager.SetActiveScene(scene);
            RenderSettings.skybox = null;
            LightmapSettings.lightmapsMode = LightmapsMode.NonDirectional;

            var probeGroupClones = new GameObject[probeGroups.Length];
            for(int i=0; i<probeGroups.Length; i++)
            {
                var g = new GameObject();
                g.transform.position = probeGroups[i].transform.position;
                g.transform.rotation = probeGroups[i].transform.rotation;
                g.transform.localScale = probeGroups[i].transform.lossyScale;
                var p = g.AddComponent<LightProbeGroup>();
                p.probePositions = probeGroups[i].probePositions;
                SceneManager.MoveGameObjectToScene(g, scene);
                probeGroupClones[i] = g;
            }

#if UNITY_2017_3_OR_NEWER
#else
            // Make sure shadowmask lights are present in LightingDataAsset together with probes
            // Occlusion channel needs to be patched later
            List<Light> maskedLightsTemp = null;
            List<Light> maskedLightsReal = null;
            if (userRenderMode == RenderMode.Shadowmask || userRenderMode == RenderMode.Subtractive)
            {
                maskedLightsTemp = new List<Light>();
                maskedLightsReal = new List<Light>();
                AllP = FindObjectsOfType(typeof(BakeryPointLight)) as BakeryPointLight[];
                All3 = FindObjectsOfType(typeof(BakeryDirectLight)) as BakeryDirectLight[];
                for(int i=0; i<All3.Length; i++)
                {
                    var obj = All3[i] as BakeryDirectLight;
                    if (!obj.enabled) continue;
                    if (!obj.shadowmask && userRenderMode == RenderMode.Shadowmask) continue;
                    var ulht = obj.GetComponent<Light>();
                    if (ulht == null) continue;
                    maskedLightsTemp.Add(AddTempShadowmaskLight(ulht, scene));
                    maskedLightsReal.Add(ulht);
                }
                for(int i=0; i<AllP.Length; i++)
                {
                    var obj = AllP[i] as BakeryPointLight;
                    if (!obj.enabled) continue;
                    if (!obj.shadowmask && userRenderMode == RenderMode.Shadowmask) continue;
                    var ulht = obj.GetComponent<Light>();
                    if (ulht == null) continue;
                    maskedLightsTemp.Add(AddTempShadowmaskLight(ulht, scene));
                    maskedLightsReal.Add(ulht);
                }
            }
            //var tempQuad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            //SceneManager.MoveGameObjectToScene(tempQuad, scene);
            //GameObjectUtility.SetStaticEditorFlags(tempQuad, StaticEditorFlags.LightmapStatic);

#endif

            var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
            var tempScenePath = bakeryRuntimePath + "_tempScene.unity";
            sceneSavedTestScene = scene;
            sceneWasSaved = false;
            EditorSceneManager.sceneSaved += SceneSavedTest;
            var saved = EditorSceneManager.SaveScene(scene, tempScenePath);
            if (!saved)
            {
                hasAnyProbes = false;
                DebugLogError("RenderLightProbes error: can't save temporary scene");
                RestoreSceneManagerSetup(setup);
                yield break;
            }
            while(!sceneWasSaved)
            {
                yield return null;
            }
            EditorSceneManager.sceneSaved -= SceneSavedTest;

#if UNITY_2017_3_OR_NEWER
#else
            if (userRenderMode == RenderMode.Shadowmask || userRenderMode == RenderMode.Subtractive)
            {
                tempID2RealID = new Dictionary<long,long>();
                realID2Channel = new Dictionary<long,int>();
                for(int i=0; i<maskedLightsTemp.Count; i++)
                {
                    var lightTemp = maskedLightsTemp[i];
                    var lightReal = maskedLightsReal[i];
                    if (!GetLightDataForPatching(lightTemp, lightReal, ref tempID2RealID, ref realID2Channel))
                    {
                        hasAnyProbes = false;
                        DebugLogError("RenderLightProbes error: can't get light IDs");
                        RestoreSceneManagerSetup(setup);
                        yield break;
                    }
                }
            }

#endif
            var paths = new string[1];
            paths[0] = tempScenePath;
            Lightmapping.BakeMultipleScenes(paths);
            while(Lightmapping.isRunning) yield return null;

            var lightingDataAsset = Lightmapping.lightingDataAsset;
            if (lightingDataAsset == null)
            {
                hasAnyProbes = false;
                DebugLogError("RenderLightProbes error: lightingDataAsset was not generated");
                RestoreSceneManagerSetup(setup);
                ftLightmaps.RefreshFull();
                yield break;
            }
            lmdataPath = AssetDatabase.GetAssetPath(lightingDataAsset);
            newPath = "Assets/" + outputPath + "/" + assetName + "_probes.asset";

            // Try writing the file. If it's locked, write a copy
            bool locked = false;
            BinaryWriter ftest = null;
            try
            {
                ftest = new BinaryWriter(File.Open(newPath, FileMode.Create));
            }
            catch
            {
                var index = assetName.IndexOf("_copy");
                if (index >= 0)
                {
                    assetName = assetName.Substring(0, index);
                }
                else
                {
                    assetName += "_copy";
                }
                newPath = "Assets/" + outputPath + "/" + assetName + ".asset";
                locked = true;
            }
            if (!locked) ftest.Close();
        }

#if UNITY_2017_3_OR_NEWER
#else
        if (userRenderMode == RenderMode.Shadowmask || userRenderMode == RenderMode.Subtractive)
        {
            if (!useUnityForOcclsusionProbes)
            {
                if (!ftLightingDataGen.PatchShadowmaskLightingData(lmdataPath, newPath, ref tempID2RealID, ref realID2Channel, userRenderMode == RenderMode.Subtractive))
                {
                    try
                    {
                        File.Copy(lmdataPath, newPath, true);
                    }
                    catch
                    {
                        //success = false;
                        Debug.LogError("Failed copying LightingDataAsset");
                    }
                }
            }
        }
        else
        {
#endif
            if (!useUnityForOcclsusionProbes)
            {
            //for(int i=0; i<3; i++)
            //{
                //bool success = true;
                try
                {
                    File.Copy(lmdataPath, newPath, true);
                }
                catch
                {
                    //success = false;
                    Debug.LogError("Failed copying LightingDataAsset");
                }
                //if (success) break;
                //yield return new WaitForSeconds(1);
            //}
            }
#if UNITY_2017_3_OR_NEWER
#else
        }
#endif

        if (!useUnityForOcclsusionProbes)
        {
            AssetDatabase.Refresh();
            newAssetLData = ApplyLightingDataAsset(newPath);
            EditorSceneManager.MarkAllScenesDirty();

            EditorSceneManager.SaveOpenScenes();
            RestoreSceneManagerSetup(setup);

            //var sanityTimeout = GetTime() + 5;
            while( (sceneCount > EditorSceneManager.sceneCount || EditorSceneManager.GetSceneAt(0).path.Length == 0))// && GetTime() < sanityTimeout )
            {
                yield return null;
            }

            LoadRenderSettings(); // prevent curSector reference from unloading
            ftLightmaps.RefreshFull();
        }
    }

    IEnumerator RenderLightProbesFunc()
    {
        int maxThreads = Mathf.Max(2, System.Environment.ProcessorCount * 2);
        DebugLogInfo("Multi-threading to " + maxThreads + " threads.");
        lightProbeRenderSize = 64;
        lightProbeReadSize = 8;
        var proc = InitializeLightProbes(false);
        while (proc.MoveNext()) yield return null;
        if (!hasAnyProbes) yield break;

        var activeScene = EditorSceneManager.GetActiveScene();

        LightingDataAsset newAsset = newAssetLData;
        List<Renderer> dynamicObjects = null;
        GameObject[] go = new GameObject[maxThreads];
        ReflectionProbe[] probe = new ReflectionProbe[maxThreads];
        RenderTexture[] rt = new RenderTexture[maxThreads];
        Material mat = null;
        Texture2D[] tex = new Texture2D[maxThreads];

        Material origSkybox = RenderSettings.skybox;
        Material tempSkybox;
        string ftSkyboxShaderName = "Bakery/Skybox";

        //if (!useUnityForLightProbes)
        {
            // Disable all dynamic objects
            //var objects = UnityEngine.Object.FindObjectsOfTypeAll(typeof(GameObject));
            var objects = Resources.FindObjectsOfTypeAll(typeof(GameObject));
            dynamicObjects = new List<Renderer>();
            var dynAllowMask = forceProbeVisibility.value;
            foreach (GameObject obj in objects)
            {
                if (!obj.activeInHierarchy) continue;
                var path = AssetDatabase.GetAssetPath(obj);
                if (path != "") continue; // must belond to scene
                //if ((obj.hideFlags & (HideFlags.DontSave|HideFlags.HideAndDontSave)) != 0) continue; // skip temp objects
                //if (obj.tag == "EditorOnly") continue; // skip temp objects
                if ((GameObjectUtility.GetStaticEditorFlags(obj) & StaticEditorFlags.LightmapStatic) != 0) continue; // skip static
                var mr = ftBuildGraphics.GetValidRenderer(obj);
                if (mr == null) continue; // must have visible mesh
                if (!mr.enabled) continue; // renderer must be on
                if ((obj.layer & dynAllowMask) != 0) continue; // don't hide renderers with forceProbeVisibility mask
                mr.enabled = false;
                dynamicObjects.Add(mr);
            }

            // Change skybox to first Skylight
            var skyLights = FindObjectsOfType(typeof(BakerySkyLight)) as BakerySkyLight[];
            BakerySkyLight firstSkyLight = null;
            for (int i = 0; i < skyLights.Length; i++)
            {
                if (skyLights[i].enabled)
                {
                    firstSkyLight = skyLights[i];
                    break;
                }
            }

            tempSkybox = new Material(Shader.Find(ftSkyboxShaderName));
            if (firstSkyLight != null)
            {
                tempSkybox.SetTexture("_Tex", firstSkyLight.cubemap as Cubemap);
                tempSkybox.SetFloat("_NoTexture", firstSkyLight.cubemap == null ? 1 : 0);
                tempSkybox.SetFloat("_Hemispherical", firstSkyLight.hemispherical ? 1 : 0);
                tempSkybox.SetFloat("_Exposure", firstSkyLight.intensity);
                tempSkybox.SetColor("_Tint", PlayerSettings.colorSpace == ColorSpace.Linear ? firstSkyLight.color : firstSkyLight.color.linear);
                tempSkybox.SetVector("_MatrixRight", firstSkyLight.transform.right);
                tempSkybox.SetVector("_MatrixUp", firstSkyLight.transform.up);
                tempSkybox.SetVector("_MatrixForward", firstSkyLight.transform.forward);
            }
            else
            {
                tempSkybox.SetFloat("_NoTexture", 1);
                tempSkybox.SetColor("_Tint", Color.black);
            }
            RenderSettings.skybox = tempSkybox;
            yield return null; // atomicjoe 2021 LTS fix?

            for (int i = 0; i < maxThreads; i++)
            {
                go[i] = new GameObject();
                probe[i] = go[i].AddComponent<ReflectionProbe>() as ReflectionProbe;
                probe[i].resolution = lightProbeRenderSize;
                probe[i].hdr = true;
                probe[i].refreshMode = ReflectionProbeRefreshMode.ViaScripting;
                probe[i].timeSlicingMode = ReflectionProbeTimeSlicingMode.NoTimeSlicing;
                probe[i].mode = ReflectionProbeMode.Realtime;
                probe[i].intensity = 0;
                probe[i].nearClipPlane = 0.0001f; // this isn't good but works so far

                rt[i] = new RenderTexture(lightProbeReadSize * 6, lightProbeReadSize, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                tex[i] = new Texture2D(lightProbeReadSize * 6, lightProbeReadSize, TextureFormat.RGBAFloat, false, true);
            }
            if (matCubemapToStrip == null)  matCubemapToStrip = new Material(Shader.Find("Hidden/ftCubemap2Strip"));
            mat = matCubemapToStrip;
        }

        var directions = new Vector3[lightProbeReadSize * lightProbeReadSize];
        var solidAngles = new float[lightProbeReadSize * lightProbeReadSize];
        float readTexelSize = 1.0f / lightProbeReadSize;
        float weightAccum = 0;
        for (int y = 0; y < lightProbeReadSize; y++)
        {
            for (int x = 0; x < lightProbeReadSize; x++)
            {
                float u = (x / (float)(lightProbeReadSize - 1)) * 2 - 1;
                float v = (y / (float)(lightProbeReadSize - 1)) * 2 - 1;
                directions[y * lightProbeReadSize + x] = (new Vector3(u, v, 1.0f)).normalized;


                float x0 = u - readTexelSize;
                float y0 = v - readTexelSize;
                float x1 = u + readTexelSize;
                float y1 = v + readTexelSize;
                float solidAngle = AreaElement(x0, y0) - AreaElement(x0, y1) - AreaElement(x1, y0) + AreaElement(x1, y1);
                weightAccum += solidAngle;
                solidAngles[y * lightProbeReadSize + x] = solidAngle;
            }
        }
        weightAccum *= 6;
        weightAccum *= Mathf.PI;

        var probes = LightmapSettings.lightProbes;
        if (probes == null)
        {
            DebugLogError("RenderLightProbes error: no probes in LightingDataAsset");
            foreach (var d in dynamicObjects) d.enabled = true;
            RenderSettings.skybox = origSkybox;
            //RestoreSceneManagerSetup(setup);
            foreach (GameObject g in go) DestroyImmediate(g);
            //userCanceled = true;
            //ProgressBarEnd();
            bakeInProgress = false;
            yield break;
        }
        SphericalHarmonicsL2[] shs;
        //if (!useUnityForLightProbes)
        {
            shs = new SphericalHarmonicsL2[probes.count];
        }
        //else
        {
            //shs = probes.bakedProbes;
        }

        var positions = probes.positions;

        var directLights = FindObjectsOfType(typeof(BakeryDirectLight)) as BakeryDirectLight[];
        var pointLights = FindObjectsOfType(typeof(BakeryPointLight)) as BakeryPointLight[];

        if (userRenderMode == RenderMode.Indirect || userRenderMode == RenderMode.Shadowmask)
        {
            var filteredDirectLights = new List<BakeryDirectLight>();
            var filteredPointLights = new List<BakeryPointLight>();
            for (int i = 0; i < directLights.Length; i++) if (directLights[i].enabled && directLights[i].bakeToIndirect) filteredDirectLights.Add(directLights[i]);
            for (int i = 0; i < pointLights.Length; i++) if (pointLights[i].enabled && pointLights[i].bakeToIndirect) filteredPointLights.Add(pointLights[i]);
            directLights = filteredDirectLights.ToArray();
            pointLights = filteredPointLights.ToArray();
        }
        else
        {
            var filteredDirectLights = new List<BakeryDirectLight>();
            var filteredPointLights = new List<BakeryPointLight>();
            for (int i = 0; i < directLights.Length; i++) if (directLights[i].enabled) filteredDirectLights.Add(directLights[i]);
            for (int i = 0; i < pointLights.Length; i++) if (pointLights[i].enabled) filteredPointLights.Add(pointLights[i]);
            directLights = filteredDirectLights.ToArray();
            pointLights = filteredPointLights.ToArray();
        }

        bool anyDirectLightToBake = (directLights.Length > 0 || pointLights.Length > 0);// && userRenderMode == RenderMode.FullLighting;
        float[] uvpos = null;
        byte[] uvnormal = null;
        int atlasTexSize = 0;
        List<Vector3>[] dirsPerProbe = new List<Vector3>[probes.count];
        List<Vector3>[] dirColorsPerProbe = new List<Vector3>[probes.count];
        if (anyDirectLightToBake)
        {
            atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)probes.count));
            atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)tileSize) * tileSize;
            uvpos = new float[atlasTexSize * atlasTexSize * 4];
            uvnormal = new byte[atlasTexSize * atlasTexSize * 4];
        }

        userCanceled = false;
        ProgressBarInit("Rendering lightprobes...");
        yield return null;

        ftBuildGraphics.CreateSceneFolder();

        if (anyDirectLightToBake)
        {
            ProgressBarShow("Rendering lightprobes - direct...", 0, true);
            if (userCanceled)
            {
                ProgressBarEnd();
                foreach (GameObject g in go) DestroyImmediate(g);
                foreach (var d in dynamicObjects) d.enabled = true;
                RenderSettings.skybox = origSkybox;
                bakeInProgress = false;
                yield break;
            }

            for (int i = 0; i < probes.count; i++)
            {
                int x = i % atlasTexSize;
                int y = i / atlasTexSize;
                int index = y * atlasTexSize + x;
                uvpos[index * 4] = positions[i].x;
                uvpos[index * 4 + 1] = positions[i].y;
                uvpos[index * 4 + 2] = positions[i].z;
                uvpos[index * 4 + 3] = 1.0f;
                uvnormal[index * 4 + 1] = 255;
                uvnormal[index * 4 + 3] = 255;
            }

            var fpos = new BinaryWriter(File.Open(scenePath + "/uvpos_probes.dds", FileMode.Create));
            fpos.Write(ftDDS.ddsHeaderFloat4);
            var posbytes = new byte[uvpos.Length * 4];
            System.Buffer.BlockCopy(uvpos, 0, posbytes, 0, posbytes.Length);
            fpos.Write(posbytes);
            fpos.BaseStream.Seek(12, SeekOrigin.Begin);
            fpos.Write(atlasTexSize);
            fpos.Write(atlasTexSize);
            fpos.Close();

            var fnorm = new BinaryWriter(File.Open(scenePath + "/uvnormal_probes.dds", FileMode.Create));
            fnorm.Write(ftDDS.ddsHeaderRGBA8);
            fnorm.Write(uvnormal);
            fnorm.BaseStream.Seek(12, SeekOrigin.Begin);
            fnorm.Write(atlasTexSize);
            fnorm.Write(atlasTexSize);
            fnorm.Close();

            if (!ftInitialized)
            {
                ftInitialized = true;
                ftSceneDirty = true;
            }
            if (forceRebuildGeometry)
            {
                ftBuildGraphics.modifyLightmapStorage = false;
                ftBuildGraphics.forceAllAreaLightsSelfshadow = false;
                ftBuildGraphics.validateLightmapStorageImmutability = false;
                var exportSceneFunc = ftBuildGraphics.ExportScene((ftRenderLightmap)EditorWindow.GetWindow(typeof(ftRenderLightmap)), false);
                progressBarEnabled = true;
                while (exportSceneFunc.MoveNext())
                {
                    progressBarText = ftBuildGraphics.progressBarText;
                    progressBarPercent = ftBuildGraphics.progressBarPercent;
                    if (ftBuildGraphics.userCanceled)
                    {
                        ProgressBarEnd();
                        foreach (GameObject g in go) DestroyImmediate(g);
                        foreach (var d in dynamicObjects) d.enabled = true;
                        RenderSettings.skybox = origSkybox;
                        bakeInProgress = false;
                        yield break;
                    }
                    yield return null;
                }
                ftSceneDirty = true;
                if (ftBuildGraphics.userCanceled)
                {
                    userCanceled = ftBuildGraphics.userCanceled;
                    ProgressBarEnd();
                    foreach (GameObject g in go) DestroyImmediate(g);
                    foreach (var d in dynamicObjects)
                    {
                        if (d != null) d.enabled = true;
                    }
                    RenderSettings.skybox = origSkybox;
                    bakeInProgress = false;
                    yield break;
                }
                EditorSceneManager.MarkAllScenesDirty();
            }
            else
            {
                ValidateCurrentScene();
            }

            ftLightmaps.RefreshFull();

            CollectStorages();
            var sceneCount = SceneManager.sceneCount;
            for (int s = 0; s < sceneCount; s++)
            {
                var scene = EditorSceneManager.GetSceneAt(s);
                if (!scene.isLoaded) continue;
                storage = storages[scene];

                // Clear temp data from storage
                storage.uvBuffOffsets = new int[0];
                storage.uvBuffLengths = new int[0];
                storage.uvSrcBuff = new float[0];
                storage.uvDestBuff = new float[0];
                storage.lmrIndicesOffsets = new int[0];
                storage.lmrIndicesLengths = new int[0];
                storage.lmrIndicesBuff = new int[0];

                storage.lmGroupLODResFlags = new int[0];
                storage.lmGroupMinLOD = new int[0];
                storage.lmGroupLODMatrix = new int[0];
            }


            int LMID = 0;
            var flms = new BinaryWriter(File.Open(scenePath + "/lms.bin", FileMode.Create));
            flms.Write("probes");
            flms.Write(atlasTexSize);
            flms.Close();

            var flmlod = new BinaryWriter(File.Open(scenePath + "/lmlod.bin", FileMode.Create));
            flmlod.Write(ftBuildGraphics.sceneLodsUsed > 0 ? 0 : -1);
            flmlod.Close();

            var fsettings = new BinaryWriter(File.Open(scenePath + "/settings.bin", FileMode.Create));
            fsettings.Write(tileSize);
            fsettings.Write(false);
            fsettings.Write(false);
            fsettings.Write(deviceMask);
            fsettings.Close();

            int errCode = 0;
            for (int i = 0; i < directLights.Length; i++)
            {
                ProgressBarShow("Rendering lightprobes - direct...", i / (float)(directLights.Length + pointLights.Length), true);
                if (userCanceled)
                {
                    ProgressBarEnd();
                    foreach (GameObject g in go) DestroyImmediate(g);
                    foreach (var d in dynamicObjects) d.enabled = true;
                    RenderSettings.skybox = origSkybox;
                    bakeInProgress = false;
                    yield break;
                }
                yield return null;

                var light = directLights[i] as BakeryDirectLight;
                ftBuildLights.BuildDirectLight(light, SampleCount(light.samples), true);

                if (exeMode)
                {
                    var startInfo = new System.Diagnostics.ProcessStartInfo();
                    startInfo.Arguments = GetSunRenderMode(light, false) + " " + scenePathQuoted + " probes.dds " + PASS_HALF + " " + 0 + " " + LMID;
                    DebugLogInfo("Running ftrace " + startInfo.Arguments);
#if LAUNCH_VIA_DLL
                    var crt = ProcessCoroutine(ftraceExe, startInfo.Arguments);
                    while (crt.MoveNext())
                    {
                        if (userCanceled)
                        {
                            ProgressBarEnd();
                            foreach (GameObject g in go) DestroyImmediate(g);
                            foreach (var d in dynamicObjects) d.enabled = true;
                            RenderSettings.skybox = origSkybox;
                            bakeInProgress = false;
                            yield break;
                        }
                        yield return null;
                    }
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        foreach (GameObject g in go) DestroyImmediate(g);
                        foreach (var d in dynamicObjects) d.enabled = true;
                        RenderSettings.skybox = origSkybox;
                        bakeInProgress = false;
                        yield break;
                    }
                    errCode = lastReturnValue;
#else
                    startInfo.CreateNoWindow  = false;
                    startInfo.UseShellExecute = false;
                    startInfo.WorkingDirectory = dllPath + "/Bakery";
                    startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                    startInfo.CreateNoWindow = true;
                    var exeProcess = System.Diagnostics.Process.Start(startInfo);
                    exeProcess.WaitForExit();
                    errCode = exeProcess.ExitCode;
#endif
                }

                if (errCode != 0)
                {
                    DebugLogError("ftrace error: " + ftErrorCodes.TranslateFtrace(errCode, rtxMode));
                    userCanceled = true;
                    foreach (GameObject g in go) DestroyImmediate(g);

                    foreach (var d in dynamicObjects) d.enabled = true;
                    RenderSettings.skybox = origSkybox;
                    bakeInProgress = false;
                    yield break;
                }

                var halfs = new ushort[atlasTexSize * atlasTexSize * 4];
                var halfBytes = new byte[halfs.Length * 2];
                var fprobes = new BinaryReader(File.Open(scenePath + "/probes.dds", FileMode.Open, FileAccess.Read));
                fprobes.BaseStream.Seek(128, SeekOrigin.Begin);
                halfBytes = fprobes.ReadBytes(halfBytes.Length);
                System.Buffer.BlockCopy(halfBytes, 0, halfs, 0, halfBytes.Length);
                fprobes.Close();

                var dir = light.transform.forward;
                float cr = 0.0f;
                float cg = 0.0f;
                float cb = 0.0f;
                for (int p = 0; p < probes.count; p++)
                {
                    cr = Mathf.HalfToFloat(halfs[p * 4]);
                    cg = Mathf.HalfToFloat(halfs[p * 4 + 1]);
                    cb = Mathf.HalfToFloat(halfs[p * 4 + 2]);
                    if (cr + cg + cb <= 0) continue;

                    if (dirsPerProbe[p] == null)
                    {
                        dirsPerProbe[p] = new List<Vector3>();
                        dirColorsPerProbe[p] = new List<Vector3>();
                    }
                    dirsPerProbe[p].Add(dir);
                    dirColorsPerProbe[p].Add(new Vector3(cr, cg, cb));
                }
            }

            for (int i = 0; i < pointLights.Length; i++)
            {
                ProgressBarShow("Rendering lightprobes - direct...", (i + directLights.Length) / (float)(directLights.Length + pointLights.Length), true);
                if (userCanceled)
                {
                    ProgressBarEnd();
                    foreach (GameObject g in go) DestroyImmediate(g);
                    foreach (var d in dynamicObjects) d.enabled = true;
                    RenderSettings.skybox = origSkybox;
                    bakeInProgress = false;
                    yield break;
                }
                yield return null;

                var light = pointLights[i] as BakeryPointLight;
                bool isError = ftBuildLights.BuildLight(light, SampleCount(light.samples), true, true); // TODO: dirty tex detection!!
                if (isError)
                {
                    ProgressBarEnd();
                    DebugLogError("BuildLight error");
                    userCanceled = true;
                    foreach (GameObject g in go) DestroyImmediate(g);

                    foreach (var d in dynamicObjects) d.enabled = true;
                    RenderSettings.skybox = origSkybox;
                    bakeInProgress = false;
                    yield break;
                }
                yield return null;

                string renderMode = GetPointLightRenderMode(light);

                if (exeMode)
                {
                    var startInfo = new System.Diagnostics.ProcessStartInfo();
                    startInfo.Arguments = renderMode + " " + scenePathQuoted + " probes.dds " + PASS_HALF + " " + 0 + " " + LMID;
                    DebugLogInfo("Running ftrace " + startInfo.Arguments);
#if LAUNCH_VIA_DLL
                    var crt = ProcessCoroutine(ftraceExe, startInfo.Arguments);
                    while (crt.MoveNext())
                    {
                        if (userCanceled)
                        {
                            ProgressBarEnd();
                            foreach (GameObject g in go) DestroyImmediate(g);
                            foreach (var d in dynamicObjects) d.enabled = true;
                            RenderSettings.skybox = origSkybox;
                            bakeInProgress = false;
                            yield break;
                        }
                        yield return null;
                    }
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        foreach (GameObject g in go) DestroyImmediate(g);
                        foreach (var d in dynamicObjects) d.enabled = true;
                        RenderSettings.skybox = origSkybox;
                        bakeInProgress = false;
                        yield break;
                    }
                    errCode = lastReturnValue;
#else
                    startInfo.CreateNoWindow  = false;
                    startInfo.UseShellExecute = false;
                    startInfo.WorkingDirectory = dllPath + "/Bakery";
                    startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                    startInfo.CreateNoWindow = true;
                    var exeProcess = System.Diagnostics.Process.Start(startInfo);
                    exeProcess.WaitForExit();
                    errCode = exeProcess.ExitCode;
#endif
                }

                if (errCode != 0)
                {
                    ProgressBarEnd();
                    DebugLogError("ftrace error: " + ftErrorCodes.TranslateFtrace(errCode, rtxMode));
                    userCanceled = true;
                    foreach (GameObject g in go) DestroyImmediate(g);

                    foreach (var d in dynamicObjects) d.enabled = true;
                    RenderSettings.skybox = origSkybox;
                    bakeInProgress = false;
                    yield break;
                }

                var halfs = new ushort[atlasTexSize * atlasTexSize * 4];
                var halfBytes = new byte[halfs.Length * 2];
                var fprobes = new BinaryReader(File.Open(scenePath + "/probes.dds", FileMode.Open));
                fprobes.BaseStream.Seek(128, SeekOrigin.Begin);
                halfBytes = fprobes.ReadBytes(halfBytes.Length);
                System.Buffer.BlockCopy(halfBytes, 0, halfs, 0, halfBytes.Length);
                fprobes.Close();

                for (int p = 0; p < probes.count; p++)
                {
                    var dir = (positions[p] - light.transform.position).normalized;

                    float cr = Mathf.HalfToFloat(halfs[p * 4]);
                    float cg = Mathf.HalfToFloat(halfs[p * 4 + 1]);
                    float cb = Mathf.HalfToFloat(halfs[p * 4 + 2]);
                    if (cr + cg + cb <= 0) continue;

                    if (dirsPerProbe[p] == null)
                    {
                        dirsPerProbe[p] = new List<Vector3>();
                        dirColorsPerProbe[p] = new List<Vector3>();
                    }
                    dirsPerProbe[p].Add(dir);
                    dirColorsPerProbe[p].Add(new Vector3(cr, cg, cb));
                }
            }
        }

        //float numPixels = lightProbeReadSize * lightProbeReadSize * 6;

        mat.SetFloat("gammaMode", PlayerSettings.colorSpace == ColorSpace.Linear ? 0 : 1);

        var eventArgs = new ProbeEventArgs();
        System.Threading.Thread[] thread = new System.Threading.Thread[maxThreads];

        int currentThreadsCount = maxThreads;
        int lastThreadsCount;
        for (int i = 0; i < shs.Length + maxThreads; i = i + maxThreads)
        {
            lastThreadsCount = currentThreadsCount;
            currentThreadsCount = Mathf.Min(shs.Length - i, maxThreads);
            if (currentThreadsCount <= 0) {
                if (i>0) for (int th = 0; th < lastThreadsCount; th++) thread[th].Join();
                break;
            }
            for (int ip = 0; ip < currentThreadsCount; ip++)
            {
                probe[ip].transform.position = positions[i + ip];
            }

            if (OnPreRenderProbe != null)
            {
                eventArgs.pos = positions[i];
                OnPreRenderProbe.Invoke(this, eventArgs);
            }

            int[] handle = new int[currentThreadsCount];
            for (int ip = 0; ip < currentThreadsCount; ip++)
            {
                handle[ip] = probe[ip].RenderProbe();
            }
            yield return null;

            for (int ip = 0; ip < currentThreadsCount; ip++)
            {
                while (!probe[ip].IsFinishedRendering(handle[ip]))
                {
                    yield return null;
                }

                var cubemap = probe[ip].texture as RenderTexture;
                Graphics.Blit(cubemap, rt[ip], mat);
                Graphics.SetRenderTarget(rt[ip]);
                tex[ip].ReadPixels(new Rect(0, 0, lightProbeReadSize * 6, lightProbeReadSize), 0, 0, false);
                tex[ip].Apply();
            }



            for (int ip = 0; ip < currentThreadsCount; ip++)
            {
                int ii = i + ip;
                var bytes = tex[ip].GetRawTextureData();
                SphericalHarmonicsL2 sh;
                sh = new SphericalHarmonicsL2();
                sh.Clear();

                if (i > 0) for (int th = 0; th < lastThreadsCount; th++) thread[th].Join();

                thread[ip] = new System.Threading.Thread(() =>
                {
                    float[] basis = new float[9];
                    float[] pixels = new float[bytes.Length / 4];
                    System.Buffer.BlockCopy(bytes, 0, pixels, 0, bytes.Length);

                    var probeDirLights = dirsPerProbe[ii];
                    var probeDirLightColors = dirColorsPerProbe[ii];


                    for (int face = 0; face < 6; face++)
                    {
                        for (int y = 0; y < lightProbeReadSize; y++)
                        {
                            for (int x = 0; x < lightProbeReadSize; x++)
                            {
                                var dir = directions[y * lightProbeReadSize + x];
                                //Vector3 dirL;

                                var solidAngle = solidAngles[y * lightProbeReadSize + x];

                                float stx = x / (float)(lightProbeReadSize - 1);
                                stx = stx * 2 - 1;
                                float sty = y / (float)(lightProbeReadSize - 1);
                                sty = sty * 2 - 1;
                                if (face == 0)
                                {
                                    dir = new Vector3(-1, -sty, stx);
                                }
                                else if (face == 1)
                                {
                                    dir = new Vector3(1, -sty, -stx);
                                }
                                else if (face == 2)
                                {
                                    dir = new Vector3(-sty, -1, -stx);
                                }
                                else if (face == 3)
                                {
                                    dir = new Vector3(-sty, 1, stx);
                                }
                                else if (face == 4)
                                {
                                    dir = new Vector3(-stx, -sty, -1);
                                }
                                else
                                {
                                    dir = new Vector3(stx, -sty, 1);
                                }
                                dir = dir.normalized;

                                float cr = 0.0f;
                                float cg = 0.0f;
                                float cb = 0.0f;
                                int pixelAddr = y * lightProbeReadSize * 6 + x + face * lightProbeReadSize;
                                cr = pixels[pixelAddr * 4];
                                cg = pixels[pixelAddr * 4 + 1];
                                cb = pixels[pixelAddr * 4 + 2];

                                if (cr + cg + cb > 0)
                                {
                                    EvalSHBasis9(dir, ref basis);
                                    for (int b = 0; b < 9; b++)
                                    {
                                        if (b == lightProbeMaxCoeffs) break;

                                        // solidAngle is a weight for texels to account for cube shape of the cubemap (we need sphere)
                                        sh[0, b] += cr * basis[b] * solidAngle;
                                        sh[1, b] += cg * basis[b] * solidAngle;
                                        sh[2, b] += cb * basis[b] * solidAngle;
                                    }
                                }

                            }
                        }
                    }

                    if (probeDirLights != null)
                    {
                        const float norm = 2.9567930857315701067858823529412f;
                        for (int d = 0; d < probeDirLights.Count; d++)
                        {
                            var clr = probeDirLightColors[d];
                            EvalSHBasis9(-probeDirLights[d], ref basis);
                            for (int b = 0; b < 9; b++)
                            {
                                if (b == lightProbeMaxCoeffs) break;
                                sh[0, b] += clr.x * basis[b] * norm;
                                sh[1, b] += clr.y * basis[b] * norm;
                                sh[2, b] += clr.z * basis[b] * norm;
                            }
                        }
                    }

                    shs[ii] = sh;
                });

                thread[ip].IsBackground = true;
                thread[ip].Start();
            }

            ProgressBarShow("Rendering lightprobes - GI...", (i / (float)probes.count), true);
            if (userCanceled)
            {
                ProgressBarEnd();
                foreach (GameObject g in go) DestroyImmediate(g);
                foreach (var d in dynamicObjects) d.enabled = true;
                RenderSettings.skybox = origSkybox;
                bakeInProgress = false;
                yield break;
            }
            yield return null;

        }

        foreach (GameObject g in go) DestroyImmediate(g);
        foreach (var d in dynamicObjects) d.enabled = true;
        RenderSettings.skybox = origSkybox;
        if (newAsset != null) EditorUtility.SetDirty(newAsset);

        probes.bakedProbes = shs;
        EditorUtility.SetDirty(probes);

        SceneManager.SetActiveScene(activeScene);

        if (OnFinishedProbes != null)
        {
            OnFinishedProbes.Invoke(this, null);
        }

        ProgressBarEnd();

        bakeInProgress = false;
        DebugLogInfo("Finished rendering Light Probes.");
        yield break;
    }


    void RenderLightmapUpdate()
    {
        if (!exeMode)
        {
            while(progressFunc.MoveNext()) {}
            EditorApplication.update -= RenderLightmapUpdate;
            bakeInProgress = false;
        }
        else
        {
            if (!progressFunc.MoveNext())
            {
                EditorApplication.update -= RenderLightmapUpdate;
                bakeInProgress = false;
            }
        }
    }

    int SetupLightShadowmaskUsingBitmask(Light ulht, int bitmask, int shadowmaskGroupID, int[] channelBitsPerLayer)
    {
        int foundChannel = -1;
        if (shadowmaskGroupID > 0)
        {
            shadowmaskGroupIDToChannel.TryGetValue(shadowmaskGroupID, out foundChannel);
        }

        if (foundChannel < 0)
        {
            // Find common available channels in affected layers
            const int fourBits = 1|2|4|8;
            int commonFreeBits = 0;
            for(int layer=0; layer<32; layer++)
            {
                if ((bitmask & (1<<layer))!=0) commonFreeBits |= channelBitsPerLayer[layer];
                if (commonFreeBits == fourBits)
                {
                    if (ulht != null)
                    {
                        DebugLogWarning("Light " + ulht.name + " can't generate shadow mask (out of channels).");
                        overlappingLights.Add(ulht.gameObject);
                    }
                    return -1;
                }
            }

            // Get the first available common channel
            int firstFreeBit = -1;
            for(int bit=0; bit<4; bit++)
            {
                if ((commonFreeBits & (1<<bit)) == 0)
                {
                    firstFreeBit = bit;
                    break;
                }
            }

            foundChannel = firstFreeBit;
        }

        // Setup the light
        if (ulht != null)
        {
            if (!SetupLightShadowmask(ulht, foundChannel)) return -1;
        }

        // Mark the channel as unavailable for affected layers
        for(int layer=0; layer<32; layer++)
        {
            if ((bitmask & (1<<layer))!=0)
            {
                channelBitsPerLayer[layer] |= 1<<foundChannel;
            }
        }

        if (shadowmaskGroupID > 0)
        {
            shadowmaskGroupIDToChannel[shadowmaskGroupID] = foundChannel;
        }

        return foundChannel;
    }

    static void CollectStorages()
    {
        var sceneCount = SceneManager.sceneCount;
        storages = new Dictionary<Scene, ftLightmapsStorage>();
        for(int i=0; i<sceneCount; i++)
        {
            var scene = EditorSceneManager.GetSceneAt(i);
            if (!scene.isLoaded) continue;
            SceneManager.SetActiveScene(scene);
            var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
            if (go == null) {
                go = new GameObject();
                go.name = "!ftraceLightmaps";
                go.hideFlags = HideFlags.HideInHierarchy;
            }
            storage = go.GetComponent<ftLightmapsStorage>();
            if (storage == null) {
                storage = go.AddComponent<ftLightmapsStorage>();
            }
            storages[scene] = storage;
        }
    }

    bool CollectGroups(List<BakeryLightmapGroup> groupList, List<BakeryLightmapGroup> groupListGIContributing, bool selected, bool probes=false)
    {
        // 1: Collect
        var sceneCount = SceneManager.sceneCount;
        var groups = new List<BakeryLightmapGroup>();

        // Find explicit LMGroups
        var groupsSelectors = FindObjectsOfType(typeof(BakeryLightmapGroupSelector)) as BakeryLightmapGroupSelector[];
        for(int i=0; i<groupsSelectors.Length; i++)
        {
            var grp = groupsSelectors[i].lmgroupAsset;
            if (grp != null && fullSectorRender && (grp as BakeryLightmapGroup).passedFilter != passedFilterFlag) continue;
            groups.Add(grp as BakeryLightmapGroup);
        }

        // Find implicit LMGroups
        for(int s=0; s<sceneCount; s++)
        {
            var scene = EditorSceneManager.GetSceneAt(s);
            if (!scene.isLoaded) continue;
            for(int i=0; i<storages[scene].implicitGroups.Count; i++)
            {
                var grp = storages[scene].implicitGroups[i] as BakeryLightmapGroup;
                groups.Add(grp);
            }
        }

        if (groups==null || groups.Count==0)
        {
            DebugLogError("Add at least one LMGroup");
            ProgressBarEnd();
            return false;
        }

        // 2: Filter
        groupListPlain = new List<BakeryLightmapGroupPlain>();
        groupListGIContributingPlain = new List<BakeryLightmapGroupPlain>();
        Object[] selObjs = null;
        if (selected)
        {
            // Selected only
            selObjs = Selection.objects;
            if (selObjs.Length == 0)
            {
                DebugLogError("No objects selected");
                ProgressBarEnd();
                return false;
            }
            for(int o=0; o<selObjs.Length; o++)
            {
                if (selObjs[o] as GameObject == null) continue;
                var selGroup = ftBuildGraphics.GetLMGroupFromObject(selObjs[o] as GameObject);
                if (selGroup == null) continue;
                if (!groupList.Contains(selGroup))
                {
                    groupList.Add(selGroup);
                    groupListPlain.Add(selGroup.GetPlainStruct());
                }
            }
            for(int i=0; i<groups.Count; i++)
            {
                var lmgroup = groups[i];
                if (lmgroup == null) continue;
                if (!groupListGIContributing.Contains(lmgroup))
                {
                    var outfile = "Assets/" + outputPathFull + "/"+lmgroup.name+"_final.hdr";
                    bool exists = File.Exists(outfile);
                    if ((!exists && lmgroup.mode != BakeryLightmapGroup.ftLMGroupMode.Vertex) && !groupList.Contains(lmgroup)) continue;
                    groupListGIContributing.Add(lmgroup);
                    groupListGIContributingPlain.Add(lmgroup.GetPlainStruct());
                }
            }
        }
        else if (probes)
        {
            // Probes only
            for(int i=0; i<groups.Count; i++)
            {
                var lmgroup = groups[i];
                if (lmgroup == null) continue;
                if (groupList.Count == 0 && lmgroup.probes)
                {
                    groupList.Add(lmgroup);
                    groupListPlain.Add(lmgroup.GetPlainStruct());
                }
                if (!groupListGIContributing.Contains(lmgroup))
                {
                    var outfile = "Assets/" + outputPathFull + "/"+lmgroup.name;
                    var dirMode = (int)lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroup.renderDirMode;
                    if (dirMode == (int)RenderDirMode.RNM)
                    {
                        outfile += "_RNM0.hdr";
                    }
                    else if (dirMode == (int)RenderDirMode.SH || dirMode == (int)RenderDirMode.MonoSH)
                    {
                        outfile += "_L0.hdr";
                    }
                    else
                    {
                        outfile += "_final.hdr";
                    }
                    bool exists = File.Exists(outfile);
                    if ((!exists && lmgroup.mode != BakeryLightmapGroup.ftLMGroupMode.Vertex) && !groupList.Contains(lmgroup)) continue;
                    groupListGIContributing.Add(lmgroup);
                    groupListGIContributingPlain.Add(lmgroup.GetPlainStruct());
                }
            }
            if (groupList.Count == 0)
            {
                DebugLogError("Add at least one LightProbeGroup (L1)");
                ProgressBarEnd();
                return false;
            }
        }
        else
        {
            // Full render
            for(int i=0; i<groups.Count; i++)
            {
                var lmgroup = groups[i];
                if (lmgroup == null) continue;
                if (!groupList.Contains(lmgroup))
                {
                    groupList.Add(lmgroup);
                    groupListPlain.Add(lmgroup.GetPlainStruct());
                    groupListGIContributing.Add(lmgroup);
                    groupListGIContributingPlain.Add(lmgroup.GetPlainStruct());
                }
            }
        }

        return true;
    }

    bool ValidateSamples()
    {
        int warnCount = 0;
        int warnLimit = 32;
        string warns = "";

        if (giSamples > 64 && bounces > 0)
        {
            var warn = "GI uses more than 64 samples.";
            if (warnCount < warnLimit) warns += warn + "\n";
            DebugLogWarning(warn);
            warnCount++;
        }

        if (hackAOSamples > 64 && hackAOIntensity > 0)
        {
            var warn = "AO uses more than 64 samples.";
            if (warnCount < warnLimit) warns += warn + "\n";
            DebugLogWarning(warn);
            warnCount++;
        }

        for(int i=0; i<All.Length; i++)
        {
            if (All[i].samples2 > 64 && All[i].selfShadow)
            {
                var warn = "Light " + All[i].name + " uses more than 64 near samples.";
                if (warnCount < warnLimit) warns += warn + "\n";
                DebugLogWarning(warn);
                warnCount++;
            }
            if (All[i].samples > 4096)
            {
                var warn = "Light " + All[i].name + " uses more than 4096 far samples.";
                if (warnCount < warnLimit) warns += warn + "\n";
                DebugLogWarning(warn);
                warnCount++;
            }
        }
        for(int i=0; i<AllP.Length; i++)
        {
            if (AllP[i].samples > 4096)
            {
                var warn = "Light " + AllP[i].name + " uses more than 4096 samples.";
                if (warnCount < warnLimit) warns += warn + "\n";
                DebugLogWarning(warn);
                warnCount++;
            }
        }
        for(int i=0; i<All2.Length; i++)
        {
            if (All2[i].samples > 64)
            {
                var warn = "Light " + All2[i].name + " uses more than 64 samples.";
                if (warnCount < warnLimit) warns += warn + "\n";
                DebugLogWarning(warn);
                warnCount++;
            }
        }
        for(int i=0; i<All3.Length; i++)
        {
            if (All3[i].samples > 64)
            {
                var warn = "Light " + All3[i].name + " uses more than 64 samples.";
                if (warnCount < warnLimit) warns += warn + "\n";
                DebugLogWarning(warn);
                warnCount++;
            }
        }
        if (warnCount > 0)
        {
            if (verbose)
            {
                var warnText = "Some sample count values might be out of reasonable range. Extremely high values may cause GPU go out of available resources. This validation can be disabled.\n\n";
                warnText += warns;
                if (warnCount >= warnLimit) warnText += "(See more warnings in console)";
                if (!EditorUtility.DisplayDialog("Bakery", warnText, "Continue", "Cancel"))
                {
                    return false;
                }
            }
            else
            {
                Debug.LogError("Some sample count values might be out of reasonable range");
            }
        }
        return true;
    }

    bool ValidatePrefabs()
    {
        var lmprefabs2 = FindObjectsOfType(typeof(BakeryLightmappedPrefab)) as BakeryLightmappedPrefab[];
        var lmprefabsList = new List<BakeryLightmappedPrefab>();
        int pwarnCount = 0;
        int pwarnLimit = 32;
        string pwarns = "";
        string pwarns2 = "";
        for(int i=0; i<lmprefabs2.Length; i++)
        {
            var p = lmprefabs2[i];
            if (!p.gameObject.activeInHierarchy) continue;
            if (!p.enableBaking) continue;
            if (!p.IsValid())
            {
                //if (prefabWarning)
                {
                    var warn = p.name + ": " + p.errorMessage;
                    if (pwarnCount < pwarnLimit) pwarns += warn + "\n";
                    DebugLogWarning(warn);
                    pwarnCount++;
                }
            }
            else
            {
                lmprefabsList.Add(p);
                //if (prefabWarning)
                {
                    if (pwarnCount < pwarnLimit) pwarns2 += p.name + "\n";
                    pwarnCount++;
                }
            }
        }
        if (pwarnCount > 0)
        {
            string warnText = "";
            if (pwarns2.Length > 0)
            {
                warnText += "These prefabs are going to be overwritten:\n\n" + pwarns2;
            }
            if (pwarns.Length > 0)
            {
                if (pwarns2.Length > 0) warnText += "\n\n";
                warnText += "These prefabs have baking enabled, but NOT going to be overwritten:\n\n" + pwarns;
            }
            if (warnText.Length > 0)
            {
                if (verbose)
                {
                    if (!EditorUtility.DisplayDialog("Bakery", warnText, "Continue", "Cancel"))
                    {
                        return false;
                    }
                }
                else
                {
                    Debug.LogError(warnText);
                }
            }
        }
        return true;
    }

	IEnumerator RenderLightmapFunc()
	{
        // Basic validation
        if (userRenderMode == RenderMode.Indirect && bounces < 1)
        {
            DebugLogError("Can't render indirect lightmaps, if bounces < 1");
            yield break;
        }

        if (userRenderMode == RenderMode.AmbientOcclusionOnly)
        {
            if (hackAOIntensity <= 0 || hackAOSamples <= 0)
            {
                DebugLogError("AO intensity and samples must be > 0 to render AO-only map");
                yield break;
            }

            if (renderDirMode != RenderDirMode.None && renderDirMode != RenderDirMode.DominantDirection && renderDirMode != RenderDirMode.BakedNormalMaps)
            {
                DebugLogError("AO-only mode does not support RNM or SH.");
                yield break;
            }
        }

        if (!exeMode && userRenderMode == RenderMode.Indirect)
        {
            DebugLogError("Selective baked direct lighting is not implemented in DLL mode");
            yield break;
        }

        if (verbose)
        {
            if (!EditorSceneManager.EnsureUntitledSceneHasBeenSaved("Please save all scenes before rendering"))
            {
                yield break;
            }
        }
        else
        {
            EditorSceneManager.SaveOpenScenes();
        }

        // Init probes
        if (lightProbeMode == LightProbeMode.L1 && !selectedOnly && !fullSectorRender)
        {
            var proc = InitializeLightProbes(!probesOnlyL1);
            while(proc.MoveNext()) yield return null;
            if (probesOnlyL1 && !hasAnyProbes) yield break;
        }

        // Alloc new data
        if (clientMode)
        {
            ftClient.serverFileList = new List<string>();
            ftClient.serverGetFileList = new List<string>();
        }

        // Get base scene data
        var activeScene = EditorSceneManager.GetActiveScene();
        var sceneCount = SceneManager.sceneCount;

        All = FindObjectsOfType(typeof(BakeryLightMesh)) as BakeryLightMesh[];
        AllP = FindObjectsOfType(typeof(BakeryPointLight)) as BakeryPointLight[];
        All2 = FindObjectsOfType(typeof(BakerySkyLight)) as BakerySkyLight[];
        All3 = FindObjectsOfType(typeof(BakeryDirectLight)) as BakeryDirectLight[];

        // Scene data validation
        if (samplesWarning)
        {
            if (!ValidateSamples()) yield break;
        }
        if (prefabWarning)
        {
            if (!ValidatePrefabs()) yield break;
        }

        var sectors = FindObjectsOfType(typeof(BakerySector)) as BakerySector[];

        // Unused (yet?)
        if (!ftInitialized)
        {
            ftInitialized = true;
            ftSceneDirty = true;
        }

        // Create output dir
        var outDir = Application.dataPath + "/" + outputPathFull;
        if (!Directory.Exists(outDir)) Directory.CreateDirectory(outDir);

        // Init storages
        storages = new Dictionary<Scene, ftLightmapsStorage>();
        for(int i=0; i<sceneCount; i++)
        {
            var scene = EditorSceneManager.GetSceneAt(i);

#if UNITY_2017_3_OR_NEWER
            bool mustGenerateLightingDataAsset = false;
#else
            bool mustGenerateLightingDataAsset = ((userRenderMode == RenderMode.Shadowmask || userRenderMode == RenderMode.Subtractive) && scene.isDirty);
#endif
            if ((unloadScenesInDeferredMode && deferredMode && scene.isDirty) || mustGenerateLightingDataAsset)
            {
                bool cont = true;
                if (verbose)
                {
                    cont = EditorUtility.DisplayDialog("Bakery", "All open scenes must be saved. Save now?", "OK", "Cancel");
                }
                if (cont)
                {
                    EditorSceneManager.SaveOpenScenes();
                }
                else
                {
                    yield break;
                }
            }

            if (!scene.isLoaded) continue;
            SceneManager.SetActiveScene(scene);
            var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
            if (go == null) {
                go = new GameObject();
                go.name = "!ftraceLightmaps";
                go.hideFlags = HideFlags.HideInHierarchy;
            }
            storage = go.GetComponent<ftLightmapsStorage>();
            if (storage == null) {
                storage = go.AddComponent<ftLightmapsStorage>();
            }

            // delete unused sectors from storages
            var stSectors = storage.sectors;
            if (stSectors == null) stSectors = storage.sectors = new List<ftLightmapsStorage.SectorData>();

            var newStSectors = new List<ftLightmapsStorage.SectorData>();
            ftLightmapsStorage.SectorData globalSector = null;
            for(int st=0; st<stSectors.Count; st++)
            {
                var stSectorName = stSectors[st].name;
                bool isGlobalSector = stSectorName == "$G";
                if (isGlobalSector) globalSector = stSectors[st];
                bool add = false;
                if (!isGlobalSector)
                {
                    for(int j=0; j<sectors.Length; j++)
                    {
                        if (sectors[j].name == stSectorName)
                        {
                            add = true;
                            break;
                        }
                    }
                }
                if (add) newStSectors.Add(stSectors[st]);
            }
            if (globalSector == null)
            {
                globalSector = new ftLightmapsStorage.SectorData();
                globalSector.name = "$G";
            }
            newStSectors.Insert(0, globalSector);

            // Cache global bake data as sector for merging
            globalSector.maps = storage.maps;
            globalSector.masks = storage.masks;
            globalSector.dirMaps = storage.dirMaps;
            globalSector.rnmMaps0 = storage.rnmMaps0;
            globalSector.rnmMaps1 = storage.rnmMaps1;
            globalSector.rnmMaps2 = storage.rnmMaps2;
            globalSector.mapsMode = storage.mapsMode;
            globalSector.bakedRenderers = storage.bakedRenderers;
#if USE_TERRAINS
            globalSector.bakedRenderersTerrain = storage.bakedRenderersTerrain;
            globalSector.bakedIDsTerrain = storage.bakedIDsTerrain;
            globalSector.bakedScaleOffsetTerrain = storage.bakedScaleOffsetTerrain;
#endif
            globalSector.bakedIDs = storage.bakedIDs;
            globalSector.bakedScaleOffset = storage.bakedScaleOffset;
            globalSector.bakedVertexColorMesh = storage.bakedVertexColorMesh;
            globalSector.nonBakedRenderers = storage.nonBakedRenderers;

            storage.sectors = newStSectors;

            if (lightProbeMode == LightProbeMode.L1 && !selectedOnly && !fullSectorRender) restoreFromGlobalSector = true;

            storage.maps = new List<Texture2D>();
            storage.masks = new List<Texture2D>();
            storage.dirMaps = new List<Texture2D>();
            storage.rnmMaps0 = new List<Texture2D>();
            storage.rnmMaps1 = new List<Texture2D>();
            storage.rnmMaps2 = new List<Texture2D>();
            storage.mapsMode = new List<int>();
            storage.bakedLights = new List<Light>();
            storage.bakedLightChannels = new List<int>();
            storage.compressedVolumes = false;
            storage.anyVolumes = false;

            //if (forceRefresh) // removed condition to make "Export" option work in isolation
            {
                storage.serverGetFileList = new List<string>();
                storage.lightmapHasColor = new List<bool>();
                storage.lightmapHasMask = new List<int>();
                storage.lightmapHasDir = new List<bool>();
                storage.lightmapHasRNM = new List<bool>();
            }

            storage.Init(forceRefresh);

            //ftBuildGraphics.storage = storage;
            storages[scene] = storage;
        }
        SceneManager.SetActiveScene(activeScene);

        // Prepare realtime GI if needed
        if (usesRealtimeGI && !probesOnlyL1)
        {
            var store = storages[activeScene];
#if UNITY_2017_2_OR_NEWER
            if (LightmapEditorSettings.lightmapper != BUILTIN_RADIOSITY)
            {
                if (verbose)
                {
                    EditorUtility.DisplayDialog("Bakery", "'Combine with Enlighten real-time GI' is enabled, but Unity lightmapper is not set to Enlighten. Please go to Lighting settings and select it.", "OK");
                    yield break;
                }
                else
                {
                    Debug.LogError("'Combine with Enlighten real-time GI' is enabled, but Unity lightmapper is not set to Enlighten");
                }
            }
#else
            if (!store.enlightenWarningShown2)
            {
                if (verbose)
                {
                    if (!EditorUtility.DisplayDialog("Bakery", "'Combine with Enlighten real-time GI' is enabled. Make sure Unity lightmapper is set to Enlighten in the Lighting window.", "I'm sure", "Cancel"))
                    {
                        yield break;
                    }
                    store.enlightenWarningShown2 = true;
                    EditorUtility.SetDirty(store);
                }
                else
                {
                    Debug.LogError("'Combine with Enlighten real-time GI' is enabled, but Unity lightmapper is not set to Enlighten");
                }
            }
#endif

            reflectionProbes = new List<ReflectionProbe>();

            //Disable Refl probes, and Baked GI so all that we bake is Realtime GI
            Lightmapping.bakedGI = false;
            Lightmapping.realtimeGI = true;
            FindAllReflectionProbesAndDisable();

            //Bake to get the Realtime GI maps
            //Lightmapping.Bake();

            Lightmapping.BakeAsync();
            ProgressBarInit("Waiting for Enlighten...");
            while(Lightmapping.isRunning)
            {
                userCanceled = simpleProgressBarCancelled();
                if (userCanceled)
                {
                    Lightmapping.Cancel();
                    ProgressBarEnd();
                    break;
                }
                yield return null;
            }
            ProgressBarEnd();

            //Re enable probes before bakery bakes, and bakedGI
            Lightmapping.bakedGI = true;
            ReEnableReflectionProbes();
        }

        // Export scene
        if (forceRebuildGeometry)
        {
            passedFilterFlag++;

            renderSettingsStorage = FindRenderSettingsStorage();
            SaveRenderSettings();

            ftBuildGraphics.overwriteWarningSelectedOnly = selectedOnly;
            ftBuildGraphics.modifyLightmapStorage = true;
            ftBuildGraphics.forceAllAreaLightsSelfshadow = false;
            ftBuildGraphics.validateLightmapStorageImmutability = selectedOnly || probesOnlyL1;
            ftBuildGraphics.sceneNeedsToBeRebuilt = false;
            var exportSceneFunc = ftBuildGraphics.ExportScene((ftRenderLightmap)EditorWindow.GetWindow(typeof(ftRenderLightmap)), true);
            progressBarEnabled = true;

            var estartMs = GetTimeMs();
            while(exportSceneFunc.MoveNext())
            {
                progressBarText = ftBuildGraphics.progressBarText;
                progressBarPercent = ftBuildGraphics.progressBarPercent;
                if (ftBuildGraphics.userCanceled)
                {
                    ftBuildGraphics.ProgressBarEnd(true);
                    ProgressBarEnd();
                    yield break;
                }
                yield return null;
            }

            if (ftBuildGraphics.sceneNeedsToBeRebuilt)
            {
                ftBuildGraphics.ProgressBarEnd(true);
                DebugLogError("Scene geometry/layout changed since last full bake. Use Render button instead.");
                yield break;
            }

            var ems = GetTimeMs();
            double exportTime = (ems - estartMs) / 1000.0;
            DebugLogInfo("Scene export time: " + exportTime);

            userCanceled = ftBuildGraphics.userCanceled;
            ProgressBarEnd(false);
            ftSceneDirty = true;
            if (ftBuildGraphics.userCanceled) yield break;
            SaveRenderSettings();
            EditorSceneManager.MarkAllScenesDirty();
        }
        else
        {
            if (!ValidateCurrentScene())
            {
                ProgressBarEnd();
                yield break;
            }
        }

        lmnameComposed = new Dictionary<string, bool>();

        uvBuffOffsets = storage.uvBuffOffsets;
        uvBuffLengths = storage.uvBuffLengths;
        uvSrcBuff = storage.uvSrcBuff;
        uvDestBuff = storage.uvDestBuff;
        lmrIndicesOffsets = storage.lmrIndicesOffsets;
        lmrIndicesLengths = storage.lmrIndicesLengths;
        lmrIndicesBuff = storage.lmrIndicesBuff;
        lmGroupMinLOD = storage.lmGroupMinLOD;
        lmGroupLODResFlags = storage.lmGroupLODResFlags;
        lmGroupLODMatrix = storage.lmGroupLODMatrix;

        userCanceled = false;
        ProgressBarInit("Rendering lightmaps - preparing...");
        yield return null;

        Debug.Log("Start");

        var groupList = new List<BakeryLightmapGroup>();
        var groupListGIContributing = new List<BakeryLightmapGroup>();
        if (!CollectGroups(groupList, groupListGIContributing, selectedOnly, probesOnlyL1)) yield break;

        // Prepare rendering lightmaps
        var startMs = GetTimeMs();

        var fsettings = new BinaryWriter(File.Open(scenePath + "/settings.bin", FileMode.Create));
        fsettings.Write(tileSize);
        fsettings.Write(compressedGBuffer);
        fsettings.Write(compressedOutput);
        fsettings.Write(deviceMask);
        fsettings.Close();

        if (clientMode) ftClient.serverFileList.Add("settings.bin");

        progressSteps = groupList.Count * (All.Length + AllP.Length + All2.Length + All3.Length) + // direct
                            1 + // compositing
                            bounces * groupList.Count + // GI
                            groupList.Count * 3; // denoise + fixSeams + encode
        progressStepsDone = 0;

        if (deferredMode)
        {
            deferredCommands = new List<System.Diagnostics.ProcessStartInfo>();
            deferredCommandsFallback = new Dictionary<int, List<string>>();
            deferredCommandsRebake = new Dictionary<int, BakeryLightmapGroupPlain>();
            deferredCommandsLODGen = new Dictionary<int, int>();
            deferredCommandsGIGen = new Dictionary<int, Vector3>();
            deferredCommandsHalf2VB = new Dictionary<int, BakeryLightmapGroupPlain>();
            deferredCommandsUVGB = new Dictionary<int, bool>();
            deferredFileSrc = new List<string>();
            deferredFileDest = new List<string>();
            deferredCommandDesc = new List<string>();
        }

        //if (forceRefresh) // removed condition to make "Export" option work in isolation
        {
            lightmapMasks = new List<List<List<string>>>();
            lightmapMaskLMNames = new List<List<List<string>>>();
            lightmapMaskLights = new List<List<List<Light>>>();
            lightmapMaskDenoise = new List<List<List<bool>>>();
    #if UNITY_2017_3_OR_NEWER
    #else
            maskedLights = new List<Light>();
    #endif
            lightmapHasColor = new List<bool>();
            lightmapHasMask = new List<int>();
            lightmapHasDir = new List<bool>();
            lightmapHasRNM = new List<bool>();

            foreach(var lmgroup in groupListGIContributingPlain)
            {
                var rmode = lmgroup.renderMode == (int)BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)lmgroup.renderMode;
                var dirMode = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroup.renderDirMode;
                var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection;
                while(lightmapMasks.Count <= lmgroup.id)
                {
                    lightmapMasks.Add(new List<List<string>>());
                    lightmapMaskLMNames.Add(new List<List<string>>());
                    lightmapMaskLights.Add(new List<List<Light>>());
                    lightmapMaskDenoise.Add(new List<List<bool>>());
                    lightmapHasColor.Add(true);
                    lightmapHasMask.Add(rmode == (int)RenderMode.Shadowmask ? 3 : 0);
                    lightmapHasDir.Add(dominantDirMode);
                    lightmapHasRNM.Add(false);
                }
            }
        }

        // Fix starting ray positions
        if (forceRebuildGeometry)
        {
            if (ftBuildGraphics.exportShaderColors)
            {
                deferredFileSrc.Add("");
                deferredFileDest.Add("");
                deferredCommands.Add(null);
                deferredCommandDesc.Add("Exporting scene - generating UV GBuffer...");
                deferredCommandsUVGB[deferredCommands.Count - 1] = true;
            }

            foreach(var lmgroup in groupList)
            {
                var nm = lmgroup.name;
                int LMID = lmgroup.id;
                if (lmgroup.mode != BakeryLightmapGroup.ftLMGroupMode.Vertex || lmgroup.fixPos3D) // skip vertex colored
                {
                    if (!adjustSamples) continue;

                    if (!pstorage.generateSmoothPos)
                    {
                        // further passes still require smooth pos, copy from pos
                        deferredFileSrc.Add(scenePath + "/uvpos_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                        deferredFileDest.Add(scenePath + "/uvsmoothpos_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                        deferredCommands.Add(null);
                        deferredCommandDesc.Add("Adjusting sample points for " + nm + " (2)...");
                    }

                    var startInfo = new System.Diagnostics.ProcessStartInfo();
                    startInfo.CreateNoWindow  = false;
                    startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                    startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                    startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                    startInfo.CreateNoWindow = true;
                    int fixPosPasses = PASS_FLOAT;
                    if (lmgroup.fixPos3D)
                    {
                        var mfilename = "fixPos3D_" + LMID + ".bin";
                        var mf = new BinaryWriter(File.Open(scenePath + "/" + mfilename, FileMode.Create));
                        mf.Write(lmgroup.voxelSize.x);
                        mf.Write(lmgroup.voxelSize.y);
                        mf.Write(lmgroup.voxelSize.z);
                        mf.Close();
                        startInfo.Arguments       = "fixpos3D " + scenePathQuoted + " \"" + "uvpos_" + nm +(compressedGBuffer ? ".lz4" : ".dds") + "\" " + fixPosPasses + " " + 0 + " " + LMID + " " + mfilename;
                        if (clientMode) ftClient.serverFileList.Add(mfilename);
                    }
                    else
                    {
                        startInfo.Arguments       = (pstorage.perTriangleSmoothPos ? "fixpos12 " : "fixpos12_notrimark ") + scenePathQuoted + " \"" + "uvpos_" + nm +(compressedGBuffer ? ".lz4" : ".dds") + "\" " + fixPosPasses + " " + 0 + " " + LMID + " " + Float2String(lmgroup.fakeShadowBias);
                    }

                    deferredFileSrc.Add("");
                    deferredFileDest.Add("");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add("Adjusting sample points for " + nm + "...");
                }
            }
        }
        else
        {
            ValidateCurrentScene();
        }

        // Render AO if needed
        if (hackAOIntensity > 0 && hackAOSamples > 0)
        {
            foreach(var lmgroup in groupList)
            {
                var nm = lmgroup.name;
                currentGroup = lmgroup;
                bool doRender = true;

                if (doRender) {
                    DebugLogInfo("Preparing AO " + nm + " (" + (lmgroup.id+1) + "/" + groupList.Count + ")");

                    progressStepsDone++;
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;

                    if (lmgroup.probes) continue;
                    if (!RenderLMAO(lmgroup.id, nm))
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                }
            }
        }

        // Mark completely baked lights
        for(int i=0; i<All3.Length; i++)
        {
            var obj = All3[i] as BakeryDirectLight;
            if (!obj.enabled) continue;
            var ulht = obj.GetComponent<Light>();
            if (ulht == null) continue;
            if (IsLightCompletelyBaked(obj.bakeToIndirect, obj.shadowmask, userRenderMode))
            {
                MarkLightAsCompletelyBaked(ulht);
            }
            else if (IsLightSubtractive(obj.bakeToIndirect, userRenderMode))
            {
                MarkLightAsSubtractive(ulht);
            }
            else if (IsLightRealtime(obj.bakeToIndirect, userRenderMode))
            {
                MarkLightAsRealtime(ulht);
            }
        }
        for(int i=0; i<AllP.Length; i++)
        {
            var obj = AllP[i] as BakeryPointLight;
            if (!obj.enabled) continue;
            var ulht = obj.GetComponent<Light>();
            //if (ulht == null) continue;
            if (IsLightCompletelyBaked(obj.bakeToIndirect, obj.shadowmask, userRenderMode))
            {
                if (ulht != null) MarkLightAsCompletelyBaked(ulht);
                obj.maskChannel = -1;
            }
            else if (IsLightSubtractive(obj.bakeToIndirect, userRenderMode))
            {
                if (ulht != null) MarkLightAsSubtractive(ulht);
                obj.maskChannel = -1;
            }
            else if (IsLightRealtime(obj.bakeToIndirect, userRenderMode))
            {
                if (ulht != null) MarkLightAsRealtime(ulht);
                obj.maskChannel = -1;
            }
        }
        for(int i=0; i<All.Length; i++)
        {
            var obj = All[i] as BakeryLightMesh;
            if (!obj.enabled) continue;
            var ulht = obj.GetComponent<Light>();
            if (ulht == null) continue;
            if (IsLightCompletelyBaked(obj.bakeToIndirect, obj.shadowmask, userRenderMode))
            {
                MarkLightAsCompletelyBaked(ulht);
            }
            else if (IsLightSubtractive(obj.bakeToIndirect, userRenderMode))
            {
                MarkLightAsSubtractive(ulht);
            }
            else if (IsLightRealtime(obj.bakeToIndirect, userRenderMode))
            {
                MarkLightAsRealtime(ulht);
            }
        }

        // Find intersecting light groups for shadowmask
        bool someLightsCantBeMasked = false;
        shadowmaskGroupIDToChannel = new Dictionary<int, int>();
        if (userRenderMode == RenderMode.Shadowmask)
        {
            overlappingLights = new List<GameObject>();

            //int channel = 0;
            var channelBitsPerLayer = new int[32];

            for(int i=0; i<All3.Length; i++)
            {
                var obj = All3[i] as BakeryDirectLight;
                if (!obj.enabled) continue;
                if (!obj.shadowmask) continue;
                var ulht = obj.GetComponent<Light>();
                if (ulht == null) continue;
                if (SetupLightShadowmaskUsingBitmask(ulht, obj.bitmask, 0, channelBitsPerLayer) < 0) someLightsCantBeMasked = true;
            }

            var lightsRemaining = new List<Light>();
            var lightsRemainingB = new List<LightBounds>();
            var lightChannels = new List<int>();
            var lightArrayIndices = new List<int>();
            var lightIntersections = new List<int>();
            for(int i=0; i<AllP.Length; i++)
            {
                var obj = AllP[i] as BakeryPointLight;
                if (!obj.enabled) continue;
                if (!obj.shadowmask) continue;
                var ulht = obj.GetComponent<Light>();
                if (ulht == null)
                {
                    if (!(obj.shadowmask && obj.bakeToIndirect)) continue; // when set to mask/direct/indirect, add null as light
                }
                lightsRemaining.Add(ulht);
                lightsRemainingB.Add(new LightBounds(obj));
                lightChannels.Add(-1);
                lightArrayIndices.Add(lightArrayIndices.Count);
                lightIntersections.Add(0);
            }
            for(int i=0; i<All.Length; i++)
            {
                var obj = All[i] as BakeryLightMesh;
                if (!obj.enabled) continue;
                if (!obj.shadowmask) continue;
                var ulht = obj.GetComponent<Light>();
                if (ulht == null) continue;
                lightsRemaining.Add(ulht);
                lightsRemainingB.Add(new LightBounds(obj));
                lightChannels.Add(-1);
                lightArrayIndices.Add(lightArrayIndices.Count);
                lightIntersections.Add(0);
            }

            // Sort by the intersection count
            for(int i=0; i<lightsRemaining.Count; i++)
            {
                lightIntersections[i] = 0;
                var la = lightsRemaining[i];
                var laRange = lightsRemainingB[i].cutoff;// * 2;
                //var laBounds = new Bounds(la.transform.position, new Vector3(laRange, laRange, laRange));
                var laPos = lightsRemainingB[i].center;// la.transform.position
                var laBitmask = lightsRemainingB[i].bitmask;
                for(int j=0; j<lightsRemaining.Count; j++)
                {
                    if (i == j) continue;
                    var lb = lightsRemaining[j];
                    var lbRange = lightsRemainingB[j].cutoff;// * 2;
                    var lbPos = lightsRemainingB[j].center;// lb.transform.position;
                    var lbBitmask = lightsRemainingB[j].bitmask;
                    if ((laBitmask & lbBitmask) == 0) continue;
                    if ((lbPos - laPos).sqrMagnitude < (laRange+lbRange)*(laRange+lbRange)) lightIntersections[i]++;
                    //var lbBounds = new Bounds(lb.transform.position, new Vector3(lbRange, lbRange, lbRange));
                    //if (laBounds.Intersects(lbBounds)) lightIntersections[i]++;
                }
            }
            lightArrayIndices.Sort(delegate(int a, int b)
            {
                return lightIntersections[b].CompareTo( lightIntersections[a] );
            });

            for(int i=0; i<lightsRemaining.Count; i++)
            {
                int idA = lightArrayIndices[i];
                if (lightChannels[idA] != -1) continue;

                var la = lightsRemaining[idA];
                var laRange = lightsRemainingB[idA].cutoff;// * 2;
                var laPos = lightsRemainingB[idA].center;//la.transform.position;
                //var laBounds = new Bounds(la.transform.position, new Vector3(laRange, laRange, laRange));
                var laBitmask = lightsRemainingB[idA].bitmask;

                var channelBoundsTypeAndOffset = new List<int>(); // sign is type, offset is to relevant array (+1)
                // Spherical
                var channelBoundsPos = new List<Vector3>();
                var channelBoundsRadius = new List<float>();
                // Convex
                var channelBoundsConvex = new List<Convex>();

                if (la != null && la.type == LightType.Spot)
                {
                    // Add spot geometry as pyramid
                    channelBoundsTypeAndOffset.Add(-(channelBoundsConvex.Count+1));
                    channelBoundsConvex.Add(GetSpotConvex(la.transform, la.spotAngle, la.range));
                }
                else
                {
                    // Add point geometry as sphere
                    channelBoundsTypeAndOffset.Add(channelBoundsPos.Count+1);
                    channelBoundsPos.Add(laPos);
                    channelBoundsRadius.Add(laRange);
                }

                //channelBoundsPos.Add(laPos);
                //channelBoundsRadius.Add(laRange);

                int channelSet = SetupLightShadowmaskUsingBitmask(la, laBitmask, lightsRemainingB[idA].shadowmaskGroupID, channelBitsPerLayer);
                if (channelSet < 0) someLightsCantBeMasked = true;
                if (lightsRemainingB[idA].point != null) lightsRemainingB[idA].point.maskChannel = channelSet;

                lightChannels[idA] = channelSet;
                if (la != null) DebugLogInfo("* Light " + la.name + " set to channel " + channelSet);
                //SetupLightShadowmask(la, channel);

                // Find all non-overlapping
                //for(int j=i+1; j<lightsRemaining.Count; j++)
                for(int j=0; j<lightsRemaining.Count; j++)
                {
                    int idB = lightArrayIndices[j];
                    if (lightChannels[idB] != -1) continue;
                    var lbBitmask = lightsRemainingB[idB].bitmask;
                    if ((laBitmask & lbBitmask) == 0) continue;
                    var lb = lightsRemaining[idB];
                    var lbRange = lightsRemainingB[idB].cutoff;// * 2;
                    //var lbBounds = new Bounds(lb.transform.position, new Vector3(lbRange, lbRange, lbRange));
                    var lbPos = lightsRemainingB[idB].center;// lbT.position;
                    Convex lbConvex = null;
                    var lbType = LightType.Point;
                    if (lb != null)
                    {
                        lbType = lb.type;
                        var lbT = lb.transform;
                        if (lb.type == LightType.Spot) lbConvex = GetSpotConvex(lbT, lb.spotAngle, lb.range);
                    }

                    bool intersects = false;
                    int boffset;
                    for(int k=0; k<channelBoundsTypeAndOffset.Count; k++)
                    {
                        boffset = channelBoundsTypeAndOffset[k];
                        LightType ctype = LightType.Point;
                        if (boffset < 0)
                        {
                            boffset = -boffset;
                            ctype = LightType.Spot;
                        }
                        boffset--;

                        if (lbType == LightType.Point && ctype == LightType.Point)
                        {
                            // sphere vs sphere
                            //if (channelBounds[k].Intersects(lbBounds))
                            float dist = channelBoundsRadius[boffset] + lbRange;
                            if ((channelBoundsPos[boffset] - lbPos).sqrMagnitude < dist*dist)
                            {
                                intersects = true;
                                break;
                            }
                        }
                        else if (lbType == LightType.Spot && ctype == LightType.Spot)
                        {
                            // convex vs convex
                            //Debug.Log("testing " + lb.name+" with "+channelBoundsConvex[boffset].vertices[0]);
                            if (ConvexIntersect(lbConvex, channelBoundsConvex[boffset]))
                            {
                                //Debug.LogError(lb.name+" intersects with "+channelBoundsConvex[boffset].vertices[0]);
                                intersects = true;
                                break;
                            }
                        }
                        else if (lbType == LightType.Spot && ctype == LightType.Point)
                        {
                            // convex vs sphere
                            if (ConvexSphereIntersect(lbConvex, channelBoundsPos[boffset], channelBoundsRadius[boffset]))
                            {
                                intersects = true;
                                break;
                            }
                        }
                        else if (lbType == LightType.Point && ctype == LightType.Spot)
                        {
                            // sphere vs convex
                            if (ConvexSphereIntersect(channelBoundsConvex[boffset], lbPos, lbRange))
                            {
                                intersects = true;
                                break;
                            }
                        }
                    }
                    if (intersects) continue;

                    if (lbType == LightType.Spot)
                    {
                        channelBoundsTypeAndOffset.Add(-(channelBoundsConvex.Count+1));
                        channelBoundsConvex.Add(lbConvex);
                    }
                    else
                    {
                        // Add point geometry as sphere
                        channelBoundsTypeAndOffset.Add(channelBoundsPos.Count+1);
                        channelBoundsPos.Add(lbPos);
                        channelBoundsRadius.Add(lbRange);
                    }
                    //channelBounds.Add(lbBounds);
                    lightChannels[idB] = channelSet;
                    if (lb != null)
                    {
                        DebugLogInfo("Light " + lb.name + " set to channel " + channelSet);
                        if (!SetupLightShadowmask(lb, channelSet)) someLightsCantBeMasked = true;
                    }
                    if (lightsRemainingB[idB].point != null) lightsRemainingB[idB].point.maskChannel = channelSet;
                }

                //channel++;
            }
        }

        if (ftAdditionalConfig.batchPointLights)
        {
            System.Array.Sort(AllP, ComparePointLights);
        }

        if (someLightsCantBeMasked)
        {
            ProgressBarEnd();
            if (verbose)
            {
                int ch = EditorUtility.DisplayDialogComplex("Bakery", "Some shadow masks can't be baked due to more than 4 masked lights overlapping. See console warnings for details. Press 'Stop and select' to select overlapping lights.", "Continue anyway", "Stop", "Stop and select");
                if (ch > 0)
                {
                    if (ch == 2)
                    {
                        Selection.objects = overlappingLights.ToArray();
                    }
                    yield break;
                }
            }
            else
            {
                Debug.LogError("Some shadow masks can't be baked due to more than 4 masked lights overlapping");
            }
        }

        // Render directional lighting for every lightmap
        ftBuildLights.InitMaps(false);
        foreach(var lmgroup in groupList)
        {
            var nm = lmgroup.name;
            currentGroup = lmgroup;
            bool doRender = true;

            if (doRender) {
                DebugLogInfo("Preparing (direct) lightmap " + nm + " (" + (lmgroup.id+1) + "/" + groupList.Count + ")");

                progressStepsDone++;
                if (userCanceled)
                {
                    ProgressBarEnd();
                    yield break;
                }
                yield return null;

                var routine = RenderLMDirect(lmgroup.id, nm, lmgroup.resolution);
                while(routine.MoveNext())
                {
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;
                }
            }
        }

        // Save rendered light properties
        for(int i=0; i<All.Length; i++)
        {
            var obj = All[i] as BakeryLightMesh;
            if (!obj.enabled) continue;
            //if ((obj.bitmask & currentGroup.bitmask) == 0) continue;
            StoreLight(obj);
        }
        for(int i=0; i<AllP.Length; i++)
        {
            var obj = AllP[i] as BakeryPointLight;
            if (!obj.enabled) continue;
            //if ((obj.bitmask & currentGroup.bitmask) == 0) continue;
            StoreLight(obj);
        }
        for(int i=0; i<All2.Length; i++)
        {
            var obj = All2[i] as BakerySkyLight;
            if (!obj.enabled) continue;
            //if ((obj.bitmask & currentGroup.bitmask) == 0) continue;
            StoreLight(obj);
        }
        for(int i=0; i<All3.Length; i++)
        {
            var obj = All3[i] as BakeryDirectLight;
            if (!obj.enabled) continue;
            //if ((obj.bitmask & currentGroup.bitmask) == 0) continue;
            StoreLight(obj);
        }

        foreach(var lmgroup in groupList)
        {
            // Optionally compute SSS after direct lighting
            if (!lmgroup.computeSSS) continue;
            RenderLMSSS(lmgroup, bounces == 0, true);
        }

        // Render GI for every lightmap
        for(int i=0; i<bounces; i++)
        {
            foreach(var lmgroup in groupList)
            {
                var nm = lmgroup.name;
                currentGroup = lmgroup;
                bool doRender = true;

                if (doRender) {
                    DebugLogInfo("Preparing (bounce " + i + ") lightmap " + nm + " (" + (lmgroup.id+1) + "/" + groupList.Count + ")");

                    progressStepsDone++;
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;

                    var rmode = lmgroup.renderMode == BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)lmgroup.renderMode;

                    if (rmode == (int)RenderMode.AmbientOcclusionOnly) continue;

                    bool lastPass = i == bounces - 1;
                    bool needsGIPass = (lastPass && (rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask));

                    var dirMode = lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroup.renderDirMode;
                    var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection && lightmapHasDir[lmgroup.id];

                    if (lmgroup.probes && !lastPass) continue; // probes only need final GI pass

                    if (performRendering)
                    {
                        deferredFileSrc.Add("");
                        deferredFileDest.Add("");
                        deferredCommands.Add(null);
                        deferredCommandDesc.Add("Generating GI parameters for " + lmgroup.name + "...");
                        deferredCommandsGIGen[deferredCommands.Count - 1] = new Vector3(lmgroup.id, i, dominantDirMode?1:0);

                        if (!RenderLMGI(lmgroup.id, nm, i, needsGIPass, lastPass))
                        {
                            ProgressBarEnd();
                            yield break;
                        }

                        // Optionally compute SSS after bounce
                        if (!lmgroup.computeSSS) continue;
                        RenderLMSSS(lmgroup, i == bounces - 1, false);
                    }
                }
            }
        }

        // Add directional contribution from selected lights to indirect
        //if ((userRenderMode == RenderMode.Indirect || userRenderMode == RenderMode.Shadowmask)  && performRendering)
        {
            //Debug.Log("Compositing bakeToIndirect lights with GI...");
            foreach(var lmgroup in groupListPlain)
            {
                string nm = lmgroup.name;
                try
                {
                    nm = lmgroup.name;
                }
                catch
                {
                    DebugLogError("Error postprocessing lightmaps. See console for details");
                    ProgressBarEnd();
                    throw;
                }

                var rmode = lmgroup.renderMode == (int)BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)lmgroup.renderMode;
                if ((rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask) && performRendering)
                {
                    //int errCode2 = 0;
                    if (exeMode)
                    {
                        var startInfo = new System.Diagnostics.ProcessStartInfo();
                        startInfo.CreateNoWindow  = false;
                        startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                        startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                        startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                        startInfo.CreateNoWindow = true;
                        startInfo.Arguments       =  "add " + scenePathQuoted + " \"" + nm + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds")
                        + "\"" + " " + PASS_HALF + " " + 0 + " " + lmgroup.id + " comp_indirect" + lmgroup.id + ".bin";

                        if (deferredMode)
                        {
                            deferredFileSrc.Add("");//scenePath + "/comp_indirect" + lmgroup.id + ".bin");
                            deferredFileDest.Add("");//scenePath + "/comp.bin");
                            deferredCommands.Add(startInfo);
                            deferredCommandDesc.Add("Compositing baked lights with GI for " + lmgroup.name + "...");
                        }
                        else
                        {
                            /*File.Copy(scenePath + "/comp_indirect" + lmgroup.id + ".bin", scenePath + "/comp.bin", true);
                            Debug.Log("Running ftrace " + startInfo.Arguments);
                            var exeProcess = System.Diagnostics.Process.Start(startInfo);
                            exeProcess.WaitForExit();
                            errCode2 = exeProcess.ExitCode;*/
                        }
                    }

                    var dirMode = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroup.renderDirMode;
                    var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection && lightmapHasDir[lmgroup.id];

                    if (dominantDirMode)
                    {
                        var startInfo = new System.Diagnostics.ProcessStartInfo();
                        startInfo.CreateNoWindow  = false;
                        startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                        startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                        startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                        startInfo.CreateNoWindow = true;
                        startInfo.Arguments       =  "diradd " + scenePathQuoted + " \"" + nm + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds")
                        + "\"" + " " + PASS_DIRECTION + " " + 0 + " " + lmgroup.id + " dircomp_indirect" + lmgroup.id + ".bin";

                        if (deferredMode)
                        {
                            deferredFileSrc.Add("");//scenePath + "/dircomp_indirect" + lmgroup.id + ".bin");
                            deferredFileDest.Add("");//scenePath + "/dircomp.bin");
                            deferredCommands.Add(startInfo);
                            deferredCommandDesc.Add("Compositing baked direction for " + lmgroup.name + "...");
                        }
                    }
                }
            }
        }

        PrepareAssetImporting();

        // Finalize lightmaps
        foreach(var lmgroup in groupListPlain)
        {
            if (lmgroup.vertexBake && lmgroup.isImplicit && !lmgroup.probes) continue; // skip objects with scaleImLm == 0
            string nm;
            try
            {
                nm = lmgroup.name;
            }
            catch
            {
                DebugLogError("Error postprocessing lightmaps. See console for details");
                ProgressBarEnd();
                throw;
            }
            bool doRender = true;

            if (doRender) {
                //if (lmgroup.vertexBake) continue; // do it after the scene is loaded back
                DebugLogInfo("Preparing (finalize) lightmap " + nm + " (" + (lmgroup.id+1) + "/" + groupList.Count + ")");

                var routine = RenderLMFinalize(lmgroup.id, nm, lmgroup.resolution, lmgroup.vertexBake, lmgroup.renderDirMode, lmgroup.renderMode, lmgroup);
                while(routine.MoveNext())
                {
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;
                }

                if (lmgroup.probes && lmgroup.name == "volumes" && lastFoundBakeableVolumes != null && lastFoundBakeableVolumes.Length > 0)
                {
                    var vols = lastFoundBakeableVolumes;
                    int voffset = 0;

                    var denoiseMod = GetDenoiseMode();
                    var ext = (compressedOutput ? ".lz4" : ".dds");
                    for(int v=0; v<vols.Length; v++)
                    {
                        var vol = vols[v];
                        int rx = VolumeDimension(vol.resolutionX);
                        int ry = VolumeDimension(vol.resolutionY);
                        int rz = VolumeDimension(vol.resolutionZ);
                        if (vol.denoise)
                        {
                            var progressText = "Denoising volume " + vol.name + "...";
                            var startInfo = new System.Diagnostics.ProcessStartInfo();
                            startInfo.CreateNoWindow  = false;
                            startInfo.UseShellExecute = false;
                            startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
                            startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/denoiser"+denoiseMod+".exe";
                            startInfo.CreateNoWindow = true;
                            startInfo.Arguments      = "v ";
                            startInfo.Arguments      += "\"" + scenePath + "/volumes_final_L0" + ext +
                                                     "\" \"" + scenePath + "/volumes_final_L1x" + ext +
                                                     "\" \"" + scenePath + "/volumes_final_L1y" + ext +
                                                     "\" \"" + scenePath + "/volumes_final_L1z" + ext +
                                                     "\" " +
                                                     voffset + " " + rx + " " + ry + " " + rz + " 32 0";
                            deferredFileSrc.Add("");
                            deferredFileDest.Add("");
                            deferredCommands.Add(startInfo);
                            deferredCommandDesc.Add(progressText);
                        }

                        voffset += rx * ry * rz;
                    }

                    if (clientMode)
                    {
                        ftClient.serverGetFileList.Add("volumes_final_L0" + ext);
                        ftClient.serverGetFileList.Add("volumes_final_L1x" + ext);
                        ftClient.serverGetFileList.Add("volumes_final_L1y" + ext);
                        ftClient.serverGetFileList.Add("volumes_final_L1z" + ext);
                    }
                }
            }
        }

        // Add lightmaps split by buckets
        if (ftBuildGraphics.postPacking)
        {
            foreach(var lmgroup in groupListPlain)
            {
                //if (lmgroup.parentID != -2) continue; // parent lightmap mark
                if (lmgroup.parentName != "|") continue; // parent lightmap mark
                var nm = lmgroup.name;

                // actually have anything to pack?
                bool anything = false;
                foreach(var lmgroup2 in groupListPlain)
                {
                    if (lmgroup2.parentName == lmgroup.name)
                    {
                        anything = true;
                        break;
                    }
                }
                if (!anything) continue;

                DebugLogInfo("Preparing (add buckets) lightmap " + nm + " (" + (lmgroup.id+1) + "/" + groupList.Count + ")");

                var routine = RenderLMAddBuckets(lmgroup.id, nm, lmgroup.resolution, lmgroup.vertexBake, lmgroup.renderDirMode, lmgroup.renderMode);
                while(routine.MoveNext())
                {
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;
                }
            }
        }

        // Combine masks
        foreach(var lmgroup in groupListPlain)
        {
            if (lmgroup.vertexBake && lmgroup.isImplicit && !lmgroup.probes) continue; // skip objects with scaleImLm == 0
            string nm;
            try
            {
                nm = lmgroup.name;
            }
            catch
            {
                DebugLogError("Error postprocessing lightmaps. See console for details");
                ProgressBarEnd();
                throw;
            }
            bool doRender = true;

            if (doRender)
            {
                //if (lmgroup.vertexBake) continue; // do it after the scene is loaded back
                DebugLogInfo("Preparing (combine masks) lightmap " + nm + " (" + (lmgroup.id+1) + "/" + groupList.Count + ")");

                var routine = RenderLMCombineMasks(lmgroup.id, nm, lmgroup.resolution, lmgroup.vertexBake, lmgroup.renderMode, lmgroup);
                while(routine.MoveNext())
                {
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;
                }
            }
        }

        // Encode lightmaps
        foreach(var lmgroup in groupListPlain)
        {
            if (lmgroup.vertexBake && lmgroup.isImplicit && !lmgroup.probes) continue; // skip objects with scaleImLm == 0
            var nm = lmgroup.name;
            bool doRender = true;

            if (lmgroup.parentName != null && lmgroup.parentName.Length > 0 && lmgroup.parentName != "|")
            {
                doRender = false;
            }

            if (doRender) {
                DebugLogInfo("Preparing (encode) lightmap " + nm + " (" + (lmgroup.id+1) + "/" + groupList.Count + ")");

                var routine = RenderLMEncode(lmgroup.id, nm, lmgroup.resolution, lmgroup.vertexBake, lmgroup.renderDirMode, lmgroup.renderMode);
                while(routine.MoveNext())
                {
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;
                }
            }
        }

        ftBuildGraphics.FreeTemporaryAreaLightMeshes();

#if UNITY_2017_3_OR_NEWER
#else
        if ((userRenderMode == RenderMode.Shadowmask || userRenderMode == RenderMode.Subtractive) && (lightProbeMode != LightProbeMode.L1) || !hasAnyProbes)
        {
            // Generate lighting data asset
            var assetName = GenerateLightingDataAssetName();
            var newPath = "Assets/" + outputPath + "/" + assetName + ".asset";

            // Try writing the file. If it's locked, write a copy
            bool locked = false;
            BinaryWriter ftest = null;
            try
            {
                ftest = new BinaryWriter(File.Open(newPath, FileMode.Create));
            }
            catch
            {
                var index = assetName.IndexOf("_copy");
                if (index >= 0)
                {
                    assetName = assetName.Substring(0, index);
                }
                else
                {
                    assetName += "_copy";
                }
                newPath = "Assets/" + outputPath + "/" + assetName + ".asset";
                locked = true;
            }
            if (!locked) ftest.Close();

            if (!ftLightingDataGen.GenerateShadowmaskLightingData(newPath, ref maskedLights, userRenderMode == RenderMode.Subtractive))
            {
                DebugLogError("Failed to generate LightingDataAsset");
                userCanceled = true;
                yield break;
            }
            AssetDatabase.Refresh();
            ApplyLightingDataAsset(newPath);
            EditorSceneManager.MarkAllScenesDirty();
            EditorSceneManager.SaveOpenScenes();
        }
#endif

        // Store lightmap flags
        for(int s=0; s<sceneCount; s++)
        {
            var scene = EditorSceneManager.GetSceneAt(s);
            if (!scene.isLoaded) continue;
            storage = storages[scene];
            //if (forceRefresh) // removed condition to make "Export" option work in isolation
            {
                storage.lightmapHasColor = lightmapHasColor;
                storage.lightmapHasMask = lightmapHasMask;
                storage.lightmapHasDir = lightmapHasDir;
                storage.lightmapHasRNM = lightmapHasRNM;
                storage.serverGetFileList = ftClient.serverGetFileList;
            }
        }
        EditorSceneManager.MarkAllScenesDirty();

        // Run commands
        if (clientMode)
        {
            // Add vertex LM data to the list of requested files
            var ext = (compressedOutput ? ".lz4" : ".dds");
            foreach(var lmgroup in groupListPlain)
            {
                if (!lmgroup.vertexBake) continue;
                if (lmgroup.isImplicit) continue;

                bool hasShadowMask = lmgroup.renderMode == (int)BakeryLightmapGroup.RenderMode.Shadowmask ||
                    (lmgroup.renderMode == (int)BakeryLightmapGroup.RenderMode.Auto && userRenderMode == RenderMode.Shadowmask);

                bool hasDir = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.DominantDirection ||
                    (lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.DominantDirection);

                bool hasSH = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.SH || lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.MonoSH ||
                    (lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.SH) ||
                    (lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.MonoSH);

                var lmname = lmgroup.name;

                ftClient.serverGetFileList.Add(lmname + (hasSH ? "_final_L0" : "_final_HDR") + ext);
                if (hasShadowMask) ftClient.serverGetFileList.Add(lmname + "_Mask" + ext);
                if (hasDir) ftClient.serverGetFileList.Add(lmname + "_final_Dir" + ext);
                if (hasSH)
                {
                    ftClient.serverGetFileList.Add(lmname + "_final_L1x" + ext);
                    ftClient.serverGetFileList.Add(lmname + "_final_L1y" + ext);
                    ftClient.serverGetFileList.Add(lmname + "_final_L1z" + ext);
                }
            }

            // Add probe data to requested list
            if (lightProbeMode == LightProbeMode.L1 && hasAnyProbes)
            {
                ftClient.serverGetFileList.Add("probes_final_L0" + ext);
                ftClient.serverGetFileList.Add("probes_final_L1x" + ext);
                ftClient.serverGetFileList.Add("probes_final_L1y" + ext);
                ftClient.serverGetFileList.Add("probes_final_L1z" + ext);
            }

            var flist = new BinaryWriter(File.Open(scenePath + "/renderSequence.bin", FileMode.Create));
            byte task;
            int tasks = 0;

            flist.Write(tasks);

            tasks++;
            flist.Write(ftClient.SERVERTASK_SETSCENENAME);
            WriteString(flist, EditorSceneManager.GetActiveScene().name);

            if (deferredCommandsLODGen.Count > 0)
            {
                var vbtraceTexPosNormalArray = ftBuildGraphics.vbtraceTexPosNormalArray;
                var vbtraceTexUVArray = ftBuildGraphics.vbtraceTexUVArray;
                var vbtraceTexUVArrayLOD = ftBuildGraphics.vbtraceTexUVArrayLOD;

                tasks++;
                flist.Write(ftClient.SERVERTASK_LODGENINIT);
                flist.Write(lmGroupMinLOD.Length);
                for(int j=0; j<lmGroupMinLOD.Length; j++) flist.Write(lmGroupMinLOD[j]);
                flist.Write(vbtraceTexPosNormalArray.Count);
                for(int j=0; j<vbtraceTexPosNormalArray.Count; j++) flist.Write(vbtraceTexPosNormalArray[j]);
                flist.Write(vbtraceTexUVArray.Count);
                for(int j=0; j<vbtraceTexUVArray.Count; j++) flist.Write(vbtraceTexUVArray[j]);
                flist.Write(vbtraceTexUVArrayLOD.Length);
                for(int j=0; j<vbtraceTexUVArrayLOD.Length; j++) flist.Write(vbtraceTexUVArrayLOD[j]);
            }

            for(int i=0; i<deferredCommands.Count; i++)
            {
                if (deferredFileSrc[i].Length > 0)
                {
                    tasks++;
                    flist.Write(ftClient.SERVERTASK_COPY);
                    WriteString(flist, deferredFileSrc[i].Replace(scenePath, "%SCENEPATH%"));
                    WriteString(flist, deferredFileDest[i].Replace(scenePath, "%SCENEPATH%"));
                }

                var startInfo = deferredCommands[i];
                if (startInfo != null)
                {
                    var app = Path.GetFileNameWithoutExtension(deferredCommands[i].FileName);
                    if (!ftClient.app2serverTask.TryGetValue(app, out task))
                    {
                        DebugLogError("Server doesn't support the task: " + app);
                        userCanceled = true;
                        yield break;
                    }
                    tasks++;
                    flist.Write(task);
                    WriteString(flist, startInfo.Arguments.Replace(scenePath, "%SCENEPATH%").
                        Replace(Application.dataPath + "/" + outputPathFull, "%SCENEPATH%"));
                }

                if (deferredCommandsUVGB.ContainsKey(i))
                {
                    GL.IssuePluginEvent(7); // render UVGBuffer
                    int uerr = 0;
                    while(uerr == 0)
                    {
                        uerr = ftBuildGraphics.GetUVGBErrorCode();
                        yield return null;
                    }

                    if (uerr != 0 && uerr != 99999)
                    {
                        DebugLogError("ftRenderUVGBuffer error: " + uerr);
                        userCanceled = true;
                        yield break;
                    }

                    ftBuildGraphics.FreeAlbedoCopies();
                }

                if (deferredCommandsRebake.ContainsKey(i))
                {
                    var lmgroup2 = deferredCommandsRebake[i];
                    if (lmgroup2.containsTerrains)
                    {
                        tasks++;
                        flist.Write(ftClient.SERVERTASK_LMREBAKESIMPLE);
                        WriteString(flist, lmgroup2.name + "_diffuse_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                        WriteString(flist, lmgroup2.name + "_diffuse_HDR_LOD");
                        flist.Write(lmgroup2.resolution/2);
                        flist.Write(lmgroup2.resolution/2);
                        flist.Write(lmgroup2.id);
                    }
                    else
                    {
                        if (lmrIndicesLengths[lmgroup2.id] == 0)
                        {
                            Debug.LogError("lmrIndicesLengths == 0 for " + lmgroup2.name);
                        }
                        else
                        {
                            tasks++;
                            flist.Write(ftClient.SERVERTASK_LMREBAKE);
                            WriteString(flist, lmgroup2.name + "_diffuse_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                            WriteString(flist, lmgroup2.name + "_diffuse_HDR_LOD");
                            WriteString(flist, "lodmask_uvpos_" + lmgroup2.name + (compressedGBuffer ? ".lz4" : ".dds"));
                            flist.Write(uvSrcBuff.Length);
                            for(int j=0; j<uvSrcBuff.Length; j++) flist.Write(uvSrcBuff[j]);
                            flist.Write(uvDestBuff.Length);
                            for(int j=0; j<uvDestBuff.Length; j++) flist.Write(uvDestBuff[j]);
                            flist.Write(uvBuffOffsets[lmgroup2.id]);
                            flist.Write(uvBuffLengths[lmgroup2.id]);
                            flist.Write(lmrIndicesBuff.Length);
                            for(int j=0; j<lmrIndicesBuff.Length; j++) flist.Write(lmrIndicesBuff[j]);
                            flist.Write(lmrIndicesOffsets[lmgroup2.id]);
                            flist.Write(lmrIndicesLengths[lmgroup2.id]);
                            flist.Write(lmgroup2.resolution/2);
                            flist.Write(lmgroup2.resolution/2);
                            flist.Write(lmgroup2.id);
                        }
                    }
                }

                if (deferredCommandsLODGen.ContainsKey(i))
                {
                    int id = deferredCommandsLODGen[i];
                    tasks++;
                    flist.Write(ftClient.SERVERTASK_LODGEN);
                    flist.Write(id);
                }

                if (deferredCommandsGIGen.ContainsKey(i))
                {
                    Vector3 paramz = deferredCommandsGIGen[i];
                    int id = (int)paramz.x;
                    int bounce = (int)paramz.y;
                    string nm = "";
                    for(int j=0; j<groupListPlain.Count; j++)
                    {
                        if (groupListPlain[j].id == id)
                        {
                            nm = groupListPlain[j].name;
                        }
                    }
                    if (nm.Length == 0)
                    {
                        DebugLogError("Error generating GI parameters for ID " + id);
                        userCanceled = true;
                        yield break;
                    }
                    tasks++;
                    flist.Write(ftClient.SERVERTASK_GIPARAMS);
                    WriteString(flist, "gi_" + nm + bounce + ".bin");
                    flist.Write(SampleCount(giSamples));
                    flist.Write(giBackFaceWeight);
                    WriteString(flist, bounce == bounces-1 ? "" : "uvalbedo_" + nm + (compressedGBuffer ? ".lz4" : ".dds"));
                    flist.Write(groupListGIContributingPlain.Count);
                    flist.Write((byte)0);// giLodModeEnabled ? (byte)1 : (byte)0);
                    flist.Write(id);
                    foreach(var lmgroup2 in groupListGIContributingPlain)
                    {
                        flist.Write(lmgroup2.id);
                        WriteString(flist, lmgroup2.name);
                        flist.Write(compressedOutput ? (byte)1 : (byte)0);
                    }
                    WriteString(flist, bounce == bounces - 1 ? (nm + "_lights_Dir" + (compressedOutput ? ".lz4" : ".dds")) : "");
                }
            }

            flist.BaseStream.Seek(0, SeekOrigin.Begin);
            flist.Write(tasks);
            flist.Close();

            var renderSequence = File.ReadAllBytes(scenePath + "/renderSequence.bin");

            try
            {
                if (!ftClient.SendRenderSequence(renderSequence))
                {
                    DebugLogError("Can't connect to server");
                    ProgressBarEnd();
                }
            }
            catch
            {
                DebugLogError("Error sending data to server");
                ProgressBarEnd();
                throw;
            }
        }
        else if (deferredMode)
        {
            DebugLogInfo("Unloading scenes...");
            if (unloadScenesInDeferredMode) UnloadScenes();
            yield return new WaitForEndOfFrame();
            DebugLogInfo("Unloading scenes - done.");

            if (deferredCommands.Count != deferredFileSrc.Count || deferredFileSrc.Count != deferredFileDest.Count || deferredCommands.Count != deferredCommandDesc.Count)
            {
                DebugLogError("Deferred execution error");
                userCanceled = true;
                yield break;
            }

            ProgressBarSetStep(1.0f / deferredCommands.Count);
            for(int i=0; i<deferredCommands.Count; i++)
            {
                if (deferredFileSrc[i].Length > 0) File.Copy(deferredFileSrc[i], deferredFileDest[i], true);

                var startInfo = deferredCommands[i];

                if (startInfo != null)
                {
                    var app = Path.GetFileNameWithoutExtension(deferredCommands[i].FileName);
                    DebugLogInfo("Running " + app + " " + startInfo.Arguments);
                    ProgressBarShow(deferredCommandDesc[i], i / (float)deferredCommands.Count, true);
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;

                    int errCode2 = -1;
                    int fallbackCtr = 0;
                    while(errCode2 != 0)
                    {
#if LAUNCH_VIA_DLL
                        var crt = ProcessCoroutine(app, startInfo.Arguments);
                        while(crt.MoveNext()) yield return null;
                        if (userCanceled) yield break;
                        errCode2 = lastReturnValue;
#else
                        var exeProcess = System.Diagnostics.Process.Start(startInfo);

                        //exeProcess.WaitForExit();
                        while(!exeProcess.HasExited)
                        {
                            yield return null;
                            userCanceled = simpleProgressBarCancelled();
                            if (userCanceled)
                            {
                                ProgressBarEnd();
                                yield break;
                            }
                        }

                        errCode2 = exeProcess.ExitCode;
#endif

                        if (errCode2 != 0)
                        {
                            DebugLogInfo("Error: " + ftErrorCodes.Translate(app, errCode2));
                            if (deferredCommandsFallback.ContainsKey(i))
                            {
                                DebugLogInfo("Trying fallback " +fallbackCtr);
                                var fallbackList = deferredCommandsFallback[i];
                                if (fallbackCtr >= fallbackList.Count) break;
                                startInfo.Arguments = fallbackList[fallbackCtr];
                                fallbackCtr++;
                            }
                            else
                            {
                                break;
                            }
                        }
                    }

                    if (errCode2 != 0)
                    {
                        DebugLogError(app + " error: " + ftErrorCodes.Translate(app, errCode2));
                        userCanceled = true;
                        yield break;
                    }
                }

                if (deferredCommandsLODGen.ContainsKey(i))
                {
                    int id = deferredCommandsLODGen[i];
                    DebugLogInfo("Generating LOD vbTraceTex for " + id);

                    ProgressBarShow(deferredCommandDesc[i], i / (float)deferredCommands.Count, true);
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;

                    int errCode2 = GenerateVBTraceTexLOD(id);
                    if (errCode2 != 0)
                    {
                        DebugLogError("Error generating tracing mesh for ID " + id);
                        userCanceled = true;
                        yield break;
                    }
                }

                if (deferredCommandsGIGen.ContainsKey(i))
                {
                    Vector3 paramz = deferredCommandsGIGen[i];
                    int id = (int)paramz.x;
                    int bounce = (int)paramz.y;
                    bool useDir = paramz.z > 0;
                    DebugLogInfo("Generating GI parameters for " + id+" "+bounce);

                    ProgressBarShow(deferredCommandDesc[i], i / (float)deferredCommands.Count, true);
                    if (userCanceled)
                    {
                        ProgressBarEnd();
                        yield break;
                    }
                    yield return null;

                    string nm = "";
                    int sceneLodLevel = -1;
                    for(int j=0; j<groupListPlain.Count; j++)
                    {
                        if (groupListPlain[j].id == id)
                        {
                            nm = groupListPlain[j].name;
                            sceneLodLevel = groupListPlain[j].sceneLodLevel;
                        }
                    }
                    if (nm.Length == 0)
                    {
                        DebugLogError("Error generating GI parameters for ID " + id);
                        userCanceled = true;
                        yield break;
                    }
                    GenerateGIParameters(id, nm, bounce, bounces, useDir, sceneLodLevel);
                }

                if (deferredCommandsHalf2VB.ContainsKey(i))
                {
                    var gr = deferredCommandsHalf2VB[i];

                    bool hasShadowMask = gr.renderMode == (int)BakeryLightmapGroup.RenderMode.Shadowmask ||
                        (gr.renderMode == (int)BakeryLightmapGroup.RenderMode.Auto && userRenderMode == RenderMode.Shadowmask);

                    bool hasDir = gr.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.DominantDirection ||
                        (gr.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.DominantDirection);

                    bool hasSH = gr.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.SH ||
                        (gr.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.SH);

                    bool monoSH = gr.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.MonoSH ||
                        (gr.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.MonoSH);

                    int err = GenerateVertexBakedMeshes(gr.id, gr.name, hasShadowMask, hasDir, hasSH || monoSH, monoSH);
                    if (err != 0)
                    {
                        DebugLogError("Error generating vertex color data for " + gr.name);
                        userCanceled = true;
                        yield break;
                    }
                }

                if (deferredCommandsUVGB.ContainsKey(i))
                {
                    GL.IssuePluginEvent(7); // render UVGBuffer
                    int uerr = 0;
                    while(uerr == 0)
                    {
                        uerr = ftBuildGraphics.GetUVGBErrorCode();
                        yield return null;
                    }

                    if (uerr != 0 && uerr != 99999)
                    {
                        DebugLogError("ftRenderUVGBuffer error: " + uerr);
                        userCanceled = true;
                        yield break;
                    }

                    ftBuildGraphics.FreeAlbedoCopies();
                }
            }

            ProgressBarShow("Finished rendering", 1, true);

            if (unloadScenesInDeferredMode)
            {
                LoadScenes();
                storages = new Dictionary<Scene, ftLightmapsStorage>();
                //var sanityTimeout = GetTime() + 5;
                while( (sceneCount > EditorSceneManager.sceneCount || EditorSceneManager.GetSceneAt(0).path.Length == 0))// && GetTime() < sanityTimeout )
                {
                    yield return null;
                }
                for(int i=0; i<sceneCount; i++)
                {
                    var scene = EditorSceneManager.GetSceneAt(i);
                    if (!scene.isLoaded) continue;
                    var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
                    storage = go.GetComponent<ftLightmapsStorage>();
                    storages[scene] = storage;

                    /*if (giLodModeEnabled)
                    {
                        storage.lmGroupLODResFlags = lmGroupLODResFlags;
                        storage.lmGroupLODMatrix = lmGroupLODMatrix;
                        EditorUtility.SetDirty(storage);
                    }*/

                    if (loadedScenesActive[i]) EditorSceneManager.SetActiveScene(scene);
                }
            }
            progressStepsDone = 0;
            progressSteps = groupList.Count * 3;
            ProgressBarSetStep(0);
        }

        if (clientMode)
        {
            ProgressBarEnd();
        }
        else
        {
            LoadRenderSettings();

            var apply = ApplyBakedData();
            while(apply.MoveNext()) yield return null;

            var ms = GetTimeMs();
            double bakeTime = (ms - startMs) / 1000.0;
            DebugLogInfo("Rendering finished in " + bakeTime + " seconds");

            lastBakeTime = (int)bakeTime;
            if (renderSettingsStorage == null) renderSettingsStorage = FindRenderSettingsStorage();
            if (renderSettingsStorage != null) renderSettingsStorage.lastBakeTime = lastBakeTime;

            try
            {
                var bakeTimeLog = new StreamWriter(File.Open("bakery_times.log", FileMode.Append));
                if (bakeTimeLog != null)
                {
                    int hours = lastBakeTime / (60*60);
                    int minutes = (lastBakeTime / 60) % 60;
                    int seconds = lastBakeTime % 60;
                    bakeTimeLog.Write(System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") +  " | " + EditorSceneManager.GetActiveScene().name + " | " + hours+"h "+minutes+"m "+seconds+"s\n");
                }
                bakeTimeLog.Close();
            }
            catch
            {
                Debug.LogError("Failed writing bakery_times.log");
            }

            ProgressBarEnd();

            if (beepOnFinish) System.Media.SystemSounds.Beep.Play();

            if (OnFinishedFullRender != null)
            {
                OnFinishedFullRender.Invoke(this, null);
            }
        }
    }

    Texture2D ConvertTexToAsset(Texture2D lm)
    {
        var path = AssetDatabase.GetAssetPath(lm);
        var ti = (TextureImporter)TextureImporter.GetAtPath(path);

        Texture2D lm2 = null;
        int resultingMipCount = 0;

        if (ti.mipmapEnabled && pstorage.maxAssetMip < lm.mipmapCount)
        {
            #if UNITY_2019_3_OR_NEWER
                lm2 = new Texture2D(lm.width, lm.width, lm.format, pstorage.maxAssetMip, !ti.sRGBTexture);
                resultingMipCount = pstorage.maxAssetMip;
            #else
                Debug.LogError("Textures can't be converted to mipmap-limited .asset in this Unity version. The exact threshold version is unknown, but it definitely works on >= 2019.3.");
                return lm;
            #endif
        }
        else
        {
            lm2 = new Texture2D(lm.width, lm.width, lm.format, ti.mipmapEnabled, !ti.sRGBTexture);
            resultingMipCount = lm.mipmapCount;
        }

        for(int i=0; i<resultingMipCount; i++)
        {
            Graphics.CopyTexture(lm, 0, i, lm2, 0, i);
        }

        lm2.anisoLevel = lm.anisoLevel;
        lm2.filterMode = lm.filterMode;
        lm2.wrapMode = lm.wrapMode;

        var newPath = Path.ChangeExtension(path, "asset");
        lm2 = CreateOrReplaceAsset(lm2, newPath);

        var so = new SerializedObject(lm);
        var lmFormat = so.FindProperty("m_LightmapFormat").intValue;

        so = new SerializedObject(lm2);
        so.FindProperty("m_LightmapFormat").intValue = lmFormat;
        so.ApplyModifiedProperties();

        AssetDatabase.SaveAssets();
        return AssetDatabase.LoadAssetAtPath<Texture2D>(newPath);
    }

    IEnumerator ApplyBakedData()
    {
        var sceneCount = EditorSceneManager.sceneCount;
        var bdataName = "BakeryPrefabLightmapData";

        // Load vertex colors
        try
        {
            foreach(var lmgroup in groupListGIContributingPlain)
            {
                if (!lmgroup.vertexBake) continue;
                if (lmgroup.isImplicit) continue;

                bool hasShadowMask = lmgroup.renderMode == (int)BakeryLightmapGroup.RenderMode.Shadowmask ||
                    (lmgroup.renderMode == (int)BakeryLightmapGroup.RenderMode.Auto && userRenderMode == RenderMode.Shadowmask);

                bool hasDir = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.DominantDirection ||
                    (lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.DominantDirection);

                bool hasSH = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.SH ||
                    (lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.SH);

                bool monoSH = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.MonoSH ||
                    (lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto && renderDirMode == RenderDirMode.MonoSH);

                GenerateVertexBakedMeshes(lmgroup.id, lmgroup.name, hasShadowMask, hasDir, hasSH || monoSH, monoSH);
            }
        }
        catch
        {
            DebugLogError("Error loading vertex colors. See console for details");
            ProgressBarEnd();
            throw;
        }

        // Set probe colors
        if (!selectedOnly && lightProbeMode == LightProbeMode.L1 && hasAnyProbes && !fullSectorRender)
        {
            var probes = LightmapSettings.lightProbes;
            if (probes == null)
            {
                DebugLogError("No probes in LightingDataAsset");
                yield break;
            }
            var positions = probes.positions;
            int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)probes.count));
            atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)tileSize) * tileSize;

            var shs = new SphericalHarmonicsL2[probes.count];

            int r = 0;
            int g = 1;
            int b = 2;

            var l0 = new float[atlasTexSize * atlasTexSize * 4];
            var l1x = new float[atlasTexSize * atlasTexSize * 4];
            var l1y = new float[atlasTexSize * atlasTexSize * 4];
            var l1z = new float[atlasTexSize * atlasTexSize * 4];
            var handle = GCHandle.Alloc(l0, GCHandleType.Pinned);
            var handleL1x = GCHandle.Alloc(l1x, GCHandleType.Pinned);
            var handleL1y = GCHandle.Alloc(l1y, GCHandleType.Pinned);
            var handleL1z = GCHandle.Alloc(l1z, GCHandleType.Pinned);
            var errCodes = new int[4];
            try
            {
                var pointer = handle.AddrOfPinnedObject();
                var pointerL1x = handleL1x.AddrOfPinnedObject();
                var pointerL1y = handleL1y.AddrOfPinnedObject();
                var pointerL1z = handleL1z.AddrOfPinnedObject();
                errCodes[0] = halffloat2vb(scenePath + "\\probes_final_L0" + (compressedOutput ? ".lz4" : ".dds"), pointer, 2);
                errCodes[1] = halffloat2vb(scenePath + "\\probes_final_L1x" + (compressedOutput ? ".lz4" : ".dds"), pointerL1x, 2);
                errCodes[2] = halffloat2vb(scenePath + "\\probes_final_L1y" + (compressedOutput ? ".lz4" : ".dds"), pointerL1y, 2);
                errCodes[3] = halffloat2vb(scenePath + "\\probes_final_L1z" + (compressedOutput ? ".lz4" : ".dds"), pointerL1z, 2);
                bool ok = true;
                for(int i=0; i<4; i++)
                {
                    if (errCodes[i] != 0)
                    {
                        Debug.LogError("hf2vb (" + i + "): " + errCodes[i]);
                        ok = false;
                    }
                }
                if (ok)
                {
                    for(int i=0; i<probes.count; i++)
                    {
                        var sh = new SphericalHarmonicsL2();

                        sh[r,0] = l0[i*4+0] * 2;
                        sh[g,0] = l0[i*4+1] * 2;
                        sh[b,0] = l0[i*4+2] * 2;

                        const float convL0 = ftAdditionalConfig.convL0;
                        const float convL1 = ftAdditionalConfig.convL1;

                        // read as BGR (2,1,0)
                        sh[r,3] = (l1x[i*4+2] * 2.0f - 1.0f) * sh[r,0]*2 * convL1;
                        sh[g,3] = (l1x[i*4+1] * 2.0f - 1.0f) * sh[g,0]*2 * convL1;
                        sh[b,3] = (l1x[i*4+0] * 2.0f - 1.0f) * sh[b,0]*2 * convL1;

                        sh[r,1] = (l1y[i*4+2] * 2.0f - 1.0f) * sh[r,0]*2 * convL1;
                        sh[g,1] = (l1y[i*4+1] * 2.0f - 1.0f) * sh[g,0]*2 * convL1;
                        sh[b,1] = (l1y[i*4+0] * 2.0f - 1.0f) * sh[b,0]*2 * convL1;

                        sh[r,2] = (l1z[i*4+2] * 2.0f - 1.0f) * sh[r,0]*2 * convL1;
                        sh[g,2] = (l1z[i*4+1] * 2.0f - 1.0f) * sh[g,0]*2 * convL1;
                        sh[b,2] = (l1z[i*4+0] * 2.0f - 1.0f) * sh[b,0]*2 * convL1;

                        sh[r,0] *= convL0;
                        sh[g,0] *= convL0;
                        sh[b,0] *= convL0;

                        shs[i] = sh;
                    }
                }
            }
            finally
            {
                handle.Free();
                handleL1x.Free();
                handleL1y.Free();
                handleL1z.Free();
            }

#if UNITY_2019_3_OR_NEWER
            if (useUnityForOcclsusionProbes)
            {
                // Reload scenes or changes to LightingDataAsset are not applied (?!)
                EditorSceneManager.SaveOpenScenes();
                var setup = EditorSceneManager.GetSceneManagerSetup();
                RestoreSceneManagerSetup(setup);
                storages = new Dictionary<Scene, ftLightmapsStorage>();
                while( (sceneCount > EditorSceneManager.sceneCount || EditorSceneManager.GetSceneAt(0).path.Length == 0))// && GetTime() < sanityTimeout )
                {
                    yield return null;
                }
                for(int i=0; i<sceneCount; i++)
                {
                    var scene = EditorSceneManager.GetSceneAt(i);
                    if (!scene.isLoaded) continue;
                    var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
                    storage = go.GetComponent<ftLightmapsStorage>();
                    storages[scene] = storage;
                }
            }
#endif

            probes.bakedProbes = shs;
            EditorUtility.SetDirty(Lightmapping.lightingDataAsset);
        }

        LoadVolumes();

        //EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
        EditorSceneManager.MarkAllScenesDirty();

        // Asset importing stage 1: set AssetPostprocessor settings -> moved

        // Asset importing stage 2: actual import
        AssetDatabase.Refresh();
        ftTextureProcessor.texSettings = new Dictionary<string, Vector2>();

        // Asset importing stage 3: load and assign imported assets
        foreach(var lmgroup in groupListGIContributingPlain)
        {
            if (lmgroup.vertexBake) continue;
            if (lmgroup.parentName != null && lmgroup.parentName.Length > 0 && lmgroup.parentName != "|") continue;
            var nm = lmgroup.name;

            var dirMode = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroup.renderDirMode;
            var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection && lightmapHasDir[lmgroup.id];
            var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM && lightmapHasRNM[lmgroup.id];
            var shMode = (dirMode == (int)ftRenderLightmap.RenderDirMode.SH || dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH) && lightmapHasRNM[lmgroup.id];
            var monoSH = dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH;
            var shModeProbe = dirMode == (int)BakeryLightmapGroup.RenderDirMode.ProbeSH && lightmapHasRNM[lmgroup.id];
            if (shModeProbe) shMode = true;

            Texture2D lm = null;
            var outfile = "Assets/" + outputPathFull + "/"+nm+"_final.hdr";
            if (rnmMode) outfile = "Assets/" + outputPathFull + "/"+nm+"_RNM0.hdr";
            if (lightmapHasColor[lmgroup.id] && File.Exists(outfile))
            {
                lm = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset)
                {
                    lm = ConvertTexToAsset(lm);
                }
            }

            Texture2D mask = null;
            if (lightmapHasMask[lmgroup.id] > 0)
            {
                outfile = "Assets/" + outputPathFull + "/"+nm+"_mask" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                if (File.Exists(outfile))
                {
                    mask = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                    if (pstorage.format8bit == BakeryProjectSettings.FileFormat.Asset)
                    {
                        mask = ConvertTexToAsset(mask);
                    }
                }
            }

            Texture2D dirLightmap = null;
            if (dominantDirMode)
            {
                outfile = "Assets/" + outputPathFull + "/"+nm+"_dir" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                if (File.Exists(outfile))
                {
                    dirLightmap = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                    if (pstorage.format8bit == BakeryProjectSettings.FileFormat.Asset)
                    {
                        dirLightmap = ConvertTexToAsset(dirLightmap);
                    }
                }
            }

            if (monoSH)
            {
                outfile = "Assets/" + outputPathFull + "/"+nm+"_L1" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                if (File.Exists(outfile))
                {
                    dirLightmap = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                    if (pstorage.format8bit == BakeryProjectSettings.FileFormat.Asset)
                    {
                        dirLightmap = ConvertTexToAsset(dirLightmap);
                    }
                }
            }

            Texture2D rnmLightmap0 = null;
            Texture2D rnmLightmap1 = null;
            Texture2D rnmLightmap2 = null;
            if (rnmMode)
            {
                for(int c=0; c<3; c++)
                {
                    outfile = "Assets/" + outputPathFull + "/"+nm+"_RNM" + c + ".hdr";
                    if (c == 0)
                    {
                        rnmLightmap0 = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                        if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset) rnmLightmap0 = ConvertTexToAsset(rnmLightmap0);
                    }
                    if (c == 1)
                    {
                        rnmLightmap1 = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                        if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset) rnmLightmap1 = ConvertTexToAsset(rnmLightmap1);
                    }
                    if (c == 2)
                    {
                        rnmLightmap2 = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                        if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset) rnmLightmap2 = ConvertTexToAsset(rnmLightmap2);
                    }
                }
            }

            if (shMode)
            {
                outfile = "Assets/" + outputPathFull + "/"+nm+"_L0.hdr";
                lm = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset)
                {
                    lm = ConvertTexToAsset(lm);
                }
                for(int c=0; c<3; c++)
                {
                    string comp;
                    if (c==0)
                    {
                        comp = "x";
                    }
                    else if (c==1)
                    {
                        comp = "y";
                    }
                    else
                    {
                        comp = "z";
                    }
                    outfile = "Assets/" + outputPathFull + "/"+nm+"_L1" + comp + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                    if (c == 0)
                    {
                        rnmLightmap0 = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                        if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset) rnmLightmap0 = ConvertTexToAsset(rnmLightmap0);
                    }
                    if (c == 1)
                    {
                        rnmLightmap1 = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                        if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset) rnmLightmap1 = ConvertTexToAsset(rnmLightmap1);
                    }
                    if (c == 2)
                    {
                        rnmLightmap2 = AssetDatabase.LoadAssetAtPath(outfile, typeof(Texture2D)) as Texture2D;
                        if (pstorage.formatHDR == BakeryProjectSettings.FileFormatHDR.Asset) rnmLightmap2 = ConvertTexToAsset(rnmLightmap2);
                    }
                }
            }

            for(int s=0; s<sceneCount; s++)
            {
                var scene = EditorSceneManager.GetSceneAt(s);
                if (!scene.isLoaded) continue;
                if (!storages.TryGetValue(scene, out storage))
                {
                    Debug.LogError("Scene " + scene.name + " is not in the storage map (wasn't loaded before rendering?)");
                    continue;
                }

                storage.anyVolumes = hasAnyVolumes;
                storage.compressedVolumes = compressVolumes;

                while(storage.maps.Count <= lmgroup.id)
                {
                    storage.maps.Add(null);
                }
                storage.maps[lmgroup.id] = lm;

                if (userRenderMode == RenderMode.Shadowmask)
                {
                    while(storage.masks.Count <= lmgroup.id)
                    {
                        storage.masks.Add(null);
                    }
                    storage.masks[lmgroup.id] = mask;
                }

                if (dominantDirMode || monoSH)
                {
                    while(storage.dirMaps.Count <= lmgroup.id)
                    {
                        storage.dirMaps.Add(null);
                    }
                    storage.dirMaps[lmgroup.id] = dirLightmap;
                }

                if (rnmMode || (shMode && !monoSH))
                {
                    while(storage.rnmMaps0.Count <= lmgroup.id)
                    {
                        storage.rnmMaps0.Add(null);
                    }
                    storage.rnmMaps0[lmgroup.id] = rnmLightmap0;

                    while(storage.rnmMaps1.Count <= lmgroup.id)
                    {
                        storage.rnmMaps1.Add(null);
                    }
                    storage.rnmMaps1[lmgroup.id] = rnmLightmap1;

                    while(storage.rnmMaps2.Count <= lmgroup.id)
                    {
                        storage.rnmMaps2.Add(null);
                    }
                    storage.rnmMaps2[lmgroup.id] = rnmLightmap2;

                    while(storage.mapsMode.Count <= lmgroup.id)
                    {
                        storage.mapsMode.Add(0);
                    }
                    storage.mapsMode[lmgroup.id] = rnmMode ? 2 : 3;
                }

                // Clear temp data from storage
                storage.uvBuffOffsets = new int[0];
                storage.uvBuffLengths = new int[0];
                storage.uvSrcBuff = new float[0];
                storage.uvDestBuff = new float[0];
                storage.lmrIndicesOffsets = new int[0];
                storage.lmrIndicesLengths = new int[0];
                storage.lmrIndicesBuff = new int[0];

                storage.lmGroupLODResFlags = new int[0];
                storage.lmGroupMinLOD = new int[0];
                storage.lmGroupLODMatrix = new int[0];
            }
        }

        if (curSector != null && curSectorName.Length > 0)
        {
            for(int s=0; s<sceneCount; s++)
            {
                var scene = EditorSceneManager.GetSceneAt(s);
                if (!scene.isLoaded) continue;
                storage = storages[scene];

                // Copy lightmap mappings to sector data
                if (storage.sectors == null) storage.sectors = new List<ftLightmapsStorage.SectorData>();
                ftLightmapsStorage.SectorData sect = null;
                for(int sc=0; sc<storage.sectors.Count; sc++)
                {
                    if (storage.sectors[sc].name == curSectorName)
                    {
                        sect = storage.sectors[sc];
                        break;
                    }
                }
                if (sect == null)
                {
                    sect = new ftLightmapsStorage.SectorData();
                    sect.name = curSectorName;
                    storage.sectors.Add(sect);
                }
                sect.maps = storage.maps;
                sect.masks = storage.masks;
                sect.dirMaps = storage.dirMaps;
                sect.rnmMaps0 = storage.rnmMaps0;
                sect.rnmMaps1 = storage.rnmMaps1;
                sect.rnmMaps2 = storage.rnmMaps2;
                sect.mapsMode = storage.mapsMode;
                sect.bakedRenderers = storage.bakedRenderers;
#if USE_TERRAINS
                sect.bakedRenderersTerrain = storage.bakedRenderersTerrain;
                sect.bakedIDsTerrain = storage.bakedIDsTerrain;
                sect.bakedScaleOffsetTerrain = storage.bakedScaleOffsetTerrain;
#endif
                sect.bakedIDs = storage.bakedIDs;
                sect.bakedScaleOffset = storage.bakedScaleOffset;
                sect.bakedVertexColorMesh = storage.bakedVertexColorMesh;
                sect.nonBakedRenderers = storage.nonBakedRenderers;
            }
        }

        if (fullSectorRender || selectedOnly || probesOnlyL1)
        {
            MergeSectors();
        }

        // Remove unused lightmaps and remap IDs
        if (sceneCount > 1 && removeDuplicateLightmaps)
        {
            for(int s=0; s<sceneCount; s++)
            {
                var scene = EditorSceneManager.GetSceneAt(s);
                if (!scene.isLoaded) continue;
                storage = storages[scene];
                var usedIDs = new Dictionary<int, bool>();
                var origID2New = new Dictionary<int, int>();
                for(int i=0; i<storage.bakedIDs.Count; i++)
                {
                    if (storage.bakedIDs[i] < 0 || storage.bakedIDs[i] > storage.maps.Count) continue;
                    usedIDs[storage.bakedIDs[i]] = true;
                }
#if USE_TERRAINS
                for(int i=0; i<storage.bakedIDsTerrain.Count; i++)
                {
                    if (storage.bakedIDsTerrain[i] < 0 || storage.bakedIDsTerrain[i] > storage.maps.Count) continue;
                    usedIDs[storage.bakedIDsTerrain[i]] = true;
                }
#endif
                var newMaps = new List<Texture2D>();
                var newMasks = new List<Texture2D>();
                var newDirMaps = new List<Texture2D>();
                var newRNM0Maps = new List<Texture2D>();
                var newRNM1Maps = new List<Texture2D>();
                var newRNM2Maps = new List<Texture2D>();
                var newMapsMode = new List<int>();
                foreach(var pair in usedIDs)
                {
                    int origID = pair.Key;
                    int newID = newMaps.Count;
                    origID2New[origID] = newID;

                    newMaps.Add(storage.maps[origID]);
                    if (storage.masks.Count > origID) newMasks.Add(storage.masks[origID]);
                    if (storage.dirMaps.Count > origID) newDirMaps.Add(storage.dirMaps[origID]);
                    if (storage.rnmMaps0.Count > origID)
                    {
                        newRNM0Maps.Add(storage.rnmMaps0[origID]);
                        newRNM1Maps.Add(storage.rnmMaps1[origID]);
                        newRNM2Maps.Add(storage.rnmMaps2[origID]);
                        newMapsMode.Add(storage.mapsMode[origID]);
                    }
                }
                storage.maps = newMaps;
                storage.masks = newMasks;
                storage.dirMaps = newDirMaps;
                storage.rnmMaps0 = newRNM0Maps;
                storage.rnmMaps1 = newRNM1Maps;
                storage.rnmMaps2 = newRNM2Maps;
                storage.mapsMode = newMapsMode;

                for(int i=0; i<storage.bakedIDs.Count; i++)
                {
                    int newID = origID2New[storage.bakedIDs[i]];
                    if (newID < 0 || newID > storage.maps.Count) continue;
                    storage.bakedIDs[i] = newID;
                }
#if USE_TERRAINS
                for(int i=0; i<storage.bakedIDsTerrain.Count; i++)
                {
                    int newID = origID2New[storage.bakedIDsTerrain[i]];
                    if (newID < 0 || newID > storage.maps.Count) continue;
                    storage.bakedIDsTerrain[i] = newID;
                }
#endif
            }
        }

        // Patch lightmapped prefabs
        //var bdataName = "BakeryPrefabLightmapData";
        var lmprefabs = FindObjectsOfType(typeof(BakeryLightmappedPrefab)) as BakeryLightmappedPrefab[];
        for(int i=0; i<lmprefabs.Length; i++)
        {
            var p = lmprefabs[i];
            if (!p.gameObject.activeInHierarchy) continue;
            if (!p.IsValid()) continue;

            var pstoreT = p.transform.Find(bdataName);
            if (pstoreT == null)
            {
                var pstoreG = new GameObject();
                pstoreG.name = bdataName;
                pstoreT = pstoreG.transform;
                pstoreT.parent = p.transform;
            }
            var pstore = pstoreT.gameObject.GetComponent<ftLightmapsStorage>();
            if (pstore == null) pstore = pstoreT.gameObject.AddComponent<ftLightmapsStorage>();

            var prenderers = p.GetComponentsInChildren<Renderer>();
#if USE_TERRAINS
            var pterrains = p.GetComponentsInChildren<Terrain>();
#endif
            var plights = p.GetComponentsInChildren<Light>();

            var storage = storages[p.gameObject.scene];

            pstore.bakedRenderers = new List<Renderer>();
            pstore.bakedIDs = new List<int>();
            pstore.bakedScaleOffset = new List<Vector4>();
            pstore.bakedVertexColorMesh = new List<Mesh>();

#if USE_TERRAINS
            pstore.bakedRenderersTerrain = new List<Terrain>();
            pstore.bakedIDsTerrain = new List<int>();
            pstore.bakedScaleOffsetTerrain = new List<Vector4>();
#endif

            pstore.bakedLights = new List<Light>();
            pstore.bakedLightChannels = new List<int>();
            var usedIDs = new Dictionary<int, bool>();
            usedIDs[0] = true; // have to include ID 0 because Unity judges lightmap compression by it

            for(int j=0; j<prenderers.Length; j++)
            {
                var r = prenderers[j];
                int idx = storage.bakedRenderers.IndexOf(r);
                if (idx < 0) continue;
                pstore.bakedRenderers.Add(r);
                pstore.bakedIDs.Add(storage.bakedIDs[idx]);
                pstore.bakedScaleOffset.Add(storage.bakedScaleOffset[idx]);
                pstore.bakedVertexColorMesh.Add(storage.bakedVertexColorMesh[idx]);
                usedIDs[storage.bakedIDs[idx]] = true;
            }

#if USE_TERRAINS
            for(int j=0; j<pterrains.Length; j++)
            {
                var r = pterrains[j];
                int idx = storage.bakedRenderersTerrain.IndexOf(r);
                if (idx < 0) continue;
                pstore.bakedRenderersTerrain.Add(r);
                pstore.bakedIDsTerrain.Add(storage.bakedIDsTerrain[idx]);
                pstore.bakedScaleOffsetTerrain.Add(storage.bakedScaleOffsetTerrain[idx]);
                usedIDs[storage.bakedIDsTerrain[idx]] = true;
            }
#endif

            for(int j=0; j<plights.Length; j++)
            {
                var r = plights[j];
                int idx = storage.bakedLights.IndexOf(r);
                if (idx < 0) continue;
                pstore.bakedLights.Add(r);
                pstore.bakedLightChannels.Add(storage.bakedLightChannels[idx]);
            }

            pstore.maps = new List<Texture2D>();
            pstore.masks = new List<Texture2D>();
            pstore.dirMaps = new List<Texture2D>();
            pstore.rnmMaps0 = new List<Texture2D>();
            pstore.rnmMaps1 = new List<Texture2D>();
            pstore.rnmMaps2 = new List<Texture2D>();
            pstore.mapsMode = new List<int>();
            foreach(var pair in usedIDs)
            {
                int id = pair.Key;
                if (id < 0) continue;
                while(pstore.maps.Count <= id)
                {
                    pstore.maps.Add(null);
                    if (storage.masks.Count > pstore.masks.Count) pstore.masks.Add(null);
                    if (storage.dirMaps.Count > pstore.dirMaps.Count) pstore.dirMaps.Add(null);
                    if (storage.rnmMaps0.Count > pstore.rnmMaps0.Count)
                    {
                        pstore.rnmMaps0.Add(null);
                        pstore.rnmMaps1.Add(null);
                        pstore.rnmMaps2.Add(null);
                        pstore.mapsMode.Add(0);
                    }
                }
                if (storage.maps.Count > id)
                {
                    pstore.maps[id] = storage.maps[id];
                    if (pstore.masks.Count > id) pstore.masks[id] = storage.masks[id];
                    if (pstore.dirMaps.Count > id) pstore.dirMaps[id] = storage.dirMaps[id];
                    if (pstore.rnmMaps0.Count > id)
                    {
                        pstore.rnmMaps0[id] = storage.rnmMaps0[id];
                        pstore.rnmMaps1[id] = storage.rnmMaps1[id];
                        pstore.rnmMaps2[id] = storage.rnmMaps2[id];
                        pstore.mapsMode[id] = storage.mapsMode[id];
                    }
                }
            }

#if UNITY_2018_3_OR_NEWER
            // Unity 2018.3 incorrectly sets lightmap IDs when applying prefabs, UNLESS editor is focused

            if (!verbose) SetForegroundWindow(unityEditorHWND);

            DebugLogInfo("Waiting for Unity editor focus...");
            bool focused = false;
            while(!focused)
            {
                var wnd = GetForegroundWindow();
                while(wnd != (System.IntPtr)0)
                {
                    if (wnd == unityEditorHWND)
                    {
                        focused = true;
                        break;
                    }
                    wnd = GetParent(wnd);
                }
                yield return null;
            }
#endif

            PrefabUtility.ReplacePrefab(p.gameObject, PrefabUtility.GetPrefabParent(p.gameObject), ReplacePrefabOptions.ConnectToPrefab);
            DebugLogInfo("Patched prefab " + p.name);
        }

        ftLightmaps.RefreshFull();
    }

    static void MergeSectorsUpdate()
    {
        if (loadedScenes != null)
        {
            if ( (loadedScenes.Count > EditorSceneManager.sceneCount || EditorSceneManager.GetSceneAt(0).path.Length == 0))
            {
                DebugLogInfo("MergeSectors: waiting for scenes...");
                return;
            }
            MergeSectors();
            DebugLogInfo("MergeSectors: done");
        }
        EditorApplication.update -= MergeSectorsUpdate;
    }

    static void MergeSectorsDeferred()
    {
        EditorApplication.update += MergeSectorsUpdate;
    }

    static public void MergeSectors()
    {
        int sceneCount = EditorSceneManager.sceneCount;
        CollectStorages();

        for(int s=0; s<sceneCount; s++)
        {
            var scene = EditorSceneManager.GetSceneAt(s);
            if (!scene.isLoaded) continue;
            storage = storages[scene];

            // Merge all sectors
            var newMaps = new List<Texture2D>();
            var newMasks = new List<Texture2D>();
            var newDirMaps = new List<Texture2D>();
            var newRNM0Maps = new List<Texture2D>();
            var newRNM1Maps = new List<Texture2D>();
            var newRNM2Maps = new List<Texture2D>();
            var newMapsMode = new List<int>();
            var newBakedRenderers = new List<Renderer>();
#if USE_TERRAINS
            var newBakedRenderersTerrain = new List<Terrain>();
            var newBakedIDsTerrain = new List<int>();
            var newBakedScaleOffsetTerrain = new List<Vector4>();
#endif
            var newBakedIDs = new List<int>();
            var newBakedScaleOffset = new List<Vector4>();
            var newBakedVertexColorMesh = new List<Mesh>();
            HashSet<Renderer> nonBakedSet = null;
            var usedIDs = new HashSet<int>();
            bool anyMasks = false;
            bool anyDirMaps = false;
            bool anyRNMMaps = false;
            int maxMapCount = 0;
            for(int sc=0; sc<storage.sectors.Count; sc++)
            {
                var sect = storage.sectors[sc];
                if (sect.masks != null && sect.masks.Count > 0) anyMasks = true;
                if (sect.dirMaps != null && sect.dirMaps.Count > 0) anyDirMaps = true;
                if (sect.rnmMaps0 != null && sect.rnmMaps0.Count > 0) anyRNMMaps = true;

                if (sect.maps != null) maxMapCount = System.Math.Max(maxMapCount, sect.maps.Count);
            }

            var idRemap = new int[maxMapCount];

            var rendererSet = new HashSet<Renderer>();
#if USE_TERRAINS
            var terrainSet = new HashSet<Terrain>();
#endif
            for(int sc=storage.sectors.Count-1; sc>=0; sc--) // revert order because newest sectors have priority over the global sector
            //for(int sc=0; sc<storage.sectors.Count; sc++)
            {
                var sect = storage.sectors[sc];
                bool hasMasks = (sect.masks != null && sect.masks.Count > 0);
                bool hasDirMaps = (sect.dirMaps != null && sect.dirMaps.Count > 0);
                bool hasRNMMaps = (sect.rnmMaps0 != null && sect.rnmMaps0.Count > 0);
                for(int j=0; j<sect.maps.Count; j++)
                {
                    int exists = newMaps.IndexOf(sect.maps[j]);
                    if (exists >= 0)
                    {
                        idRemap[j] = exists;
                        continue;
                    }

                    idRemap[j] = newMaps.Count;
                    newMaps.Add(sect.maps[j]);

                    bool has = hasMasks && sect.masks.Count > j;
                    if (anyMasks) newMasks.Add(has ? sect.masks[j] : null);

                    has = hasDirMaps && sect.dirMaps.Count > j;
                    if (anyDirMaps)
                    {
                        newDirMaps.Add(has ? sect.dirMaps[j] : null);
                    }

                    if (anyRNMMaps)
                    {
                        has = hasRNMMaps && sect.rnmMaps0.Count > j;
                        newRNM0Maps.Add(has ? sect.rnmMaps0[j] : null);
                        newRNM1Maps.Add(has ? sect.rnmMaps1[j] : null);
                        newRNM2Maps.Add(has ? sect.rnmMaps2[j] : null);
                        newMapsMode.Add(has ? sect.mapsMode[j] : 0);
                    }
                }

                for(int j=0; j<sect.bakedRenderers.Count; j++)
                {
                    var renderer = sect.bakedRenderers[j];
                    if (rendererSet.Contains(renderer)) continue;
                    if (renderer != null)
                    {
                        if ((GameObjectUtility.GetStaticEditorFlags(renderer.gameObject) & StaticEditorFlags.LightmapStatic) == 0)
                        {
                            renderer.lightmapIndex = -1;
                            continue; // skip dynamic
                        }
                        var so = new SerializedObject(renderer);
                        var prop = so.FindProperty("m_ScaleInLightmap");
                        var scaleInLm = prop.floatValue;
                        if (scaleInLm == 0)
                        {
                            renderer.lightmapIndex = -1;
                            continue; // skip scaleInLm=0
                        }
                    }
                    rendererSet.Add(renderer);

                    newBakedRenderers.Add(renderer);
                    newBakedScaleOffset.Add(sect.bakedScaleOffset[j]);
                    newBakedVertexColorMesh.Add(sect.bakedVertexColorMesh.Count > j ? sect.bakedVertexColorMesh[j] : null);

                    int id = sect.bakedIDs[j];
                    if (id >= 0 && id != 0xFFFF)
                    {
                        if (idRemap.Length > id) id = idRemap[id];
                    }
                    newBakedIDs.Add(id);
                    usedIDs.Add(id);
                }

#if USE_TERRAINS
                for(int j=0; j<sect.bakedRenderersTerrain.Count; j++)
                {
                    var terrain = sect.bakedRenderersTerrain[j];
                    if (terrainSet.Contains(terrain)) continue;
                    if (terrain != null)
                    {
                        if ((GameObjectUtility.GetStaticEditorFlags(terrain.gameObject) & StaticEditorFlags.LightmapStatic) == 0) continue; // skip dynamic
                        var so = new SerializedObject(terrain);
                        var prop = so.FindProperty("m_ScaleInLightmap");
                        var scaleInLm = prop.floatValue;
                        if (scaleInLm == 0) continue; // skip scaleInLm=0
                    }
                    terrainSet.Add(terrain);

                    newBakedRenderersTerrain.Add(terrain);
                    newBakedScaleOffsetTerrain.Add(sect.bakedScaleOffsetTerrain[j]);

                    int id = sect.bakedIDsTerrain[j];
                    if (id >= 0 && id != 0xFFFF)
                    {
                        if (idRemap.Length > id) id = idRemap[id];
                    }
                    newBakedIDsTerrain.Add(id);
                    usedIDs.Add(id);
                }
#endif

                if (nonBakedSet == null)
                {
                    nonBakedSet = new HashSet<Renderer>(sect.nonBakedRenderers);
                }
                else
                {
                    nonBakedSet.IntersectWith(sect.nonBakedRenderers);
                }
            }

            // Strip unused
            for(int i=0; i<newMaps.Count; i++)
            {
                if (!usedIDs.Contains(i))
                {
                    newMaps[i] = null;
                    if (newMasks != null && newMasks.Count > i) newMasks[i] = null;
                    if (newDirMaps != null && newDirMaps.Count > i) newDirMaps[i] = null;
                    if (newRNM0Maps != null && newRNM0Maps.Count > i) newRNM0Maps[i] = null;
                    if (newRNM1Maps != null && newRNM1Maps.Count > i) newRNM1Maps[i] = null;
                    if (newRNM2Maps != null && newRNM2Maps.Count > i) newRNM2Maps[i] = null;
                }
            }

            storage.maps = newMaps;
            storage.masks = newMasks;
            storage.dirMaps = newDirMaps;
            storage.rnmMaps0 = newRNM0Maps;
            storage.rnmMaps1 = newRNM1Maps;
            storage.rnmMaps2 = newRNM2Maps;
            storage.mapsMode = newMapsMode;
            storage.bakedRenderers = newBakedRenderers;
#if USE_TERRAINS
            storage.bakedRenderersTerrain = newBakedRenderersTerrain;
            storage.bakedIDsTerrain = newBakedIDsTerrain;
            storage.bakedScaleOffsetTerrain = newBakedScaleOffsetTerrain;
#endif
            storage.bakedIDs = newBakedIDs;
            storage.bakedScaleOffset = newBakedScaleOffset;
            storage.bakedVertexColorMesh = newBakedVertexColorMesh;
            storage.nonBakedRenderers = new List<Renderer>(nonBakedSet);

            EditorUtility.SetDirty(storage);
            EditorSceneManager.MarkAllScenesDirty();

            ftLightmaps.RefreshFull();
        }
    }

    void FindAllReflectionProbesAndDisable()
    {
        var found = FindObjectsOfType(typeof(ReflectionProbe))as ReflectionProbe[];
        for(int i = 0; i < found.Length; i++)
        {
            reflectionProbes.Add(found[i]);
            found[i].enabled = false;
        }
    }

    void ReEnableReflectionProbes()
    {
        for(int i = 0; i < reflectionProbes.Count; i++)
        {
            if (reflectionProbes[i] != null) reflectionProbes[i].enabled = true;
        }
    }

    public static int GetID(GameObject obj, ftLightmapsStorage storage)
    {
        ftLightmapsStorage.LightData data;
        if (storage.lightsDict != null)
        {
            if (storage.lightsDict.TryGetValue(obj, out data)) // try to get stored data
            {
                if (data.UID != 0) return data.UID; // data exists, UID filled, return
                if (storage.uniqueLights != null)
                {
                    data.UID = storage.uniqueLights.IndexOf(obj) + 1; // data exists, no UID (legacy), fill it
                    if (data.UID > 0) return data.UID;
                }
            }
            else
            {
                data = new ftLightmapsStorage.LightData();
                storage.StoreLight(obj, data); // no data, no UID, add, but don't fill everything else so IsLightDirty works
                return data.UID;
            }
        }
        Debug.LogError("No UID for " + obj.name); // no Init called on storage? no uniqueLights?
        return 0;
    }

    string GetLightName(GameObject obj, ftLightmapsStorage storage, int lmid)
    {
        return "light_" + GetID(obj, storage) + "_" + lmid;
    }

    bool IsLightDirty(BakeryLightMesh light)
    {
        if (forceRefresh) return true;

        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data)) {
            return true; // not stored
        }

        if (light.color != data.color) {
            return true;
        }
        if (light.intensity != data.intensity) {
            return true;
        }
        if (light.cutoff != data.range) {
            return true;
        }
        if (light.samples != data.samples) {
            return true;
        }
        if (light.samples2 != data.samples2) {
            return true;
        }
        if (light.selfShadow != data.selfShadow) {
            return true;
        }
        if (light.bakeToIndirect != data.bakeToIndirect) {
            return true;
        }

        var tform1 = light.GetComponent<Transform>().localToWorldMatrix;
        var tform2 = data.tform;
        for(int y=0; y<4; y++) {
            for(int x=0; x<4; x++) {
                if (tform1[x,y] != tform2[x,y]) {
                    return true;
                }
            }
        }

        return false;
    }

    bool IsLightDirty(BakeryPointLight light)
    {
        if (forceRefresh) return true;

        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data)) {
            return true; // not stored
        }

        if (light.color != data.color) {
            return true;
        }
        if (light.intensity != data.intensity) {
            return true;
        }
        if (light.cutoff != data.range) {
            return true;
        }
        if (light.shadowSpread != data.radius) {
            return true;
        }
        if (light.samples != data.samples) {
            return true;
        }
        if (light.realisticFalloff != data.realisticFalloff)
        {
            return true;
        }
        if ((int)light.projMode != data.projMode)
        {
            return true;
        }
        Object cookie = null;
        if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cubemap)
        {
            cookie = light.cubemap;
        } else if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cookie)
        {
            cookie = light.cookie;
        } else if (light.projMode == BakeryPointLight.ftLightProjectionMode.IES)
        {
            cookie = light.iesFile;
        }
        if (cookie != data.cookie) return true;

        if (light.angle != data.angle) return true;

        if (light.bakeToIndirect != data.bakeToIndirect) {
            return true;
        }

        //if (light.texName != data.texName) return true;

        var tform1 = light.GetComponent<Transform>().localToWorldMatrix;
        var tform2 = data.tform;
        for(int y=0; y<4; y++) {
            for(int x=0; x<4; x++) {
                if (tform1[x,y] != tform2[x,y]) {
                    return true;
                }
            }
        }

        return false;
    }

    public static bool IsLightDirty(BakeryDirectLight light)
    {
        if (forceRefresh) return true;

        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data)) return true; // not stored

        if (light.color != data.color) {
            return true;
        }
        if (light.intensity != data.intensity) {
            return true;
        }
        if (light.shadowSpread != data.radius) {
            return true;
        }
        if (light.samples != data.samples) {
            return true;
        }

        if (light.bakeToIndirect != data.bakeToIndirect) {
            return true;
        }

        var tform1 = light.GetComponent<Transform>().localToWorldMatrix;
        var tform2 = data.tform;
        for(int y=0; y<4; y++) {
            for(int x=0; x<4; x++) {
                if (tform1[x,y] != tform2[x,y]) {
                    return true;
                }
            }
        }

        return false;
    }

    bool IsLightDirty(BakerySkyLight light)
    {
        if (forceRefresh) return true;

        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data)) return true; // not stored

        if (light.color != data.color) return true;
        if (light.intensity != data.intensity) return true;
        //if (light.texName != data.texName) return true;
        if (light.samples != data.samples) {
            return true;
        }
        if (light.bakeToIndirect != data.bakeToIndirect) {
            return true;
        }
        if (light.cubemap != data.cookie)
        {
            return true;
        }

        return false;
    }

    void StoreLight(BakeryLightMesh light)
    {
        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data) || data == null)
        {
            data = new ftLightmapsStorage.LightData();
            storage.StoreLight(light.gameObject, data);
        }
        data.color = light.color;
        data.intensity = light.intensity;
        data.range = light.cutoff;
        data.samples = light.samples;
        data.samples2 = light.samples2;
        data.selfShadow = light.selfShadow;
        data.bakeToIndirect = light.bakeToIndirect;
        data.tform = light.GetComponent<Transform>().localToWorldMatrix;
    }

    void StoreLight(BakeryPointLight light)
    {
        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data) || data == null)
        {
            data = new ftLightmapsStorage.LightData();
            storage.StoreLight(light.gameObject, data);
        }
        //var unityLight = light.GetComponent<Light>();
        data.color = light.color;
        data.intensity = light.intensity;
        data.radius = light.shadowSpread;
        data.range = light.cutoff;
        data.samples = light.samples;
        data.bakeToIndirect = light.bakeToIndirect;

        data.realisticFalloff = light.realisticFalloff;
        data.projMode = (int)light.projMode;
        if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cubemap)
        {
            data.cookie = light.cubemap;
        } else if (light.projMode == BakeryPointLight.ftLightProjectionMode.Cookie)
        {
            data.cookie = light.cookie;
        } else if (light.projMode == BakeryPointLight.ftLightProjectionMode.IES)
        {
            data.cookie = light.iesFile;
        }
        data.angle = light.angle;

        //data.texName = light.texName; // TODO: check for cubemap! (and sky too)
        data.tform = light.GetComponent<Transform>().localToWorldMatrix;
    }

    void StoreLight(BakeryDirectLight light)
    {
        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data) || data == null)
        {
            data = new ftLightmapsStorage.LightData();
            storage.StoreLight(light.gameObject, data);
        }
        data.color = light.color;
        data.intensity = light.intensity;
        data.radius = light.shadowSpread;
        data.samples = light.samples;
        data.bakeToIndirect = light.bakeToIndirect;
        data.tform = light.GetComponent<Transform>().localToWorldMatrix;
    }

    void StoreLight(BakerySkyLight light)
    {
        storage = storages[light.gameObject.scene];
        ftLightmapsStorage.LightData data;
        if (!storage.lightsDict.TryGetValue(light.gameObject, out data) || data == null)
        {
            data = new ftLightmapsStorage.LightData();
            storage.StoreLight(light.gameObject, data);
        }
        data.color = light.color;
        data.intensity = light.intensity;
        data.range = 0;
        data.samples = light.samples;
        data.bakeToIndirect = light.bakeToIndirect;
        data.tform = Matrix4x4.identity;
        //data.texName = light.texName;
        data.cookie = light.cubemap;
    }

    void UpdateLightmapShadowmaskFromPointLight(BakeryPointLight obj, int LMID, string lname, string lmname)
    {
        var rmode = currentGroup.renderMode == BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)currentGroup.renderMode;
        if (rmode == (int)RenderMode.Shadowmask && obj.shadowmask)
        {
            var ulht = obj.GetComponent<Light>();
            if (ulht == null && !(obj.shadowmask && obj.bakeToIndirect))
            {
                DebugLogWarning("Light " + obj.name + " set to shadowmask, but doesn't have real-time light");;
            }
            else
            {
                UpdateMaskArray(LMID, lname, lmname, ulht, obj, false);
            }
        }
    }

    void UpdateLightmapShadowmaskFromAreaLight(BakeryLightMesh obj, int LMID, string lname, string lmname)
    {
        if (userRenderMode == RenderMode.Shadowmask && obj.shadowmask)
        {
            var ulht = obj.GetComponent<Light>();
            if (ulht == null)
            {
                DebugLogWarning("Light " + obj.name + " set to shadowmask, but doesn't have real-time light");;
            }
            else
            {
                UpdateMaskArray(LMID, lname, lmname, ulht, null, false);
            }
        }
    }

    bool WriteCompFiles(BakeryPointLight obj, ComposeInstructionFiles cif, string lname, int rmode, bool dominantDirMode, bool rnmMode, bool shMode, bool shModeProbe)
    {
        bool usesIndirectIntensity = false;

        cif.fcomp.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
        if (bounces > 0)
        {
            cif.fcomp.Write(obj.indirectIntensity * hackIndirectBoost);
            if (Mathf.Abs(obj.indirectIntensity - 1.0f) > 0.01f) usesIndirectIntensity = true;
        }

        if ((rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask)
                && obj.bakeToIndirect)
        {
            cif.fcompIndirect.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
            if (cif.fcompDirIndirect != null)
            {
                cif.fcompDirIndirect.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                cif.fcompDirIndirect.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
            }
        }

        bool rmodeFullLight = (rmode == (int)RenderMode.FullLighting || rmode == (int)RenderMode.Subtractive);

        if (dominantDirMode && (rmodeFullLight || obj.bakeToIndirect))
        {
            cif.fcompDir.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
            cif.fcompDir.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
        }
        else if (rnmMode && (rmodeFullLight || obj.bakeToIndirect))
        {
            cif.fcompRNM0.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
            cif.fcompRNM1.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
            cif.fcompRNM2.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
        }
        else if (shMode && (rmodeFullLight || obj.bakeToIndirect))
        {
            cif.fcompSH.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
            cif.fcompSH.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
            cif.fcompSH.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
            cif.fcompSH.Write(lname + "_RNM3" + (compressedOutput ? ".lz4" : ".dds"));
        }

        return usesIndirectIntensity;
    }

    void AddPointLightCommandLine(string renderMode, string lname, string settingsFile, string progressText, int LMID, BakeryPointLight obj,
                                                int rmode, bool dominantDirMode, bool rnmMode, bool shMode, bool shModeProbe, bool legacySampling)
    {
        var startInfo = new System.Diagnostics.ProcessStartInfo();
        startInfo.CreateNoWindow  = false;
        startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
        startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
        startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
        startInfo.CreateNoWindow = true;

        bool rmodeFullLight = (rmode == (int)RenderMode.FullLighting || rmode == (int)RenderMode.Subtractive);

        int passes = PASS_HALF;
        if (dominantDirMode && (rmodeFullLight || obj.bakeToIndirect))
        {
            passes |= PASS_DIRECTION;
        }
        else if (rnmMode && (rmodeFullLight || obj.bakeToIndirect))
        {
            renderMode += "rnm";
            if (bounces == 0) passes = 0;
            passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2;
        }
        else if (shMode && (rmodeFullLight || obj.bakeToIndirect || shModeProbe))
        {
            renderMode += shModeProbe ? "probesh" : "sh";
            if (bounces == 0) passes = 0;
            passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2 | PASS_RNM3;
        }
        if (userRenderMode == RenderMode.Shadowmask && obj.shadowmask)
        {
            passes |= PASS_MASK;
            if (currentGroup.transparentSelfShadow) passes |= PASS_MASK1;
            hasAnyShadowmasks = true;
        }
        if (legacySampling)
        {
            renderMode += "legacy";
        }

        startInfo.Arguments       = renderMode + " " + scenePathQuoted + " \"" + lname + "\" " + passes + " " + 0 + " " + LMID + " " + settingsFile;

        deferredFileSrc.Add("");//scenePath + "/pointlight" + i + ".bin");
        deferredFileDest.Add("");//scenePath + "/pointlight.bin");
        deferredCommands.Add(startInfo);
        deferredCommandDesc.Add(progressText);
    }

    string PrepareBatchPointLight(int start, int end, int LMID, bool[] skipLight, ComposeInstructionFiles cif, int rmode, bool dominantDirMode, bool rnmMode, bool shMode, bool shModeProbe, ref bool usesIndirectIntensity)
    {
        string lname = "PointBatch_" + LMID + "_" + start + "_" + end;
        bool first = true;
        //Debug.LogError("----- Group:");
        for(int j=start; j<=end; j++)
        {
            if (skipLight[j]) continue;

            //Debug.LogError(AllP[j]);

            // For every light in a batch
            UpdateLightmapShadowmaskFromPointLight(AllP[j], LMID, lname, currentGroup.name);
            if (first)
            {
                // Once for the whole batch
                if (WriteCompFiles(AllP[j], cif, lname, rmode, dominantDirMode, rnmMode, shMode, shModeProbe)) usesIndirectIntensity = true;
                first = false;
            }
        }
        return lname;
    }

    class ComposeInstructionFiles
    {
        public BinaryWriter fcomp = null;
        public BinaryWriter fcompIndirect = null;
        public BinaryWriter fcompDir = null;
        public BinaryWriter fcompDirIndirect = null;
        public BinaryWriter fcompRNM0 = null;
        public BinaryWriter fcompRNM1 = null;
        public BinaryWriter fcompRNM2 = null;
        public BinaryWriter fcompSH = null;

        public void Close()
        {
            if (fcomp != null) fcomp.Close();
            if (fcompIndirect != null) fcompIndirect.Close();
            if (fcompDirIndirect != null) fcompDirIndirect.Close();
            if (fcompDir != null) fcompDir.Close();
            if (fcompRNM0 != null) fcompRNM0.Close();
            if (fcompRNM1 != null) fcompRNM1.Close();
            if (fcompRNM2 != null) fcompRNM2.Close();
            if (fcompSH != null) fcompSH.Close();
        }
    }

    IEnumerator RenderLMDirect(int LMID, string lmname, int resolution)
    {
        System.Diagnostics.ProcessStartInfo startInfo;
        //System.Diagnostics.Process exeProcess;

        bool doCompose = exeMode;

        var cif = new ComposeInstructionFiles();

        long fcompStartPos = 0;
        bool usesIndirectIntensity = Mathf.Abs(hackIndirectBoost - 1.0f) > 0.001f;
        var rmode = currentGroup.renderMode == BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)currentGroup.renderMode;
        var dirMode = currentGroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)currentGroup.renderDirMode;
        var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection;
        var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM;
        var shMode = dirMode == (int)ftRenderLightmap.RenderDirMode.SH || dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH;
        var shModeProbe = dirMode == (int)BakeryLightmapGroup.RenderDirMode.ProbeSH;
        if (shModeProbe) shMode = true;

        if (rmode == (int)RenderMode.AmbientOcclusionOnly)
        {
            if (dominantDirMode) lightmapHasDir[LMID] = true;
            yield break;
        }

        bool rmodeFullLight = (rmode == (int)RenderMode.FullLighting || rmode == (int)RenderMode.Subtractive);

        lightmapHasMask[LMID] = 0;

        if (doCompose)
        {
            var fcompName = "comp_" + LMID + ".bin";
            cif.fcomp = new BinaryWriter(File.Open(scenePath + "/" + fcompName, FileMode.Create));
            if (clientMode) ftClient.serverFileList.Add(fcompName);
            if (bounces > 0)
            {
                cif.fcomp.Write(false);
                cif.fcomp.Write("uvalbedo_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));

                if (storage.hasEmissive.Count > LMID && storage.hasEmissive[LMID])
                {
                    cif.fcomp.Write("uvemissive_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
                }
                else
                {
                    cif.fcomp.Write("");
                }
            }

            if (rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask)
            {
                cif.fcompIndirect = new BinaryWriter(File.Open(scenePath + "/comp_indirect" + LMID + ".bin", FileMode.Create));
                if (clientMode) ftClient.serverFileList.Add("comp_indirect" + LMID + ".bin");
                if (bounces > 0)
                {
                    cif.fcompIndirect.Write(lmname + "_final_HDR2" + (compressedOutput ? ".lz4" : ".dds"));
                }
                if (currentGroup.computeSSS && !rnmMode && !shMode)
                {
                    cif.fcompIndirect.Write(lmname + "_SSS_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                }
                if (dominantDirMode)
                {
                    cif.fcompDirIndirect = new BinaryWriter(File.Open(scenePath + "/dircomp_indirect" + LMID + ".bin", FileMode.Create));
                    if (clientMode) ftClient.serverFileList.Add("dircomp_indirect" + LMID + ".bin");
                    cif.fcompDirIndirect.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
                    if (bounces > 0)
                    {
                        cif.fcompDirIndirect.Write(lmname + "_final_HDR2" + (compressedOutput ? ".lz4" : ".dds"));
                        cif.fcompDirIndirect.Write(lmname + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds"));
                    }
                }
            }
            if (dominantDirMode)
            {
                cif.fcompDir = new BinaryWriter(File.Open(scenePath + (deferredMode ? "/dircomp_" + LMID + ".bin" : "/dircomp.bin"), FileMode.Create));
                cif.fcompDir.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
                if (clientMode) ftClient.serverFileList.Add("dircomp_" + LMID + ".bin");
            }
            if (rnmMode)
            {
                cif.fcompRNM0 = new BinaryWriter(File.Open(scenePath + (deferredMode ? "/rnm0comp_" + LMID + ".bin" : "/rnm0comp.bin"), FileMode.Create));
                cif.fcompRNM1 = new BinaryWriter(File.Open(scenePath + (deferredMode ? "/rnm1comp_" + LMID + ".bin" : "/rnm1comp.bin"), FileMode.Create));
                cif.fcompRNM2 = new BinaryWriter(File.Open(scenePath + (deferredMode ? "/rnm2comp_" + LMID + ".bin" : "/rnm2comp.bin"), FileMode.Create));

                if (clientMode)
                {
                    ftClient.serverFileList.Add("rnm0comp_" + LMID + ".bin");
                    ftClient.serverFileList.Add("rnm1comp_" + LMID + ".bin");
                    ftClient.serverFileList.Add("rnm2comp_" + LMID + ".bin");
                }

                if (bounces > 0)
                {
                    cif.fcompRNM0.Write(lmname + "_final_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompRNM1.Write(lmname + "_final_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompRNM2.Write(lmname + "_final_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                }
            }
            if (shMode)
            {
                cif.fcompSH = new BinaryWriter(File.Open(scenePath + (deferredMode ? "/shcomp_" + LMID + ".bin" : "/shcomp.bin"), FileMode.Create));
                if (clientMode) ftClient.serverFileList.Add("shcomp_" + LMID + ".bin");
                if (bounces > 0)
                {
                    cif.fcompSH.Write(lmname + "_final_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lmname + "_final_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lmname + "_final_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lmname + "_final_RNM3" + (compressedOutput ? ".lz4" : ".dds"));
                }
                if (currentGroup.computeSSS)
                {
                    cif.fcompSH.Write(lmname + "_SSS_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lmname + "_SSS_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lmname + "_SSS_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lmname + "_SSS_RNM3" + (compressedOutput ? ".lz4" : ".dds"));
                }
            }
        }
        fcompStartPos = cif.fcomp.BaseStream.Position;

        // Area lights
        for(int i=0; i<All.Length; i++)
        {
            progressStepsDone++;

            var obj = All[i] as BakeryLightMesh;
            if (!obj.enabled) continue;
            if ((obj.bitmask & currentGroup.bitmask) == 0) continue;

            var lmr = ftBuildGraphics.GetValidRenderer(obj.gameObject);
            var lma = obj.GetComponent<Light>();
            if (lmr == null && lma == null) continue;

            bool isArea = lma != null && ftLightMeshInspector.IsArea(lma);

            if (isArea)
            {
                lmr = null;
            }
            else if (ftBuildGraphics.GetSharedMesh(obj.gameObject) != null)
            {
                lma = null;
            }
            else
            {
                Debug.LogError("Light mesh " + obj.name + " must have either a mesh or an area light");
                continue;
            }

            Bounds lBounds;
            Vector3[] corners = null;
            if (lma != null)
            {
                corners = ftLightMeshInspector.GetAreaLightCorners(lma);
                lBounds = new Bounds(corners[0], Vector3.zero);
                lBounds.Encapsulate(corners[1]);
                lBounds.Encapsulate(corners[2]);
                lBounds.Encapsulate(corners[3]);
            }
            else
            {
                var lmrState = lmr.enabled;
                lmr.enabled = true;
                lBounds = lmr.bounds;
                lmr.enabled = lmrState;
            }

            lBounds.Expand(new Vector3(obj.cutoff, obj.cutoff, obj.cutoff));
            if (!lBounds.Intersects(storage.bounds[LMID])) continue;

            var lname = GetLightName(obj.gameObject, storage, LMID);
            UpdateLightmapShadowmaskFromAreaLight(obj, LMID, lname, lmname);

            if (doCompose)
            {
                cif.fcomp.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                if (bounces > 0)
                {
                    cif.fcomp.Write(obj.indirectIntensity * hackIndirectBoost);
                    if (Mathf.Abs(obj.indirectIntensity - 1.0f) > 0.01f) usesIndirectIntensity = true;
                }

                if ((rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask)
                        && obj.bakeToIndirect)
                {
                    cif.fcompIndirect.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                    if (cif.fcompDirIndirect != null)
                    {
                        cif.fcompDirIndirect.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                        cif.fcompDirIndirect.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
                    }
                }
            }

            string renderMode;
            int passes = PASS_HALF;
            if (dominantDirMode && (rmodeFullLight || obj.bakeToIndirect))
            {
                renderMode = obj.texture == null ? "arealightdir" : "texarealightdir";
                passes |= PASS_DIRECTION;

                cif.fcompDir.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                cif.fcompDir.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
            }
            else if (rnmMode && (rmodeFullLight || obj.bakeToIndirect))
            {
                renderMode = obj.texture == null ? "arealightrnm" : "texarealightrnm";
                if (bounces == 0) passes = 0;
                passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2;

                cif.fcompRNM0.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                cif.fcompRNM1.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                cif.fcompRNM2.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
            }
            else if (shMode && (rmodeFullLight || obj.bakeToIndirect || shModeProbe))
            {
                if (shModeProbe) {
                    renderMode = obj.texture == null ? "arealightprobesh" : "texarealightprobesh";
                } else {
                    renderMode = obj.texture == null ? "arealightsh" : "texarealightsh";
                }
                if (bounces == 0) passes = 0;
                passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2 | PASS_RNM3;

                cif.fcompSH.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                cif.fcompSH.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                cif.fcompSH.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                cif.fcompSH.Write(lname + "_RNM3" + (compressedOutput ? ".lz4" : ".dds"));
            }
            else
            {
                renderMode = obj.texture == null ? "arealight" : "texarealight";
            }

            if (rmode == (int)RenderMode.Shadowmask && obj.shadowmask)
            {
                passes |= PASS_MASK;
                hasAnyShadowmasks = true;
            }

            if (!performRendering) continue;

            ftBuildLights.BuildLight(obj, SampleCount(obj.samples), corners, deferredMode ? ("lights" + i + ".bin") : "lights.bin");


            var pth = scenePath + "/" + lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds");
            if (!IsLightDirty(obj) && File.Exists(pth)) continue;// && new FileInfo(pth).Length == 128+size*size*8) continue;

            string progressText = "Rendering area light " + obj.name + " for " + lmname + "...";
            if (!deferredMode) ProgressBarShow(progressText, (progressStepsDone / (float)progressSteps), true);
            if (userCanceled)
            {
                if (doCompose)
                {
                    cif.fcomp.Close();
                    if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
                    if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
                    if (cif.fcompDir != null) cif.fcompDir.Close();
                    if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
                    if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
                    if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
                    if (cif.fcompSH != null) cif.fcompSH.Close();
                }
                yield break;
            }
            yield return null;

            DebugLogInfo("Preparing light " + obj.name + "...");

            int errCode = 0;
            if (exeMode)
            {
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;
                /*if (userRenderMode == RenderMode.Shadowmask && obj.shadowmask)
                {
                    passes |= PASS_MASK;
                }*/
                startInfo.Arguments       = renderMode + " " + scenePathQuoted + " \"" + lname + "\" " + passes + " " + 0 + " " + LMID + " lights" + i + ".bin";

                if (deferredMode)
                {
                    deferredFileSrc.Add("");//scenePath + "/lights" + i + ".bin");
                    deferredFileDest.Add("");//scenePath + "/lights.bin");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText);
                }
                else
                {
                    /*Debug.Log("Running ftrace " + startInfo.Arguments);
                    exeProcess = System.Diagnostics.Process.Start(startInfo);
                    exeProcess.WaitForExit();
                    errCode = exeProcess.ExitCode;*/
                }
            }
            if (errCode != 0)
            {
                DebugLogError("ftrace error: " + ftErrorCodes.TranslateFtrace(errCode, rtxMode));
                userCanceled = true;
                if (doCompose)
                {
                    cif.fcomp.Close();
                    if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
                    if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
                    if (cif.fcompDir != null) cif.fcompDir.Close();
                    if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
                    if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
                    if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
                    if (cif.fcompSH != null) cif.fcompSH.Close();
                }
                yield break;//return false;
            }

            //StoreLight(obj);
        }

        // Point lights
        int start = 0;
        int end = 0;
        int sampleCounter = 0;
        int channel = -1;
        bool bakeToIndirect = false;
        bool legacySampling = true;
        float indirectIntensity = 1.0f;
        bool[] skipLight = null;
        int addedLights = 0;
        if (ftAdditionalConfig.batchPointLights)
        {
            if (AllP.Length > 0)
            {
                channel = GetShadowmaskChannel(AllP[0]);
                bakeToIndirect = AllP[0].bakeToIndirect;
                indirectIntensity = AllP[0].indirectIntensity;
                legacySampling = AllP[0].legacySampling;
            }
            skipLight = new bool[AllP.Length];
        }
        for(int i=0; i<AllP.Length; i++)
        {
            progressStepsDone++;
            if (ftAdditionalConfig.batchPointLights) skipLight[i] = true;

            // Cull the light
            var obj = AllP[i] as BakeryPointLight;
            if (!obj.enabled) continue;
            if ((obj.bitmask & currentGroup.bitmask) == 0) continue;

            var boundsRange = obj.cutoff * 2;//obj.GetComponent<Light>().range * 2;
            var lBounds = new Bounds(obj.transform.position, new Vector3(boundsRange, boundsRange, boundsRange));
            if (!lBounds.Intersects(storage.bounds[LMID])) continue;

            string lname = "";
            string settingsFile = "";

            // Split in batches if needed
            bool bakeBatch = false;
            if (ftAdditionalConfig.batchPointLights)
            {
                skipLight[i] = false;
                addedLights++;
                bool split = false;

                // Split by bakeToIndirect
                if (AllP[i].bakeToIndirect != bakeToIndirect)
                {
                    split = true;
                    bakeToIndirect = AllP[i].bakeToIndirect;
                }

                // Split by indirectIntensity
                if (AllP[i].indirectIntensity != indirectIntensity)
                {
                    split = true;
                    indirectIntensity = AllP[i].indirectIntensity;
                }

                // Split by shadowmask channel
                var objChannel = GetShadowmaskChannel(AllP[i]);
                if (objChannel != channel)
                {
                    split = true;
                    channel = objChannel;
                }

                // Split by count
                int newSampleCount = sampleCounter + AllP[i].samples;
                if (newSampleCount > maxSamplesPerPointLightBatch)
                {
                    split = true;
                    sampleCounter = 0;
                }

                // Split by legacySampling
                if (AllP[i].legacySampling != legacySampling)
                {
                    split = true;
                    legacySampling = AllP[i].legacySampling;
                }

                sampleCounter += AllP[i].samples;

                if (split)
                {
                    end = i-1;
                    lname = PrepareBatchPointLight(start, end, LMID, skipLight, cif, rmode, dominantDirMode, rnmMode, shMode, shModeProbe, ref usesIndirectIntensity);
                    settingsFile = "batchpointlight_" + LMID + "_" + start + "_" + end + ".bin";
                    bakeBatch = true;
                }
            }
            else
            {
                // Update shadowmask settings for LMGroup
                lname = GetLightName(obj.gameObject, storage, LMID);
                UpdateLightmapShadowmaskFromPointLight(obj, LMID, lname, lmname);

                // Update composing instructions
                if (WriteCompFiles(obj, cif, lname, rmode, dominantDirMode, rnmMode, shMode, shModeProbe)) usesIndirectIntensity = true;

                settingsFile = "pointlight" + i + ".bin";
            }

            if (!performRendering) continue;

            if (ftAdditionalConfig.batchPointLights)
            {
                if (bakeBatch)
                {
                    // Export batch light data and textures
                    bool isError = ftBuildLights.BuildLights(AllP, start, end, skipLight, sampleDivisor, shModeProbe, settingsFile); // TODO: dirty tex detection!!
                    if (isError)
                    {
                        userCanceled = true;
                        cif.Close();
                        yield break;
                    }

                    // Cancel
                    if (userCanceled)
                    {
                        cif.Close();
                        yield break;
                    }
                    yield return null;

                    // Generate batch command line
                    string renderMode = "batchpointlight";
                    string progressText = "Rendering point light batch (" + (start) + "-" + (end) + ") for " + lmname + "...";
                    AddPointLightCommandLine(renderMode, lname, settingsFile, progressText, LMID, AllP[start], rmode, dominantDirMode, rnmMode, shMode, shModeProbe, AllP[start].legacySampling);

                    start = i;
                }
            }
            else
            {
                // Export light data and textures
                bool isError = ftBuildLights.BuildLight(obj, SampleCount(obj.samples), true, false, settingsFile); // TODO: dirty tex detection!!
                if (isError)
                {
                    userCanceled = true;
                    cif.Close();
                    yield break;
                }
                if (obj.projMode != 0)
                {
                    //yield return new WaitForEndOfFrame();
                    //yield return new WaitForSeconds(1); // ?????
                    yield return null;
                }

                // Check if "update unmodified lights" is off, and this light was modified
                var pth = scenePath + "/" + lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds");
                if (!IsLightDirty(obj) && File.Exists(pth)) continue;// && new FileInfo(pth).Length == 128+size*size*8) continue;

                // Get ftrace rendermode
                string renderMode = GetPointLightRenderMode(obj);

                // Progressbar
                string progressText = "Rendering point light " + obj.name + " for " + lmname + "...";

                // Cancel
                if (userCanceled)
                {
                    cif.Close();
                    yield break;
                }
                yield return null;

                // Generate command line
                AddPointLightCommandLine(renderMode, lname, settingsFile, progressText, LMID, AllP[i], rmode, dominantDirMode, rnmMode, shMode, shModeProbe, true);
            }
        }
        if (ftAdditionalConfig.batchPointLights && addedLights > 0)
        {
            end = AllP.Length-1;
            string lname = PrepareBatchPointLight(start, end, LMID, skipLight, cif, rmode, dominantDirMode, rnmMode, shMode, shModeProbe, ref usesIndirectIntensity);
            string settingsFile = "batchpointlight_" + LMID + "_" + start + "_" + end + ".bin";
            string renderMode = "batchpointlight";
            string progressText = "Rendering point light batch (" + (start) + "-" + (end) + ") for " + lmname + "...";
            bool isError = ftBuildLights.BuildLights(AllP, start, end, skipLight, sampleDivisor, shModeProbe, settingsFile); // TODO: dirty tex detection!!
            if (isError)
            {
                userCanceled = true;
                cif.Close();
                yield break;
            }
            AddPointLightCommandLine(renderMode, lname, settingsFile, progressText, LMID, AllP[start], rmode, dominantDirMode, rnmMode, shMode, shModeProbe, AllP[start].legacySampling);
        }

        // Skylight
        for(int i=0; i<All2.Length; i++)
        {
            progressStepsDone++;

            var obj = All2[i] as BakerySkyLight;
            if (!obj.enabled) continue;
            if ((obj.bitmask & currentGroup.bitmask) == 0) continue;

            if (obj.tangentSH && verbose && !askedTangentSH)
            {
                if (!EditorUtility.DisplayDialog("Bakery", "Skylight '"+obj.name+"' has Tangent-space SH enabled. This is an advanced mode generally useful for dynamic object occlusion baking, requiring special shaders. Are you sure you want to continue?", "OK", "Cancel"))
                {
                    userCanceled = true;
                    ProgressBarEnd();
                }
                askedTangentSH = true;
            }

            var lname = GetLightName(obj.gameObject, storage, LMID);
            if (doCompose)
            {
                cif.fcomp.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                if (bounces > 0)
                {
                    cif.fcomp.Write(obj.indirectIntensity * hackIndirectBoost);
                    if (Mathf.Abs(obj.indirectIntensity - 1.0f) > 0.01f) usesIndirectIntensity = true;
                }

                if ((rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask)
                        && obj.bakeToIndirect)
                {
                    cif.fcompIndirect.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                    if (cif.fcompDirIndirect != null)
                    {
                        cif.fcompDirIndirect.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                        cif.fcompDirIndirect.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
                    }
                }

                if (dominantDirMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    cif.fcompDir.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompDir.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
                }
                else if (rnmMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    cif.fcompRNM0.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompRNM1.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompRNM2.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                }
                else if (shMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    cif.fcompSH.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lname + "_RNM3" + (compressedOutput ? ".lz4" : ".dds"));
                }
            }

            if (!performRendering) continue;

            /*
            if (!storage.skylights.Contains(obj))
            {
                storage.skylights.Add(obj);
                storage.skylightsDirty.Add(true);
            }
            var skylightIndex = storage.skylights.IndexOf(obj);
            */
            var texDirty = obj.cubemap != null;//true;//storage.skylightsDirty[skylightIndex];

            ftBuildLights.BuildSkyLight(obj, SampleCount(obj.samples), texDirty, deferredMode ? "sky" + i + ".bin" : "sky.bin");

            if (texDirty)
            {
                //yield return new WaitForEndOfFrame();
                yield return new WaitForSeconds(1);
            }

            //storage.skylightsDirty[skylightIndex] = false;

            var pth = scenePath + "/" + lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds");
            if (!IsLightDirty(obj) && File.Exists(pth)) continue;// && new FileInfo(pth).Length == 128+size*size*8) continue;

            string progressText = "Rendering sky light " + obj.name + " for " + lmname + "...";
            if (!deferredMode) ProgressBarShow(progressText, (progressStepsDone / (float)progressSteps), true);
            if (userCanceled)
            {
                if (doCompose)
                {
                    cif.fcomp.Close();
                    if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
                    if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
                    if (cif.fcompDir != null) cif.fcompDir.Close();
                    if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
                    if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
                    if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
                    if (cif.fcompSH != null) cif.fcompSH.Close();
                }
                yield break;
            }
            yield return null;

            var bakeDir = (dominantDirMode && (rmodeFullLight || obj.bakeToIndirect));
            var bakeRNM = (rnmMode && (rmodeFullLight || obj.bakeToIndirect));
            var bakeSH = (shMode && (rmodeFullLight || obj.bakeToIndirect || shModeProbe));
            string renderMode;
            if (obj.cubemap != null)
            {
                if (bakeDir)
                {
                    renderMode = "skycubemapdir";
                }
                else if (bakeRNM)
                {
                    renderMode = "skycubemaprnm";
                }
                else if (bakeSH)
                {
                    renderMode = shModeProbe ? "skycubemapprobesh" : "skycubemapsh";
                }
                else
                {
                    renderMode = "skycubemap";
                }
            }
            else
            {
                if (bakeDir)
                {
                    renderMode = "skydir";
                }
                else if (bakeRNM)
                {
                    renderMode = "skyrnm";
                }
                else if (bakeSH)
                {
                    renderMode = (obj.tangentSH && !shModeProbe) ? "skytangentsh" : (shModeProbe ? "skyprobesh" : "skysh");
                }
                else
                {
                    renderMode = "sky";
                }
            }

            int errCode = 0;
            if (exeMode)
            {
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;
                int passes = PASS_HALF;
                if (bakeDir) passes |= PASS_DIRECTION;
                if ((bakeRNM || bakeSH) && bounces == 0) passes = 0;
                if (bakeRNM) passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2;
                if (bakeSH) passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2 | PASS_RNM3;
                startInfo.Arguments       =  renderMode + " " + scenePathQuoted + " \"" + lname + "\" " + passes + " " + 0 + " " + LMID + " sky" + i + ".bin";

                if (deferredMode)
                {
                    deferredFileSrc.Add("");//scenePath + "/sky" + i + ".bin");
                    deferredFileDest.Add("");//scenePath + "/sky.bin");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText);
                }
                else
                {
                    /*Debug.Log("Running ftrace " + startInfo.Arguments);
                    exeProcess = System.Diagnostics.Process.Start(startInfo);
                    exeProcess.WaitForExit();
                    errCode = exeProcess.ExitCode;*/
                }
            }

            if (errCode != 0)
            {
                DebugLogError("ftrace error: "+ftErrorCodes.TranslateFtrace(errCode, rtxMode));
                userCanceled = true;
                if (doCompose)
                {
                    cif.fcomp.Close();
                    if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
                    if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
                    if (cif.fcompDir != null) cif.fcompDir.Close();
                    if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
                    if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
                    if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
                    if (cif.fcompSH != null) cif.fcompSH.Close();
                }
                yield break;
            }
            //StoreLight(obj);
        }

        // Directional light
        for(int i=0; i<All3.Length; i++)
        {
            progressStepsDone++;

            var obj = All3[i] as BakeryDirectLight;
            if (!obj.enabled) continue;
            if ((obj.bitmask & currentGroup.bitmask) == 0) continue;

            var lname = GetLightName(obj.gameObject, storage, LMID);
            if (doCompose && rmode == (int)RenderMode.Shadowmask && obj.shadowmask)
            {
                var ulht = obj.GetComponent<Light>();
                if (ulht == null)
                {
                    DebugLogWarning("Light " + obj.name + " set to shadowmask, but doesn't have real-time light");;
                }
                else
                {
                    UpdateMaskArray(currentGroup.id, lname, lmname, ulht, null, obj.shadowmaskDenoise);
                }
            }

            if (doCompose)
            {
                var texName = lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds");
                cif.fcomp.Write(texName);
                if (bounces > 0)
                {
                    cif.fcomp.Write(obj.indirectIntensity * hackIndirectBoost);
                    if (Mathf.Abs(obj.indirectIntensity - 1.0f) > 0.01f) usesIndirectIntensity = true;
                }

                if ((rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask)
                        && obj.bakeToIndirect)
                {
                    cif.fcompIndirect.Write(texName);
                    if (cif.fcompDirIndirect != null)
                    {
                        cif.fcompDirIndirect.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                        cif.fcompDirIndirect.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
                    }
                }

                if (dominantDirMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    cif.fcompDir.Write(lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompDir.Write(lname + "_Dir" + (compressedOutput ? ".lz4" : ".dds"));
                }
                else if (rnmMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    cif.fcompRNM0.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompRNM1.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompRNM2.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                }
                else if (shMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    cif.fcompSH.Write(lname + "_RNM0" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lname + "_RNM1" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lname + "_RNM2" + (compressedOutput ? ".lz4" : ".dds"));
                    cif.fcompSH.Write(lname + "_RNM3" + (compressedOutput ? ".lz4" : ".dds"));
                }
            }

            if (!performRendering) continue;

            ftBuildLights.BuildDirectLight(obj, SampleCount(obj.samples), false, deferredMode ? "direct" + i + ".bin" : "direct.bin");

            if (hasAnyVolumes)
            {
                ftBuildLights.BuildDirectLight(obj, SampleCount(obj.samples), true, deferredMode ? "direct" + i + "_volumes.bin" : "direct.bin");
            }

            var pth = scenePath + "/" + lname + "_HDR" + (compressedOutput ? ".lz4" : ".dds");
            if (!IsLightDirty(obj) && File.Exists(pth)) continue;// && new FileInfo(pth).Length == 128+size*size*8) continue;
            //Debug.Log(IsLightDirty(obj)+" "+File.Exists(pth)+" "+(new FileInfo(pth).Length == 128+size*size*8));

            string progressText = "Rendering direct light " + obj.name + " for " + lmname + "...";
            if (!deferredMode) ProgressBarShow(progressText, (progressStepsDone / (float)progressSteps), true);
            if (userCanceled)
            {
                if (doCompose)
                {
                    cif.fcomp.Close();
                    if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
                    if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
                    if (cif.fcompDir != null) cif.fcompDir.Close();
                    if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
                    if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
                    if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
                    if (cif.fcompSH != null) cif.fcompSH.Close();
                }
                yield break;
            }
            yield return null;

            int errCode = 0;
            if (exeMode)
            {
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;

                int passes = PASS_HALF;
                bool allowSupersample = !shModeProbe;
                if (currentGroup != null && currentGroup.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex) allowSupersample = false;
                string rrmode = GetSunRenderMode(obj, allowSupersample); // no SHProbe mode for supersample
                if (dominantDirMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    passes |= PASS_DIRECTION;
                }
                else if (rnmMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    rrmode += "rnm";
                    if (bounces == 0) passes = 0;
                    passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2;
                }
                else if (shMode && (rmodeFullLight || obj.bakeToIndirect))
                {
                    rrmode += shModeProbe ? "probesh" : "sh";
                    if (bounces == 0) passes = 0;
                    passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2 | PASS_RNM3;
                }
                if (userRenderMode == RenderMode.Shadowmask && obj.shadowmask)
                {
                    passes |= PASS_MASK;
                    if (currentGroup.transparentSelfShadow) passes |= PASS_MASK1;
                    hasAnyShadowmasks = true;
                }

                startInfo.Arguments       =  rrmode + " " + scenePathQuoted + " \"" + lname + "\" " + passes + " " + 0 + " " + LMID +
                    " direct" + i + ((currentGroup.probes && currentGroup.name == "volumes") ? "_volumes" : "") + ".bin";

                deferredFileSrc.Add("");//scenePath + "/direct" + i + ".bin");
                deferredFileDest.Add("");//scenePath + "/direct.bin");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText);
            }

            if (errCode != 0)
            {
                DebugLogError("ftrace error: "+ftErrorCodes.TranslateFtrace(errCode, rtxMode));
                userCanceled = true;
                if (doCompose)
                {
                    cif.fcomp.Close();
                    if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
                    if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
                    if (cif.fcompDir != null) cif.fcompDir.Close();
                    if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
                    if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
                    if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
                    if (cif.fcompSH != null) cif.fcompSH.Close();
                }
                yield break;//return false;
            }
            //StoreLight(obj);
        }

        lmnameComposed[lmname] = true;

        if (dominantDirMode && cif.fcompDir.BaseStream.Position > 0)
        {
            lightmapHasDir[LMID] = true;
        }

        if (rnmMode && cif.fcompRNM0.BaseStream.Position > 0)
        {
            lightmapHasRNM[LMID] = true;
        }

        if (shMode && cif.fcompSH.BaseStream.Position > 0)
        {
            lightmapHasRNM[LMID] = true;
        }

        if (cif.fcomp.BaseStream.Position == fcompStartPos)
        {
            cif.fcomp.Write(lmname + "_lights_HDR.dds");

            /*cif.fcomp.Close();
            if (cif.fcompIndirect != null) cif.fcompIndirect.Close();*/
            DebugLogInfo("No lights for " + lmname);

            var fpos = new BinaryWriter(File.Open(scenePath + "/" + lmname + "_lights_HDR.dds", FileMode.Create));
            if (clientMode) ftClient.serverFileList.Add(lmname + "_lights_HDR.dds");
            //var fpos = new BinaryWriter(File.Open(scenePath + "/" + lmname + "_diffuse_HDR" + (compressedOutput ? ".lz4" : ".dds"), FileMode.Create));
            fpos.Write(ftDDS.ddsHeaderHalf4);

            int atlasTexSize = resolution;
            if (currentGroup.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex)
            {
                atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)currentGroup.totalVertexCount));
                atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)ftRenderLightmap.tileSize) * ftRenderLightmap.tileSize;
            }

            var halfs = new ushort[atlasTexSize*atlasTexSize*4];
            for(int f=0; f<atlasTexSize*atlasTexSize*4; f+=4)
            {
                halfs[f+3] = 15360; // 1.0f in halffloat
            }
            var posbytes = new byte[atlasTexSize * atlasTexSize * 8];
            System.Buffer.BlockCopy(halfs, 0, posbytes, 0, posbytes.Length);
            fpos.Write(posbytes);
            fpos.BaseStream.Seek(12, SeekOrigin.Begin);
            fpos.Write(atlasTexSize);
            fpos.Write(atlasTexSize);
            fpos.Close();

            //yield break;
        }
        else if (usesIndirectIntensity)
        {
            cif.fcomp.Seek(0, SeekOrigin.Begin);
            cif.fcomp.Write(true);
        }

        if (rmode == (int)RenderMode.Shadowmask && cif.fcompIndirect.BaseStream.Position == 0)
        {
            lightmapHasColor[LMID] = false;
        }

        if (!doCompose)
        {
            progressStepsDone++;
            yield break;
        }

        progressStepsDone++;
        string progressText2 = "Compositing lighting for " + lmname + "...";
        if (!deferredMode) ProgressBarShow(progressText2 , (progressStepsDone / (float)progressSteps), true);
        if (userCanceled)
        {
            cif.fcomp.Close();
            if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
            if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
            if (cif.fcompDir != null) cif.fcompDir.Close();
            if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
            if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
            if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
            if (cif.fcompSH != null) cif.fcompSH.Close();
            yield break;
        }
        yield return null;

        // Compose
        cif.fcomp.Close();
        if (cif.fcompIndirect != null) cif.fcompIndirect.Close();
        if (cif.fcompDirIndirect != null) cif.fcompDirIndirect.Close();
        if (cif.fcompDir != null) cif.fcompDir.Close();
        if (cif.fcompRNM0 != null) cif.fcompRNM0.Close();
        if (cif.fcompRNM1 != null) cif.fcompRNM1.Close();
        if (cif.fcompRNM2 != null) cif.fcompRNM2.Close();
        if (cif.fcompSH != null) cif.fcompSH.Close();
        if (!performRendering) yield break;
        DebugLogInfo("Compositing...");

        int errCode2 = 0;
        if (exeMode)
        {
            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;

            bool shouldAddLights = !(bounces == 0 && (shMode || rnmMode));

            if (shouldAddLights)
            {
                if (bounces == 0)
                {
                    startInfo.Arguments       =  "add " + scenePathQuoted + " \"" + lmname + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds")
                    + "\" " + PASS_HALF + " " + 0 + " " + LMID + " comp_" + LMID + ".bin";
                }
                else
                {
                    startInfo.Arguments       =  "addmul " + scenePathQuoted + " \"" + lmname + "\" " + PASS_HALF + " " + 0 + " " + LMID + " comp_" + LMID + ".bin";;
                }

                deferredFileSrc.Add("");//scenePath + "/comp_" + LMID + ".bin");
                deferredFileDest.Add("");//scenePath + "/comp.bin");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText2);
            }

            if (dominantDirMode)// && rmode == (int)RenderMode.FullLighting)
            {
                progressText2 = "Compositing direction for " + lmname + "...";
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;

                startInfo.Arguments       =  "diradd " + scenePathQuoted + " \"" + lmname + (bounces > 0 ? "_lights_Dir" : "_final_Dir") + (compressedOutput ? ".lz4" : ".dds")
                + "\" " + PASS_DIRECTION + " " + 0 + " " + LMID + " dircomp_" + LMID + ".bin";

                if (deferredMode)
                {
                    deferredFileSrc.Add("");//scenePath + "/dircomp_" + LMID + ".bin");
                    deferredFileDest.Add("");//scenePath + "/dircomp.bin");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText2);
                }
                else
                {
                    Debug.LogError("Not supported");
                }
            }
        }

        if (errCode2 != 0)
        {
            DebugLogError("ftrace error: "+ftErrorCodes.TranslateFtrace(errCode2, rtxMode));
            userCanceled = true;
            yield break;
        }
    }

    bool RenderLMAO(int LMID, string lmname)
    {
        string progressText = "Rendering AO for " + lmname + "...";
        if (!deferredMode) ProgressBarShow(progressText, (progressStepsDone / (float)progressSteps), true);

        var rmode = currentGroup.renderMode == BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)currentGroup.renderMode;

        int passes = rmode == (int)RenderMode.AmbientOcclusionOnly ? PASS_HALF : PASS_MASK;

        // There is no realistic weight for AO to mix with other light directions
        var dirMode = currentGroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)currentGroup.renderDirMode;
        var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection;
        if (dominantDirMode && rmode == (int)RenderMode.AmbientOcclusionOnly) passes |= PASS_DIRECTION;

        var fao = new BinaryWriter(File.Open(scenePath + "/ao.bin", FileMode.Create));
        if (clientMode) ftClient.serverFileList.Add("ao.bin");
        fao.Write(SampleCount(hackAOSamples));
        fao.Write(hackAORadius);
        fao.Write(rmode == (int)RenderMode.AmbientOcclusionOnly ? hackAOIntensity : 1.0f);
        fao.Close();

        System.Diagnostics.ProcessStartInfo startInfo;
        //System.Diagnostics.Process exeProcess;

        int errCode = 0;
        if (exeMode)
        {
            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;
            string renderMode;
            if (dominantDirMode && rmode == (int)RenderMode.AmbientOcclusionOnly)
            {
                renderMode = "aodir";
            }
            else
            {
                renderMode = "ao";//currentGroup.aoIsThickness ? "thickness" : "ao";
            }

            if (rmode ==  (int)RenderMode.AmbientOcclusionOnly)
            {
                startInfo.Arguments       =  renderMode + " " + scenePathQuoted + " \"" + lmname + "_final" +  "\" " + passes + " " + dilate + " " + LMID;
            }
            else
            {
                startInfo.Arguments       =  renderMode + " " + scenePathQuoted + " \"" + lmname + "_ao" +  "\" " + passes + " " + dilate + " " + LMID;
            }

            deferredFileSrc.Add("");
            deferredFileDest.Add("");
            deferredCommands.Add(startInfo);
            deferredCommandDesc.Add(progressText);
        }

        if (errCode != 0)
        {
            DebugLogError("ftrace error: "+ftErrorCodes.TranslateFtrace(errCode, rtxMode));
            userCanceled = true;
            return false;
        }
        return true;
    }

    void RenderLMSSS(BakeryLightmapGroup lmgroup, bool lastPass, bool firstPass)
    {
        int LMID = lmgroup.id;

        //var rmode = lmgroup.renderMode == BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)lmgroup.renderMode;

        var dirMode = lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroup.renderDirMode;
        var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection && lightmapHasDir[lmgroup.id];
        var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM && lightmapHasRNM[LMID];
        var shMode = (dirMode == (int)ftRenderLightmap.RenderDirMode.SH || dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH) && lightmapHasRNM[LMID];

        int passes = PASS_HALF;
        //if (dominantDirMode && lastPass) passes |= PASS_DIRECTION;
        if (rnmMode && lastPass) passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2;
        if (shMode && lastPass) passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2 | PASS_RNM3;

        var remode = "sss";
        if (dominantDirMode)
        {
            //rmode = "sss";
            Debug.LogError("SSS does not output its own direction, thus unlit SSS-only parts can look too bright (Group: " + lmgroup.name + ")");
        }
        else if (rnmMode)
        {
            //remode = "sssrnm";
            Debug.LogError("SSS is not currently supported in RNM mode (Group: " + lmgroup.name + ")");
        }
        else if (shMode && lastPass)
        {
            remode = "ssssh";
        }

        var fname = "sss" + LMID + "_"+(lastPass?1:0)+".bin";
        var fsss = new BinaryWriter(File.Open(scenePath + "/" + fname, FileMode.Create));
        if (clientMode) ftClient.serverFileList.Add(fname);

        var rmode = (int)lmgroup.renderMode == (int)BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)lmgroup.renderMode;
        bool indirectRMode = rmode == (int)RenderMode.Indirect || rmode == (int)RenderMode.Shadowmask;

        if (bounces == 0 && shMode && indirectRMode) Debug.LogError("SSS won't work in Shadowmask mode with SH directional mode and 0 bounces (Group: " + lmgroup.name + ")");

        var inputTex = lmgroup.name + (lastPass ? "_final" : "_diffuse") + "_HDR" + (compressedOutput ? ".lz4" : ".dds");

        fsss.Write(SampleCount(lmgroup.sssSamples));
        fsss.Write(lmgroup.sssDensity);
        fsss.Write(Mathf.Pow(lmgroup.sssColor.r,2.2f) * lmgroup.sssScale);
        fsss.Write(Mathf.Pow(lmgroup.sssColor.g,2.2f) * lmgroup.sssScale);
        fsss.Write(Mathf.Pow(lmgroup.sssColor.b,2.2f) * lmgroup.sssScale);
        if (lastPass)
        {
            fsss.Write(indirectRMode ? 0 : 1); // only add SSS to GI in full lighting
        }
        else
        {
            fsss.Write(1); // always add SSS to _diffuse direct lighting
        }
        fsss.Write(inputTex);
        fsss.Close();

        var startInfo = new System.Diagnostics.ProcessStartInfo();
        startInfo.CreateNoWindow  = false;
        startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
        startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
        startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
        startInfo.CreateNoWindow = true;
        startInfo.Arguments       =  remode + " " + scenePathQuoted + " \"" + lmgroup.name + (lastPass ? ((shMode || indirectRMode) ? "_SSS" : "_final") : "_diffuse")
        + "\"" + " " + passes + " " + 16 + " " + lmgroup.id
        + " " + fname
        + " \"" + inputTex + "\""; // full lighting passed as direct

        deferredFileSrc.Add("");//scenePath + "/sss" + LMID + ".bin");
        deferredFileDest.Add("");//scenePath + "/sss.bin");
        deferredCommands.Add(startInfo);
        deferredCommandDesc.Add("Computing subsurface scattering for " + lmgroup.name + "...");

        if (firstPass && bounces > 0)
        {
            deferredFileSrc.Add(scenePath + "/" + lmgroup.name + "_diffuse_HDR" + (compressedOutput ? ".lz4" : ".dds"));
            deferredFileDest.Add(scenePath + "/" + lmgroup.name + "_diffuse0_HDR" + (compressedOutput ? ".lz4" : ".dds"));
            deferredCommands.Add(null);
            deferredCommandDesc.Add("Computing subsurface scattering for " + lmgroup.name + " (2) ...");
        }
    }

    bool RenderLMGI(int LMID, string lmname, int i, bool needsGIPass, bool lastPass)
    {
        string progressText = "Rendering GI bounce " + i + " for " + lmname + "...";
        if (!deferredMode) ProgressBarShow(progressText, (progressStepsDone / (float)progressSteps), true);

        var dirMode = currentGroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)currentGroup.renderDirMode;
        var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection && lightmapHasDir[LMID];
        var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM && lightmapHasRNM[LMID];
        var shMode = (dirMode == (int)ftRenderLightmap.RenderDirMode.SH || dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH) && lightmapHasRNM[LMID];
        var shModeProbe = dirMode == (int)BakeryLightmapGroup.RenderDirMode.ProbeSH && lightmapHasRNM[LMID];
        if (shModeProbe) shMode = true;

        // Needs both HALF and SECONDARY_HALF because of multiple lightmaps reading each other's lighting
        int passes = needsGIPass ? (PASS_HALF|PASS_SECONDARY_HALF) : PASS_HALF;

        if (dominantDirMode && lastPass) passes |= PASS_DIRECTION;
        if (rnmMode && lastPass) passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2;
        if (shMode && lastPass) passes |= PASS_RNM0 | PASS_RNM1 | PASS_RNM2 | PASS_RNM3;

        System.Diagnostics.ProcessStartInfo startInfo;
        //System.Diagnostics.Process exeProcess;

        int errCode = 0;
        if (exeMode)
        {
            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;
            string rmode = "texgi";
            if (dominantDirMode && lastPass)
            {
                rmode = "texgidir";
            }
            else if (rnmMode && lastPass)
            {
                rmode = "texgirnm";
            }
            else if (shMode && lastPass)
            {
                rmode = shModeProbe ? "texgiprobesh" : "texgish";
            }
            startInfo.Arguments       =  rmode + " " + scenePathQuoted + " \"" + lmname + (i==bounces-1 ? "_final" : "_diffuse") +  "\" " + passes + " " + dilate + " " + LMID;
            startInfo.Arguments += " \"gi_" + lmname + i + ".bin\"";
            if (i == bounces-1)
            {
                // add direct lighting on top of GI
                startInfo.Arguments += " \"" + lmname + "_lights_HDR" + (compressedOutput ? ".lz4" : ".dds") + "\""; // direct lighting
            }
            else
            {
                // add direct*albedo+emissive on top of GI
                startInfo.Arguments += " \"" + lmname + "_diffuse0_HDR" + (compressedOutput ? ".lz4" : ".dds") + "\""; // direct lighting
            }

            /*if (giLodModeEnabled)
            {
                startInfo.Arguments += " vbTraceTex" + LMID + ".bin";
            }
            else
            {*/
                startInfo.Arguments += " vbTraceTex.bin";
            //}

            deferredFileSrc.Add("");//scenePath + "/gi_" + lmname + i + ".bin");
            deferredFileDest.Add("");//scenePath + "/gi.bin");
            deferredCommands.Add(startInfo);
            deferredCommandDesc.Add(progressText);
        }

        if (errCode != 0)
        {
            DebugLogError("ftrace error: "+ftErrorCodes.TranslateFtrace(errCode, rtxMode));
            userCanceled = true;
            return false;
        }
        return true;
    }

    void UpdateMaskArray(int LMID, string lname, string lmname, Light ulht, BakeryPointLight lht, bool denoise)
    {
        int maskChannel = -1;
        if (ulht != null)
        {
#if UNITY_2017_3_OR_NEWER
            maskChannel = ulht.bakingOutput.occlusionMaskChannel;
#else
            var so = new SerializedObject(ulht);
            maskChannel = so.FindProperty("m_BakingOutput").FindPropertyRelative("occlusionMaskChannel").intValue;
#endif
        }
        else if (lht != null)
        {
            maskChannel = lht.maskChannel;
        }

        if (maskChannel >=0 && maskChannel <= 3)
        {
            var maskArray = lightmapMasks[LMID];
            var maskArrayLMNames = lightmapMaskLMNames[LMID];
            var maskArrayLights = lightmapMaskLights[LMID];
            var maskArrayDenoise = lightmapMaskDenoise[LMID];
            while(maskArray.Count < maskChannel + 1)
            {
                maskArray.Add(new List<string>());
                maskArrayLMNames.Add(new List<string>());
                maskArrayLights.Add(new List<Light>());
                maskArrayDenoise.Add(new List<bool>());
            }
            maskArray[maskChannel].Add(lname + "_Mask" + (compressedOutput ? ".lz4" : ".dds"));
            maskArrayLMNames[maskChannel].Add(lmname);
            maskArrayLights[maskChannel].Add(ulht);
            maskArrayDenoise[maskChannel].Add(denoise);
            lightmapHasMask[LMID]++;// = true;
        }
    }

    bool SetupLightShadowmask(Light light, int channel)
    {
        bool success = true;
        if (channel > 3)
        {
            success = false;
            DebugLogWarning("Light " + light.name + " can't generate shadow mask (out of channels).");
            overlappingLights.Add(light.gameObject);
        }

        int occlusionMaskChannel = channel > 3 ? -1 : channel;

#if UNITY_2017_3_OR_NEWER
        var output = new LightBakingOutput();
        output.isBaked = true;
        output.lightmapBakeType = LightmapBakeType.Mixed;
        output.mixedLightingMode = userRenderMode == RenderMode.Shadowmask ? MixedLightingMode.Shadowmask : MixedLightingMode.Subtractive;
        output.occlusionMaskChannel = occlusionMaskChannel;
        output.probeOcclusionLightIndex  = light.bakingOutput.probeOcclusionLightIndex;
        light.bakingOutput = output;
#else
        light.alreadyLightmapped = true;
        light.lightmapBakeType = LightmapBakeType.Mixed;
        var so = new SerializedObject(light);
        var sp = so.FindProperty("m_BakingOutput");
        sp.FindPropertyRelative("occlusionMaskChannel").intValue = occlusionMaskChannel;
        //sp.FindPropertyRelative("probeOcclusionLightIndex").intValue = -1;
        sp.FindPropertyRelative("lightmappingMask").intValue = -1;
        so.ApplyModifiedProperties();

        if (!maskedLights.Contains(light)) maskedLights.Add(light);

#endif

        var st = storages[light.gameObject.scene];
        if (!st.bakedLights.Contains(light))
        {
            st.bakedLights.Add(light);
            st.bakedLightChannels.Add(occlusionMaskChannel);
        }

        return success;
    }

    void PrepareAssetImporting()
    {
        var outputPathCompat = outputPathFull.Replace("\\", "/");

        // Prepare asset importing: set AssetPostprocessor settings
        ftTextureProcessor.texSettings = new Dictionary<string, Vector2>();
        foreach(var lmgroup in groupListGIContributingPlain)
        {
            if (lmgroup.vertexBake) continue;
            var nm = lmgroup.name;

            int colorSize = lmgroup.resolution / (1 << (int)((1.0f - ftBuildGraphics.mainLightmapScale) * 6));
            int maskSize = lmgroup.resolution / (1 << (int)((1.0f - ftBuildGraphics.maskLightmapScale) * 6));
            int dirSize = lmgroup.resolution / (1 << (int)((1.0f - ftBuildGraphics.dirLightmapScale) * 6));

            var dirMode = lmgroup.renderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroup.renderDirMode;
            var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection && lightmapHasDir[lmgroup.id];
            var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM && lightmapHasRNM[lmgroup.id];
            var shMode = (dirMode == (int)ftRenderLightmap.RenderDirMode.SH || dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH) && lightmapHasRNM[lmgroup.id];
            var shModeProbe = dirMode == (int)BakeryLightmapGroup.RenderDirMode.ProbeSH && lightmapHasRNM[lmgroup.id];
            var shModeMono = dirMode == (int)BakeryLightmapGroup.RenderDirMode.MonoSH;
            if (shModeProbe) shMode = true;

            //if (!bc6h)
            {
                //if (File.Exists(folder + "../Assets/" + nm + "_final.hdr"))
                {
                    //var outfile = "Assets/"+nm+"_final_RGBM.dds";
                    //Texture2D lm = null;
                    var outfile = "Assets/" + outputPathCompat + "/"+nm+"_final.hdr";
                    if (rnmMode) outfile = "Assets/" + outputPathCompat + "/"+nm+"_RNM0.hdr";
                    var desiredTextureType = encodeMode == 0 ? ftTextureProcessor.TEX_LM : ftTextureProcessor.TEX_LMDEFAULT;
                    if (lightmapHasColor[lmgroup.id])// && File.Exists(outfile))
                    {
                        ftTextureProcessor.texSettings[outfile] = new Vector2(colorSize, desiredTextureType);
                    }

                    //Texture2D mask = null;
                    //if (userRenderMode == RenderMode.Shadowmask && lightmapMasks[lmgroup.id].Count > 0)
                    if (lightmapHasMask[lmgroup.id] > 0)
                    {
                        outfile = "Assets/" + outputPathCompat + "/"+nm+"_mask" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                        desiredTextureType = lightmapHasMask[lmgroup.id] >= 4 ? ftTextureProcessor.TEX_MASK : ftTextureProcessor.TEX_MASK_NO_ALPHA;
                        ftTextureProcessor.texSettings[outfile] = new Vector2(maskSize, desiredTextureType);
                    }

                    //Texture2D dirLightmap = null;
                    if (dominantDirMode)
                    {
                        outfile = "Assets/" + outputPathCompat + "/"+nm+"_dir" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                        desiredTextureType = ftTextureProcessor.TEX_DIR;// TextureImporterType.Default;
                        ftTextureProcessor.texSettings[outfile] = new Vector2(dirSize, desiredTextureType);
                    }

                    //Texture2D rnmLightmap0 = null;
                    //Texture2D rnmLightmap1 = null;
                    //Texture2D rnmLightmap2 = null;
                    if (rnmMode)
                    {
                        desiredTextureType = encodeMode == 0 ? ftTextureProcessor.TEX_LM : ftTextureProcessor.TEX_LMDEFAULT;
                        //TextureImporterType.Lightmap : TextureImporterType.Default;
                        for(int c=0; c<3; c++)
                        {
                            outfile = "Assets/" + outputPathCompat + "/"+nm+"_RNM" + c + ".hdr";
                            ftTextureProcessor.texSettings[outfile] = new Vector2(dirSize, desiredTextureType);
                        }
                    }

                    if (shMode)
                    {
                        outfile = "Assets/" + outputPathCompat + "/"+nm+"_L0.hdr";
                        desiredTextureType = encodeMode == 0 ? ftTextureProcessor.TEX_LM : ftTextureProcessor.TEX_LMDEFAULT;
                        ftTextureProcessor.texSettings[outfile] = new Vector2(colorSize, desiredTextureType);

                        desiredTextureType = ftTextureProcessor.TEX_DIR;// TextureImporterType.Default;
                        if (shModeMono)
                        {
                            desiredTextureType = ftTextureProcessor.TEX_DIR_NO_ALPHA;
                            outfile = "Assets/" + outputPathCompat + "/"+nm+"_L1" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                            ftTextureProcessor.texSettings[outfile] = new Vector2(dirSize, desiredTextureType);
                        }
                        else
                        {
                            for(int c=0; c<3; c++)
                            {
                                string comp;
                                if (c==0)
                                {
                                    comp = "x";
                                }
                                else if (c==1)
                                {
                                    comp = "y";
                                }
                                else
                                {
                                    comp = "z";
                                }
                                outfile = "Assets/" + outputPathCompat + "/"+nm+"_L1" + comp + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                                ftTextureProcessor.texSettings[outfile] = new Vector2(dirSize, desiredTextureType);
                            }
                        }
                    }
                }
            }
        }

#if UNITY_2021_2_OR_NEWER
        // For parallel import
        if (UnityEditor.EditorSettings.refreshImportMode == AssetDatabase.RefreshImportMode.OutOfProcessPerQueue)
        {
            gstorage.texSettingsKey = new List<string>();
            gstorage.texSettingsVal = new List<Vector2>();
            foreach(var pair in ftTextureProcessor.texSettings)
            {
                gstorage.texSettingsKey.Add(pair.Key);
                gstorage.texSettingsVal.Add(pair.Value);
            }
        }
#endif
    }

    IEnumerator RenderLMAddBuckets(int LMID, string lmname, int resolution, bool vertexBake, int lmgroupRenderDirMode, int lmgroupRenderMode)
    {
        var dirMode = lmgroupRenderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroupRenderDirMode;
        var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection;
        var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM && lightmapHasRNM[LMID];
        var shMode = (dirMode == (int)ftRenderLightmap.RenderDirMode.SH || dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH) && lightmapHasRNM[LMID];
        var shModeProbe = dirMode == (int)BakeryLightmapGroup.RenderDirMode.ProbeSH && lightmapHasRNM[LMID];
        if (shModeProbe) shMode = true;
        var shadowmask = (userRenderMode == RenderMode.Shadowmask);

        if (rnmMode)
        {
            for(int c=0; c<3; c++)
            {
                var startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
        #if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
        #endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;
                startInfo.Arguments       =  "postadd " + scenePathQuoted + " \"" + lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds")
                + "\"" + " " + PASS_HALF + " " + 0 + " " + LMID + " comp_addbuckets" + c + "_" + LMID + ".bin";

                deferredFileSrc.Add("");
                deferredFileDest.Add("");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add("Compositing lightmaps for " + lmname + "...");

                var fcomp = new BinaryWriter(File.Open(scenePath + "/comp_addbuckets" + c + "_" + LMID + ".bin", FileMode.Create));
                if (clientMode) ftClient.serverFileList.Add("comp_addbuckets" + c + "_" + LMID + ".bin");
                fcomp.Write(lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds"));
                fcomp.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
                foreach(var lmgroup in groupListPlain)
                {
                    if (lmgroup.parentName != lmname) continue;
                    fcomp.Write(lmgroup.name + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds"));
                    fcomp.Write("uvnormal_" + lmgroup.name + (compressedGBuffer ? ".lz4" : ".dds"));
                }
                fcomp.Close();
            }
        }
        else if (shMode)
        {
            var startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
    #if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
    #endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       =  "postadd " + scenePathQuoted + " \"" + lmname + "_final_L0" + (compressedOutput ? ".lz4" : ".dds")
            + "\"" + " " + PASS_HALF + " " + 0 + " " + LMID + " comp_addbucketsL0_" + LMID + ".bin";

            deferredFileSrc.Add("");
            deferredFileDest.Add("");
            deferredCommands.Add(startInfo);
            deferredCommandDesc.Add("Compositing lightmaps for " + lmname + "...");

            var fcomp = new BinaryWriter(File.Open(scenePath + "/comp_addbucketsL0_" + LMID + ".bin", FileMode.Create));
            if (clientMode) ftClient.serverFileList.Add("comp_addbucketsL0_" + LMID + ".bin");
            fcomp.Write(lmname + "_final_L0" + (compressedOutput ? ".lz4" : ".dds"));
            fcomp.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
            foreach(var lmgroup in groupListPlain)
            {
                if (lmgroup.parentName != lmname) continue;
                fcomp.Write(lmgroup.name + "_final_L0" + (compressedOutput ? ".lz4" : ".dds"));
                fcomp.Write("uvnormal_" + lmgroup.name + (compressedGBuffer ? ".lz4" : ".dds"));
            }
            fcomp.Close();

            for(int c=0; c<3; c++)
            {
                string cname;
                switch(c)
                {
                    case 0:
                        cname = "L1x";
                        break;
                    case 1:
                        cname = "L1y";
                        break;
                    default:
                        cname = "L1z";
                        break;
                }

                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
    #if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
    #endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;
                startInfo.Arguments       =  "postdiradd " + scenePathQuoted + " \"" + lmname + "_final_" + cname + (compressedOutput ? ".lz4" : ".dds")
                + "\"" + " " + PASS_DIRECTION + " " + 0 + " " + LMID + " dircomp_addbuckets" + c + "_" + LMID + ".bin";

                deferredFileSrc.Add("");
                deferredFileDest.Add("");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add("Compositing directions for " + lmname + "...");

                fcomp = new BinaryWriter(File.Open(scenePath + "/dircomp_addbuckets" + c + "_" + LMID + ".bin", FileMode.Create));
                if (clientMode) ftClient.serverFileList.Add("dircomp_addbuckets" + c + "_" + LMID + ".bin");
                fcomp.Write(lmname + "_final_" + cname + (compressedOutput ? ".lz4" : ".dds"));
                fcomp.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
                foreach(var lmgroup in groupListPlain)
                {
                    if (lmgroup.parentName != lmname) continue;
                    fcomp.Write(lmgroup.name + "_final_" +  cname + (compressedOutput ? ".lz4" : ".dds"));
                    fcomp.Write("uvnormal_" + lmgroup.name + (compressedGBuffer ? ".lz4" : ".dds"));
                }
                fcomp.Close();
            }
        }
        else
        {
            var startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
    #if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
    #endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       =  "postadd " + scenePathQuoted + " \"" + lmname + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds")
            + "\"" + " " + PASS_HALF + " " + 0 + " " + LMID + " comp_addbuckets" + LMID + ".bin";

            deferredFileSrc.Add("");
            deferredFileDest.Add("");
            deferredCommands.Add(startInfo);
            deferredCommandDesc.Add("Compositing lightmaps for " + lmname + "...");

            var fcomp = new BinaryWriter(File.Open(scenePath + "/comp_addbuckets" + LMID + ".bin", FileMode.Create));
            if (clientMode) ftClient.serverFileList.Add("comp_addbuckets" + LMID + ".bin");
            fcomp.Write(lmname + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds"));
            fcomp.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
            foreach(var lmgroup in groupListPlain)
            {
                //Debug.LogError("Cur: "+lmname+", "+LMID+", this parent: " + lmgroup.name+", "+lmgroup.parentID);
                //if (lmgroup.parentID != LMID) continue;
                if (lmgroup.parentName != lmname) continue;
                fcomp.Write(lmgroup.name + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds"));
                fcomp.Write("uvnormal_" + lmgroup.name + (compressedGBuffer ? ".lz4" : ".dds"));
            }
            fcomp.Close();
        }

        if (dominantDirMode)
        {
            var startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       =  "postdiradd " + scenePathQuoted + " \"" + lmname + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds")
            + "\"" + " " + PASS_DIRECTION + " " + 0 + " " + LMID + " dircomp_addbuckets" + LMID + ".bin";

            deferredFileSrc.Add("");
            deferredFileDest.Add("");
            deferredCommands.Add(startInfo);
            deferredCommandDesc.Add("Compositing directions for " + lmname + "...");

            var fcomp = new BinaryWriter(File.Open(scenePath + "/dircomp_addbuckets" + LMID + ".bin", FileMode.Create));
            if (clientMode) ftClient.serverFileList.Add("dircomp_addbuckets" + LMID + ".bin");
            fcomp.Write(lmname + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds"));
            fcomp.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
            foreach(var lmgroup in groupListPlain)
            {
                if (lmgroup.parentName != lmname) continue;
                fcomp.Write(lmgroup.name + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds"));
                fcomp.Write("uvnormal_" + lmgroup.name + (compressedGBuffer ? ".lz4" : ".dds"));
            }
            fcomp.Close();
        }

        if (shadowmask)
        {
            var maskNames = lightmapMasks[LMID];
            var maskLights = lightmapMaskLights[LMID];
            if (maskNames != null)
            {
                for(int c=0; c<maskNames.Count; c++)
                {
                    var maskNamesOnChannel = maskNames[c];
                    var maskLightsOnChannel = maskLights[c];

                    for(int i=0; i<maskNamesOnChannel.Count; i++)
                    {
                        var uid = LMID + "_" + c + "_" + i;

                        var startInfo = new System.Diagnostics.ProcessStartInfo();
                        startInfo.CreateNoWindow  = false;
                        startInfo.UseShellExecute = false;
            #if !LAUNCH_VIA_DLL
                        startInfo.WorkingDirectory = dllPath + "/Bakery";
            #endif
                        startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                        startInfo.CreateNoWindow = true;
                        startInfo.Arguments       =  "postmaskadd " + scenePathQuoted + " \"" + maskNamesOnChannel[i]
                        + "\"" + " " + PASS_MASK + " " + 0 + " " + LMID + " maskcomp_addbuckets" + uid + ".bin";

                        deferredFileSrc.Add("");
                        deferredFileDest.Add("");
                        deferredCommands.Add(startInfo);
                        deferredCommandDesc.Add("Compositing masks for " + lmname + "...");

                        var fcomp = new BinaryWriter(File.Open(scenePath + "/maskcomp_addbuckets" + uid + ".bin", FileMode.Create));
                        if (clientMode) ftClient.serverFileList.Add("maskcomp_addbuckets" + uid + ".bin");
                        fcomp.Write(maskNamesOnChannel[i]);
                        fcomp.Write("uvnormal_" + lmname + (compressedGBuffer ? ".lz4" : ".dds"));
                        foreach(var lmgroup2 in groupListPlain)
                        {
                            if (lmgroup2.parentName != lmname) continue;

                            var maskNames2 = lightmapMasks[lmgroup2.id];
                            var maskLMNames2 = lightmapMaskLMNames[lmgroup2.id];
                            var maskLights2 = lightmapMaskLights[lmgroup2.id];
                            int channels2 = maskNames2.Count;
                            if (channels2 <= c) continue;

                            var names2 = maskNames2[c];
                            var lmnames2 = maskLMNames2[c];
                            var lights2 = maskLights2[c];
                            for(int k=0; k<names2.Count; k++)
                            {
                                if (lights2[k] != maskLightsOnChannel[i]) continue;
                                fcomp.Write(names2[k]);
                                fcomp.Write("uvnormal_" + lmnames2[k] + (compressedGBuffer ? ".lz4" : ".dds"));
                            }
                        }
                        fcomp.Close();
                    }
                }
            }
        }

        yield break;
    }

    static int GetDenoiseStartTileSize(int resolution)
    {
        return System.Math.Min(resolution, 2048); // workaround for the new NV driver bug
    }

    string GetDenoiseMode()
    {
        string denoiseMod;
        switch(denoiserType)
        {
            case ftGlobalStorage.DenoiserType.OpenImageDenoise:
                denoiseMod = "OIDN";
                break;
            case ftGlobalStorage.DenoiserType.Optix5:
                denoiseMod = "Legacy";
                break;
            case ftGlobalStorage.DenoiserType.Optix7:
                denoiseMod = "72";
                break;
            default:
                denoiseMod = "";
                break;
        }
        return denoiseMod;
    }

    IEnumerator RenderLMCombineMasks(int LMID, string lmname, int resolution, bool vertexBake, int lmgroupRenderMode, BakeryLightmapGroupPlain lmgroup)
    {
        System.Diagnostics.ProcessStartInfo startInfo;
        string progressText;

        //var rmode = lmgroupRenderMode == (int)BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)lmgroupRenderMode;
        var denoiseMod = GetDenoiseMode();

        // Combine shadow masks
        if (userRenderMode == RenderMode.Shadowmask)
        {
            var maskNames = lightmapMasks[LMID];
            var maskLights = lightmapMaskLights[LMID];
            var maskDenoise = lightmapMaskDenoise[LMID];

            bool process = true;
            if (ftBuildGraphics.postPacking)
            {
                if (lmgroup.parentName != null && lmgroup.parentName.Length > 0 && lmgroup.parentName != "|")
                {
                    process = false;
                }
                /*else if (lmgroup.parentName == "|")
                {
                    foreach(var lmgroup2 in groupListPlain)
                    {
                        if (lmgroup2.parentName == lmgroup.name)
                        {
                            var maskNames2 = lightmapMasks[lmgroup2.id];
                            var maskLights2 = lightmapMaskLights[lmgroup2.id];
                            var maskDenoise2 = lightmapMaskDenoise[lmgroup2.id];
                            int channels2 = maskNames2.Count;
                            for(int j=0; j<channels2; j++)
                            {
                                var names2 = maskNames2[j];
                                var lights2 = maskLights2[j];
                                var denoise2 = maskDenoise2[j];
                                for(int k=0; k<names2.Count; k++)
                                {
                                    maskNames[j].Add(names2[k]);
                                    maskLights[j].Add(lights2[k]);
                                    maskDenoise[j].Add(denoise2[k]);
                                }
                            }
                        }
                    }
                }*/
            }

            if (maskNames.Count > 0 && process)
            {
                var fcomp = new BinaryWriter(File.Open(scenePath + ("/masks_" + LMID + ".bin"), FileMode.Create));
                if (clientMode) ftClient.serverFileList.Add("masks_" + LMID + ".bin");
                fcomp.Write(maskNames[0].Count);
                fcomp.Write(maskNames.Count > 1 ? maskNames[1].Count : 0);
                fcomp.Write(maskNames.Count > 2 ? maskNames[2].Count : 0);
                fcomp.Write(maskNames.Count > 3 ? maskNames[3].Count : 0);
                for(int channel=0; channel<maskNames.Count; channel++)
                {
                    for(int i=0; i<maskNames[channel].Count; i++)
                    {
                        fcomp.Write(maskNames[channel][i]);
                        if (vertexBake) continue;
                        if (!maskDenoise[channel][i]) continue;
                        if (maskLights[channel][i] == null) continue;

                        progressText = "Denoising light " + maskLights[channel][i].name + " for shadowmask " + lmname + "...";
                        if (userCanceled) yield break;
                        yield return null;

                        startInfo = new System.Diagnostics.ProcessStartInfo();
                        startInfo.CreateNoWindow  = false;
                        startInfo.UseShellExecute = false;
                        startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
                        startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/denoiser"+denoiseMod+".exe";
                        startInfo.CreateNoWindow = true;
                        startInfo.Arguments       = "m \"" + scenePath +  "/" + maskNames[channel][i] + "\" \"" + scenePath +  "/" + maskNames[channel][i] + "\"";
                        string firstArgs = startInfo.Arguments;
                        startInfo.Arguments += " " + GetDenoiseStartTileSize(resolution) + " 0";

                        if (deferredMode)
                        {
                            deferredFileSrc.Add("");
                            deferredFileDest.Add("");
                            deferredCommands.Add(startInfo);
                            deferredCommandDesc.Add(progressText);
                            List<string> list;
                            deferredCommandsFallback[deferredCommands.Count - 1] = list = new List<string>();

                            int denoiseRes = GetDenoiseStartTileSize(resolution);
                            while(denoiseRes > 64)
                            {
                                denoiseRes /= 2;
                                list.Add(firstArgs + " " + denoiseRes + " 0");
                            }
                        }
                        else
                        {
                            // unsupported
                        }
                    }
                }
                fcomp.Close();

                progressText = "Creating shadow masks for " + lmname + "...";
                if (!deferredMode) ProgressBarShow(progressText, (progressStepsDone / (float)progressSteps), true);
                if (userCanceled) yield break;
                yield return null;

                var outPath = Application.dataPath + "/" + outputPathFull + "/" + lmname + "_mask" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                if (File.Exists(outPath)) ValidateFileAttribs(outPath);

                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
                startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
                startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/combineMasks.exe";
                startInfo.CreateNoWindow = true;
                if (vertexBake)
                {
                    startInfo.Arguments       = "\"" + scenePath + "/" + lmname + "_mask.lz4\" ";
                }
                else
                {
                    startInfo.Arguments       = "\"" + outPath + "\" ";
                }
                                                                /*maskNames[0] + " ";
                if (maskNames.Count > 1) startInfo.Arguments += maskNames[1] + " ";
                if (maskNames.Count > 2) startInfo.Arguments += maskNames[2] + " ";
                if (maskNames.Count > 3) startInfo.Arguments += maskNames[3] + " ";*/
                startInfo.Arguments +=
                "\"" + scenePath + ("/masks_" + LMID + ".bin") + "\" " +
                "\"" + scenePath + "/\"";

                //for(int i=0; i<maskLights.Count; i++) SetupLightShadowmask(maskLights[i], i);

                if (deferredMode)
                {
                    deferredFileSrc.Add("");
                    deferredFileDest.Add("");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText);
                    if (clientMode && !vertexBake) ftClient.serverGetFileList.Add(lmname + "_mask" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga"));
                }
                else
                {
                    Debug.LogError("Doesn't work in non-deferred mode");
                }
            }
        }
    }

    IEnumerator RenderLMFinalize(int LMID, string lmname, int resolution, bool vertexBake, int lmgroupRenderDirMode, int lmgroupRenderMode, BakeryLightmapGroupPlain lmgroup)
    {
        System.Diagnostics.ProcessStartInfo startInfo;
        //System.Diagnostics.Process exeProcess;
        string progressText;

        var dirMode = lmgroupRenderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroupRenderDirMode;
        var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection;
        var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM && lightmapHasRNM[LMID];
        var shMode = (dirMode == (int)ftRenderLightmap.RenderDirMode.SH || dirMode == (int)ftRenderLightmap.RenderDirMode.MonoSH) && lightmapHasRNM[LMID];
        var shModeProbe = dirMode == (int)BakeryLightmapGroup.RenderDirMode.ProbeSH && lightmapHasRNM[LMID];
        if (shModeProbe) shMode = true;

        var rmode = lmgroupRenderMode == (int)BakeryLightmapGroup.RenderMode.Auto ? (int)userRenderMode : (int)lmgroupRenderMode;

        var denoiseMod = GetDenoiseMode();

        // Denoise directions
        if (dominantDirMode && denoise && !vertexBake && lightmapHasDir[LMID])
        {
            progressText = "Denoising direction for " + lmname + "...";
            //if (userCanceled) yield break;
            //yield return null;

            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
            startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
            startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/denoiser"+denoiseMod+".exe";
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       = (alternativeDenoiseDir?"D":"d") + " \"" + scenePath + "/" + lmname + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + scenePath + "/" + lmname + "_final_Dir"  + (compressedOutput ? ".lz4" : ".dds") + "\"";
            string firstArgs = startInfo.Arguments;
            startInfo.Arguments += " " + GetDenoiseStartTileSize(resolution) + " 0";

            if (deferredMode)
            {
                deferredFileSrc.Add("");
                deferredFileDest.Add("");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText);
                List<string> list;
                deferredCommandsFallback[deferredCommands.Count - 1] = list = new List<string>();

                int denoiseRes = GetDenoiseStartTileSize(resolution);
                while(denoiseRes > 64)
                {
                    denoiseRes /= 2;
                    list.Add(firstArgs + " " + denoiseRes + " 0");
                }
            }
            else
            {
                // unsupported
            }
        }

        if (!lightmapHasColor[LMID]) yield break;

        // Apply AO if needed
        if (hackAOIntensity > 0 && hackAOSamples > 0 && !rnmMode && !shMode && !lmgroup.probes && rmode != (int)RenderMode.AmbientOcclusionOnly)
        {
            progressText = "Applying AO to " + lmname + "...";
            if (userCanceled) yield break;//return false;

            var fcomp = new BinaryWriter(File.Open(scenePath + "/addao_" + LMID + ".bin", FileMode.Create));
            if (clientMode) ftClient.serverFileList.Add("addao_" + LMID + ".bin");
            fcomp.Write(lmname + (shMode ? "_final_L0" : "_final_HDR") + (compressedOutput ? ".lz4" : ".dds"));
            fcomp.Write(lmname + "_ao_Mask" + (compressedOutput ? ".lz4" : ".dds"));
            fcomp.Write(hackAOIntensity);
            fcomp.Close();

            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       =  "addao " + scenePathQuoted + " \"" + lmname + (shMode ? "_final_L0" : "_final_HDR") + (compressedOutput ? ".lz4" : ".dds")
            + "\"" + " " + PASS_HALF + " " + 0 + " " + LMID + " addao_" + LMID + ".bin";

            deferredFileSrc.Add("");//scenePath + "/addao_" + LMID + ".bin");
            deferredFileDest.Add("");//scenePath + "/addao.bin");
            deferredCommands.Add(startInfo);
            deferredCommandDesc.Add(progressText);
        }

        // Denoise
        if (denoise && !vertexBake)
        {
            if (!shMode && !rnmMode)
            {
                progressText = "Denoising " + lmname + "...";
                if (userCanceled) yield break;//return false;
                yield return null;

                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
                startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
                startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/denoiser"+denoiseMod+".exe";
                startInfo.CreateNoWindow = true;
                startInfo.Arguments       = "c \"" + scenePath + "/" + lmname + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + scenePath + "/" + lmname + "_final_HDR"  + (compressedOutput ? ".lz4" : ".dds") + "\"";
                string firstArgs = startInfo.Arguments;
                startInfo.Arguments += " " + GetDenoiseStartTileSize(resolution) + " " + (denoise2x ? 1 : 0);

                if (deferredMode)
                {
                    deferredFileSrc.Add("");
                    deferredFileDest.Add("");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText);
                    List<string> list;
                    deferredCommandsFallback[deferredCommands.Count - 1] = list = new List<string>();

                    int denoiseRes = GetDenoiseStartTileSize(resolution);
                    while(denoiseRes > 64)
                    {
                        denoiseRes /= 2;
                        list.Add(firstArgs + " " + denoiseRes + " " + (denoise2x ? 1 : 0));
                    }
                }
            }
        }
        progressStepsDone++;

        string progressText2;

        if (rnmMode && lightmapHasRNM[LMID])
        {
            for(int c=0; c<3; c++)
            {
                // Compose RNM
                progressText2 = "Composing RNM" + c + " for " + lmname + "...";
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;
                startInfo.Arguments       =  "add " + scenePathQuoted + " \"" + lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds")
                + "\" " + PASS_HALF + " " + 0 + " " + LMID + " rnm" + c +"comp_" + LMID + ".bin";
                if (deferredMode)
                {
                    deferredFileSrc.Add("");//scenePath + "/rnm" + c +"comp_" + LMID + ".bin");
                    deferredFileDest.Add("");//scenePath + "/comp.bin");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText2);
                }
                else
                {
                    Debug.LogError("Not supported");
                }

                if (hackAOIntensity > 0 && hackAOSamples > 0)
                {
                    progressText = "Applying AO to " + lmname + "...";
                    //for(int c=0; c<3; c++)
                    {
                        var fcomp = new BinaryWriter(File.Open(scenePath + "/addao_" + LMID + "_" + c + ".bin", FileMode.Create));
                        if (clientMode) ftClient.serverFileList.Add("addao_" + LMID + "_" + c + ".bin");
                        fcomp.Write(lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds"));
                        fcomp.Write(lmname + "_ao_Mask" + (compressedOutput ? ".lz4" : ".dds"));
                        fcomp.Write(hackAOIntensity);
                        fcomp.Close();

                        startInfo = new System.Diagnostics.ProcessStartInfo();
                        startInfo.CreateNoWindow  = false;
                        startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                        startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                        startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                        startInfo.CreateNoWindow = true;
                        startInfo.Arguments       =  "addao " + scenePathQuoted + " \"" + lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds")
                        + "\"" + " " + PASS_HALF + " " + 0 + " " + LMID + " addao_" + LMID + "_" + c + ".bin";

                        if (deferredMode)
                        {
                            deferredFileSrc.Add("");//scenePath + "/addao_" + LMID + "_" + c + ".bin");
                            deferredFileDest.Add("");//scenePath + "/addao.bin");
                            deferredCommands.Add(startInfo);
                            deferredCommandDesc.Add(progressText);
                        }
                    }
                }

                if (denoise && !vertexBake)
                {
                    progressText = "Denoising RNM" + c + " for " + lmname + "...";
                    if (userCanceled) yield break;
                    yield return null;
                    startInfo = new System.Diagnostics.ProcessStartInfo();
                    startInfo.CreateNoWindow  = false;
                    startInfo.UseShellExecute = false;
                    startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
                    startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/denoiser"+denoiseMod+".exe";
                    startInfo.CreateNoWindow = true;
                    startInfo.Arguments       = "c \"" + scenePath + "/" + lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + scenePath + "/" + lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds") + "\"";
                    string firstArgs = startInfo.Arguments;
                    startInfo.Arguments += " " + GetDenoiseStartTileSize(resolution) + " " + (denoise2x ? 1 : 0);
                    if (deferredMode)
                    {
                        deferredFileSrc.Add("");
                        deferredFileDest.Add("");
                        deferredCommands.Add(startInfo);
                        deferredCommandDesc.Add(progressText);
                        List<string> list;
                        deferredCommandsFallback[deferredCommands.Count - 1] = list = new List<string>();

                        int denoiseRes = GetDenoiseStartTileSize(resolution);
                        while(denoiseRes > 64)
                        {
                            denoiseRes /= 2;
                            list.Add(firstArgs + " " + denoiseRes + " " + (denoise2x ? 1 : 0));
                        }
                    }
                    else
                    {
                        Debug.LogError("Not supported");
                    }
                }
            }
        }

        if (shMode && lightmapHasRNM[LMID])
        {
            // Compose SH
            progressText2 = "Composing SH " + " for " + lmname + "...";
            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       =  "addsh " + scenePathQuoted + " \"" + lmname + "_final_"
            + "\" " + PASS_HALF + " " + 0 + " " + LMID + " shcomp_" + LMID + ".bin";
            if (deferredMode)
            {
                deferredFileSrc.Add("");//scenePath + "/shcomp_" + LMID + ".bin");
                deferredFileDest.Add("");//scenePath + "/shcomp.bin");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText2);
            }
            else
            {
                Debug.LogError("Not supported");
            }

            if (hackAOIntensity > 0 && hackAOSamples > 0 && !lmgroup.probes)
            {
                progressText = "Applying AO to " + lmname + "...";
                var fcomp = new BinaryWriter(File.Open(scenePath + "/addao_" + LMID + ".bin", FileMode.Create));
                if (clientMode) ftClient.serverFileList.Add("addao_" + LMID + ".bin");
                fcomp.Write(lmname + (shMode ? "_final_L0" : "_final_HDR") + (compressedOutput ? ".lz4" : ".dds"));
                fcomp.Write(lmname + "_ao_Mask" + (compressedOutput ? ".lz4" : ".dds"));
                fcomp.Write(hackAOIntensity);
                fcomp.Close();

                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = startInfo.WorkingDirectory + "/" + ftraceExe;
                startInfo.CreateNoWindow = true;
                startInfo.Arguments       =  "addao " + scenePathQuoted + " \"" + lmname + (shMode ? "_final_L0" : "_final_HDR") + (compressedOutput ? ".lz4" : ".dds")
                + "\"" + " " + PASS_HALF + " " + 0 + " " + LMID + " addao_" + LMID + ".bin";

                deferredFileSrc.Add("");//scenePath + "/addao_" + LMID + ".bin");
                deferredFileDest.Add("");//scenePath + "/addao.bin");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText);
            }

            if (denoise && !vertexBake)
            {
                progressText = "Denoising SH for " + lmname + "...";
                if (userCanceled) yield break;
                yield return null;
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
                startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
                startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/denoiser"+denoiseMod+".exe";
                startInfo.CreateNoWindow = true;
                startInfo.Arguments      = "s ";
                startInfo.Arguments      += "\"" + scenePath + "/" + lmname + "_final_L0" + (compressedOutput ? ".lz4" : ".dds") +
                                         "\" \"" + scenePath + "/" + lmname + "_final_L1x" + (compressedOutput ? ".lz4" : ".dds") +
                                         "\" \"" + scenePath + "/" + lmname + "_final_L1y" + (compressedOutput ? ".lz4" : ".dds") +
                                         "\" \"" + scenePath + "/" + lmname + "_final_L1z" + (compressedOutput ? ".lz4" : ".dds") +
                                         "\"";
                string firstArgs = startInfo.Arguments;
                startInfo.Arguments += " " + GetDenoiseStartTileSize(resolution) + " 0";
                deferredFileSrc.Add("");
                deferredFileDest.Add("");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText);
                List<string> list;
                deferredCommandsFallback[deferredCommands.Count - 1] = list = new List<string>();

                int denoiseRes = GetDenoiseStartTileSize(resolution);
                while(denoiseRes > 64)
                {
                    denoiseRes /= 2;
                    list.Add(firstArgs + " " + denoiseRes + " 0");
                }
            }


        }

        // Fix seams
        if (fixSeams && !vertexBake)
        {
            progressText = "Fixing seams " + lmname + "...";
            if (userCanceled) yield break;//return false;
            yield return null;

            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
            startInfo.WorkingDirectory = "Assets/Editor/x64/Bakery";
            startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/seamfixer.exe";
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       = "\"" + scenePath + "\" \"" +
                                               LMID + "\" \"";
            if (shMode)
            {
                startInfo.Arguments += lmname + "_final_L0" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" +
                                       lmname + "_final_L1x" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" +
                                       lmname + "_final_L1y" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" +
                                       lmname + "_final_L1z" + (compressedOutput ? ".lz4" : ".dds") + "\"";
            }
            else if (rnmMode)
            {
                startInfo.Arguments += lmname + "_final_RNM0" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" +
                                       lmname + "_final_RNM1" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" +
                                       lmname + "_final_RNM2" + (compressedOutput ? ".lz4" : ".dds") + "\"";
            }
            else if (dominantDirMode)
            {
                startInfo.Arguments += lmname + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" +
                                       lmname + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds");
            }
            else
            {
                startInfo.Arguments += lmname + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds") + "\"";
            }

            deferredFileSrc.Add("");
            deferredFileDest.Add("");
            deferredCommands.Add(startInfo);
            deferredCommandDesc.Add(progressText);
        }
        progressStepsDone++;
    }

    IEnumerator RenderLMEncode(int LMID, string lmname, int resolution, bool vertexBake, int lmgroupRenderDirMode, int lmgroupRenderMode)
    {
        if (vertexBake) yield break;

        System.Diagnostics.ProcessStartInfo startInfo;

        var dirMode = lmgroupRenderDirMode == (int)BakeryLightmapGroup.RenderDirMode.Auto ? (int)renderDirMode : (int)lmgroupRenderDirMode;
        var dominantDirMode = dirMode == (int)ftRenderLightmap.RenderDirMode.DominantDirection;
        var rnmMode = dirMode == (int)ftRenderLightmap.RenderDirMode.RNM && lightmapHasRNM[LMID];
        var shMode = dirMode == (int)ftRenderLightmap.RenderDirMode.SH && lightmapHasRNM[LMID];
        var shModeProbe = dirMode == (int)BakeryLightmapGroup.RenderDirMode.ProbeSH && lightmapHasRNM[LMID];
        var shModeMono = dirMode == (int)BakeryLightmapGroup.RenderDirMode.MonoSH && lightmapHasRNM[LMID];
        if (shModeProbe || shModeMono) shMode = true;

        var progressText2 = "Encoding " + lmname + "...";
        if (userCanceled) yield break;//return false;
        progressStepsDone++;
        yield return null;

        int maxValue = 1024;
#if UNITY_2019_1_OR_NEWER
        if (GraphicsSettings.renderPipelineAsset != null)
        {
             var srpType = GraphicsSettings.renderPipelineAsset.GetType().ToString();
             if (srpType.Contains("HDRenderPipelineAsset"))
             {
                maxValue = 64000;
             }
        }
#endif

        if (encode)// && !vertexBake)// && File.Exists(scenePath + "/" + lmname + "_final_HDR.dds"))
        {
            if (vertexBake)
            {
                if (deferredMode)
                {
                    deferredFileSrc.Add("");
                    deferredFileDest.Add("");
                    deferredCommands.Add(null);
                    deferredCommandDesc.Add(progressText2);

                    var gr = new BakeryLightmapGroupPlain();
                    gr.id = LMID;
                    gr.name = lmname;
                    deferredCommandsHalf2VB[deferredCommands.Count - 1] = gr;
                }
                else
                {
                    //GenerateVertexBakedMeshes(LMID, lmname);
                }
            }
            else// if (!bc6h)
            {
                if (!shMode && !rnmMode)
                {
                    var outPath = Application.dataPath + "/" + outputPathFull + "/" + lmname + "_final.hdr";
                    if (File.Exists(outPath)) ValidateFileAttribs(outPath);

                    startInfo = new System.Diagnostics.ProcessStartInfo();
                    startInfo.CreateNoWindow  = false;
                    startInfo.UseShellExecute = false;
                    //startInfo.WorkingDirectory = scenePath;
#if !LAUNCH_VIA_DLL
                    startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                    startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/halffloat2hdr.exe";
                    startInfo.CreateNoWindow = true;
                    startInfo.Arguments       = "\"" + scenePath + "/" + lmname + "_final_HDR" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + outPath + "\" " + maxValue;

                    deferredFileSrc.Add("");
                    deferredFileDest.Add("");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText2);
                    if (clientMode) ftClient.serverGetFileList.Add(lmname + "_final.hdr");
                }
            }
        }

        // Encode directions
        if (dominantDirMode && !vertexBake && lightmapHasDir[LMID])
        {
            var outPath = Application.dataPath + "/" + outputPathFull + "/" + lmname + "_dir" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
            if (File.Exists(outPath)) ValidateFileAttribs(outPath);

            progressText2 = "Encoding direction for " + lmname + "...";
            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
            //startInfo.WorkingDirectory = scenePath;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/rgba2tga.exe";
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       = "\"" + scenePath + "/" + lmname + "_final_Dir" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + outPath + "\" " + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? "p" : "");

            if (deferredMode)
            {
                deferredFileSrc.Add("");
                deferredFileDest.Add("");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText2);
                if (clientMode) ftClient.serverGetFileList.Add(lmname + "_dir" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga"));
            }
            else
            {
                Debug.LogError("Not supported");
            }
        }

        if (rnmMode && !vertexBake && lightmapHasRNM[LMID])
        {
            for(int c=0; c<3; c++)
            {
                var outPath = Application.dataPath + "/" + outputPathFull + "/" + lmname + "_RNM" + c + ".hdr";
                if (File.Exists(outPath)) ValidateFileAttribs(outPath);

                // Encode RNM
                progressText2 = "Encoding RNM" + c + " for " + lmname + "...";
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
                //startInfo.WorkingDirectory = scenePath;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/halffloat2hdr.exe";
                startInfo.CreateNoWindow = true;
                startInfo.Arguments       = "\"" + scenePath + "/" + lmname + "_final_RNM" + c + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + outPath + "\" " + maxValue;
                if (deferredMode)
                {
                    deferredFileSrc.Add("");
                    deferredFileDest.Add("");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText2);
                    if (clientMode) ftClient.serverGetFileList.Add(lmname + "_RNM" + c + ".hdr");
                }
                else
                {
                    Debug.LogError("Not supported");
                }
            }
        }

        if (shMode && !vertexBake && lightmapHasRNM[LMID])
        {
            var outPath = Application.dataPath + "/" + outputPathFull + "/" + lmname + "_L0.hdr";
            if (File.Exists(outPath)) ValidateFileAttribs(outPath);

            progressText2 = "Encoding SH L0 for " + lmname + "...";
            startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
            //startInfo.WorkingDirectory = scenePath;
#if !LAUNCH_VIA_DLL
            startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
            startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/halffloat2hdr.exe";
            startInfo.CreateNoWindow = true;
            startInfo.Arguments       = "\"" + scenePath + "/" + lmname + "_final_L0" + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + outPath + "\" " + maxValue;
            if (deferredMode)
            {
                deferredFileSrc.Add("");
                deferredFileDest.Add("");
                deferredCommands.Add(startInfo);
                deferredCommandDesc.Add(progressText2);
                if (clientMode) ftClient.serverGetFileList.Add(lmname + "_L0.hdr");
            }
            else
            {
                Debug.LogError("Not supported");
            }

            progressText2 = "Encoding SH L1 for " + lmname + "...";
            if (shModeMono)
            {
                startInfo = new System.Diagnostics.ProcessStartInfo();
                startInfo.CreateNoWindow  = false;
                startInfo.UseShellExecute = false;
                //startInfo.WorkingDirectory = scenePath;
#if !LAUNCH_VIA_DLL
                startInfo.WorkingDirectory = dllPath + "/Bakery";
#endif
                startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/combineSH.exe";
                startInfo.CreateNoWindow = true;

                var outPath1 = Application.dataPath + "/" + outputPathFull + "/" + lmname + "_L1" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                if (File.Exists(outPath1)) ValidateFileAttribs(outPath1);

                startInfo.Arguments       = " \"" + outPath1 + "\"" + 
                                            " \"" + scenePath + "/" + lmname + "_final_L1x" + (compressedOutput ? ".lz4" : ".dds") + "\"" +
                                            " \"" + scenePath + "/" + lmname + "_final_L1y" + (compressedOutput ? ".lz4" : ".dds") + "\"" +
                                            " \"" + scenePath + "/" + lmname + "_final_L1z" + (compressedOutput ? ".lz4" : ".dds") + "\"";

                if (deferredMode)
                {
                    deferredFileSrc.Add("");
                    deferredFileDest.Add("");
                    deferredCommands.Add(startInfo);
                    deferredCommandDesc.Add(progressText2);
                    if (clientMode) ftClient.serverGetFileList.Add(lmname + "_L1" + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga"));
                }
                else
                {
                    Debug.LogError("Not supported");
                }
            }
            else
            {
                for(int i=0; i<3; i++)
                {
                    startInfo = new System.Diagnostics.ProcessStartInfo();
                    startInfo.CreateNoWindow  = false;
                    startInfo.UseShellExecute = false;
                    //startInfo.WorkingDirectory = scenePath;
    #if !LAUNCH_VIA_DLL
                    startInfo.WorkingDirectory = dllPath + "/Bakery";
    #endif
                    startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/rgba2tga.exe";
                    startInfo.CreateNoWindow = true;
                    string comp;
                    if (i==0)
                    {
                        comp = "x";
                    }
                    else if (i==1)
                    {
                        comp = "y";
                    }
                    else
                    {
                        comp = "z";
                    }

                    var outPath1 = Application.dataPath + "/" + outputPathFull + "/" + lmname + "_L1" + comp + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga");
                    if (File.Exists(outPath1)) ValidateFileAttribs(outPath1);

                    startInfo.Arguments       = "\"" + scenePath + "/" + lmname + "_final_L1" + comp + (compressedOutput ? ".lz4" : ".dds") + "\" \"" + outPath1 + "\" " + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? "p" : "");

                    if (deferredMode)
                    {
                        deferredFileSrc.Add("");
                        deferredFileDest.Add("");
                        deferredCommands.Add(startInfo);
                        deferredCommandDesc.Add(progressText2);
                        if (clientMode) ftClient.serverGetFileList.Add(lmname + "_L1" + comp + (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG ? ".png" : ".tga"));
                    }
                    else
                    {
                        Debug.LogError("Not supported");
                    }
                }
            }
        }
    }

    public static System.IntPtr RunFTrace(string args, bool visible = false)
    {
        DebugLogInfo("Running ftrace " + args);
#if LAUNCH_VIA_DLL
        System.IntPtr exeProcess;

        if (visible)
        {
            exeProcess = RunLocalProcessVisible(ftraceExe+" "+args);
        }
        else
        {
            exeProcess = RunLocalProcess(ftraceExe+" "+args, true);
        }

        if (exeProcess == (System.IntPtr)null)
        {
            Debug.LogError(ftraceExe + " launch failed (see console for details)");
            return (System.IntPtr)0;
        }
        return exeProcess;
#else
        Debug.LogError("Not supported");
        return (System.IntPtr)0;
#endif
    }

    public static ftGlobalStorage FindGlobalStorage()
    {
        if (gstorage == null)
        {
            var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
            gstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;
        }
        return gstorage;
    }

    public static void LoadDefaultSettings(ftLightmapsStorage storage)
    {
        FindGlobalStorage();
        if (gstorage == null) return;
        ftLightmapsStorage.CopySettings(gstorage, storage);
    }

    static List<GameObject> roots;
    public static ftLightmapsStorage FindRenderSettingsStorage()
    {
        // Load saved settings
        GameObject go = null;
        if (roots == null) roots = new List<GameObject>();

        try
        {
            SceneManager.GetActiveScene().GetRootGameObjects(roots);
        }
        catch
        {
            // scene is not loaded, oops
            return null;
        }

        go = roots.Find( g => g.name == "!ftraceLightmaps" );

        if (go == null) go = GameObject.Find("!ftraceLightmaps");
        if (go == null) {
            go = new GameObject();
            go.name = "!ftraceLightmaps";
            go.hideFlags = HideFlags.HideInHierarchy;
        }
        var storage = go.GetComponent<ftLightmapsStorage>();
        if (storage == null) {
            storage = go.AddComponent<ftLightmapsStorage>();
            LoadDefaultSettings(storage);
        }
        return storage;
    }

    public static void LoadStaticAtlasingSettings()
    {
        var storage = FindRenderSettingsStorage();
        ftRenderLightmap.tileSize = storage.renderSettingsTileSize;
        ftBuildGraphics.texelsPerUnit = storage.renderSettingsTexelsPerUnit;
        ftBuildGraphics.autoAtlas = storage.renderSettingsAutoAtlas;
        ftBuildGraphics.unwrapUVs = storage.renderSettingsUnwrapUVs;
        ftBuildGraphics.forceDisableUnwrapUVs = storage.renderSettingsForceDisableUnwrapUVs;
        ftBuildGraphics.maxAutoResolution = storage.renderSettingsMaxAutoResolution;
        ftBuildGraphics.minAutoResolution = storage.renderSettingsMinAutoResolution;
        ftRenderLightmap.checkOverlaps = storage.renderSettingsCheckOverlaps;
        ftBuildGraphics.texelsPerUnitPerMap = storage.renderSettingsTexelsPerMap;
        ftBuildGraphics.mainLightmapScale = storage.renderSettingsTexelsColor;
        ftBuildGraphics.maskLightmapScale = storage.renderSettingsTexelsMask;
        ftBuildGraphics.dirLightmapScale = storage.renderSettingsTexelsDir;
        ftBuildGraphics.splitByScene = storage.renderSettingsSplitByScene;
        ftBuildGraphics.splitByTag = storage.renderSettingsSplitByTag;
        ftBuildGraphics.uvPaddingMax = storage.renderSettingsUVPaddingMax;
        ftBuildGraphics.postPacking = storage.renderSettingsPostPacking;
        ftBuildGraphics.holeFilling = storage.renderSettingsHoleFilling;
        ftBuildGraphics.atlasPacker = storage.renderSettingsAtlasPacker;
    }

    public void LoadRenderSettings()
    {
        FindGlobalStorage();
        if (gstorage != null)
        {
            foundCompatibleSetup = gstorage.foundCompatibleSetup;
            scenePath = gstorage.renderSettingsTempPath;
        }

        instance = this;
        var storage = instance.renderSettingsStorage = FindRenderSettingsStorage();
        if (storage == null) return;
        bounces = storage.renderSettingsBounces;
        instance.giSamples = storage.renderSettingsGISamples;
        giBackFaceWeight = storage.renderSettingsGIBackFaceWeight;
        ftRenderLightmap.tileSize = storage.renderSettingsTileSize;
        instance.priority = storage.renderSettingsPriority;
        instance.texelsPerUnit = ftBuildGraphics.texelsPerUnit = storage.renderSettingsTexelsPerUnit;
        ftRenderLightmap.forceRefresh = storage.renderSettingsForceRefresh;
        instance.forceRebuildGeometry = storage.renderSettingsForceRebuildGeometry;
        instance.performRendering = storage.renderSettingsPerformRendering;
        instance.userRenderMode = (RenderMode)storage.renderSettingsUserRenderMode;
        instance.settingsMode = (SettingsMode)storage.renderSettingsSettingsMode;
        instance.fixSeams = storage.renderSettingsFixSeams;
        instance.denoise = storage.renderSettingsDenoise;
        instance.denoise2x = storage.renderSettingsDenoise2x;
        instance.encode = storage.renderSettingsEncode;
        instance.encodeMode = storage.renderSettingsEncodeMode;
        ftBuildGraphics.overwriteWarning = storage.renderSettingsOverwriteWarning;
        ftBuildGraphics.autoAtlas = storage.renderSettingsAutoAtlas;
        ftBuildGraphics.unwrapUVs = storage.renderSettingsUnwrapUVs;
        ftBuildGraphics.forceDisableUnwrapUVs = storage.renderSettingsForceDisableUnwrapUVs;
        ftBuildGraphics.maxAutoResolution = storage.renderSettingsMaxAutoResolution;
        ftBuildGraphics.minAutoResolution = storage.renderSettingsMinAutoResolution;
        instance.unloadScenesInDeferredMode = storage.renderSettingsUnloadScenes;
        ftRenderLightmap.adjustSamples = storage.renderSettingsAdjustSamples;
        ftRenderLightmap.giLodMode = (GILODMode)storage.renderSettingsGILODMode;
        ftRenderLightmap.giLodModeEnabled = storage.renderSettingsGILODModeEnabled;
        ftRenderLightmap.checkOverlaps = storage.renderSettingsCheckOverlaps;
        ftRenderLightmap.outputPath = storage.renderSettingsOutPath == "" ? "BakeryLightmaps" : storage.renderSettingsOutPath;
        ftRenderLightmap.useScenePath = storage.renderSettingsUseScenePath;
        hackEmissiveBoost = storage.renderSettingsHackEmissiveBoost;
        hackIndirectBoost = storage.renderSettingsHackIndirectBoost;
        hackAOIntensity = renderSettingsStorage.renderSettingsHackAOIntensity;
        hackAORadius = renderSettingsStorage.renderSettingsHackAORadius;
        hackAOSamples = renderSettingsStorage.renderSettingsHackAOSamples;
        showAOSettings = renderSettingsStorage.renderSettingsShowAOSettings;
        showTasks = renderSettingsStorage.renderSettingsShowTasks;
        showTasks2 = renderSettingsStorage.renderSettingsShowTasks2;
        showPaths = renderSettingsStorage.renderSettingsShowPaths;
        showNet = renderSettingsStorage.renderSettingsShowNet;
        showPerf = renderSettingsStorage.renderSettingsShowPerf;
        //showCompression = renderSettingsStorage.renderSettingsShowCompression;
        ftBuildGraphics.texelsPerUnitPerMap = renderSettingsStorage.renderSettingsTexelsPerMap;
        ftBuildGraphics.mainLightmapScale = renderSettingsStorage.renderSettingsTexelsColor;
        ftBuildGraphics.maskLightmapScale = renderSettingsStorage.renderSettingsTexelsMask;
        ftBuildGraphics.dirLightmapScale = renderSettingsStorage.renderSettingsTexelsDir;
        useUnityForOcclsusionProbes = renderSettingsStorage.renderSettingsOcclusionProbes;
        lastBakeTime = renderSettingsStorage.lastBakeTime;
        beepOnFinish = renderSettingsStorage.renderSettingsBeepOnFinish;
        ftBuildGraphics.exportTerrainAsHeightmap = renderSettingsStorage.renderSettingsExportTerrainAsHeightmap;
        ftBuildGraphics.exportTerrainTrees = renderSettingsStorage.renderSettingsExportTerrainTrees;
        rtxMode = renderSettingsStorage.renderSettingsRTXMode;
        lightProbeMode = (LightProbeMode)renderSettingsStorage.renderSettingsLightProbeMode;
        clientMode = renderSettingsStorage.renderSettingsClientMode;
        ftClient.serverAddress = renderSettingsStorage.renderSettingsServerAddress;
        unwrapper = (ftGlobalStorage.Unwrapper)renderSettingsStorage.renderSettingsUnwrapper;
        denoiserType = (ftGlobalStorage.DenoiserType)renderSettingsStorage.renderSettingsDenoiserType;
        //legacyDenoiser = renderSettingsStorage.renderSettingsLegacyDenoiser;
        ftBuildGraphics.atlasPacker = renderSettingsStorage.renderSettingsAtlasPacker;
        sampleDivisor = storage.renderSettingsSampleDiv;
        if (storage.renderSettingsSector != null) curSector = (BakerySector)storage.renderSettingsSector;

        ftraceExe = rtxMode ? ftraceExe6 : ftraceExe1;
        //scenePath = storage.renderSettingsTempPath;

        if (scenePath == "") scenePath = System.Environment.GetEnvironmentVariable("TEMP", System.EnvironmentVariableTarget.Process) + "\\frender";
        ftBuildGraphics.scenePath = scenePath;
        scenePathQuoted = "\"" + scenePath + "\"";

#if UNITY_2017_1_OR_NEWER
        isDistanceShadowmask = QualitySettings.shadowmaskMode == ShadowmaskMode.DistanceShadowmask;
#else
        isDistanceShadowmask = storage.renderSettingsDistanceShadowmask;
#endif
        showDirWarning = storage.renderSettingsShowDirWarning;
        renderDirMode = (RenderDirMode)storage.renderSettingsRenderDirMode;
        showCheckerSettings = storage.renderSettingsShowCheckerSettings;
        usesRealtimeGI = storage.usesRealtimeGI;
        samplesWarning = storage.renderSettingsSamplesWarning;
        suppressPopups = storage.renderSettingsSuppressPopups;
        prefabWarning = storage.renderSettingsPrefabWarning;
        ftBuildGraphics.splitByScene = storage.renderSettingsSplitByScene;
        ftBuildGraphics.splitByTag = storage.renderSettingsSplitByTag;
        ftBuildGraphics.uvPaddingMax = storage.renderSettingsUVPaddingMax;
        ftBuildGraphics.postPacking = storage.renderSettingsPostPacking;
        ftBuildGraphics.holeFilling = storage.renderSettingsHoleFilling;
        compressVolumes = storage.renderSettingsCompressVolumes;
    }

    void OnEnable()
    {
        LoadRenderSettings();
    }

	[MenuItem ("Bakery/Render lightmap...", false, 0)]
	public static void RenderLightmap ()
    {
        instance = (ftRenderLightmap)GetWindow(typeof(ftRenderLightmap));
        instance.titleContent.text = "Bakery";
        var edPath = ftLightmaps.GetEditorPath();
        var icon = EditorGUIUtility.Load(edPath + "icon.png") as Texture2D;
        instance.titleContent.image = icon;
        instance.Show();
        ftLightmaps.GetRuntimePath();
	}
}

#endif
