#define USE_TERRAINS

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Disable 'obsolete' warnings
#pragma warning disable 0618

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.IO;
#endif

using UnityEngine.SceneManagement;

#if UNITY_EDITOR
[InitializeOnLoad]
#endif
public class ftLightmaps {

    struct LightmapAdditionalData
    {
       public Texture2D rnm0, rnm1, rnm2;
       public int mode;
    };

    static List<int> lightmapRefCount;
    static List<LightmapAdditionalData> globalMapsAdditional;
    static int directionalMode; // -1 undefined, 0 off, 1 on
    //static List<ftLightmapsStorage> loadedStorages;

#if UNITY_EDITOR
    public static bool mustReloadRenderSettings = false;
    static ftGlobalStorage gstorage;
    static ftLocalStorage lstorage;
    static BakeryProjectSettings pstorage;
    static bool editorUpdateCalled = false;

    public static string _bakeryRuntimePath = "";
    public static string _bakeryEditorPath = "";
    public static string GetRuntimePath()
    {
        if (_bakeryRuntimePath.Length == 0)
        {
            // Try default path
            // (start with AssetDatabase assuming it's faster than GetFiles)
            var a = AssetDatabase.LoadAssetAtPath("Assets/Bakery/ftDefaultAreaLightMat.mat", typeof(Material)) as Material;
            if (a == null)
            {
                // Find elsewhere
                var assetGUIDs = AssetDatabase.FindAssets("ftDefaultAreaLightMat", null);
                if (assetGUIDs.Length == 0)
                {
                    // No extra data present - find the script at least
                    var res = Directory.GetFiles(Application.dataPath, "ftLightmaps.cs", SearchOption.AllDirectories);
                    if (res.Length == 0)
                    {
                        Debug.LogError("Can't locate Bakery folder");
                        return "";
                    }
                    return "Assets" + res[0].Replace("ftLightmaps.cs", "").Replace("\\", "/").Replace(Application.dataPath, "");
                }
                if (assetGUIDs.Length > 1)
                {
                    Debug.LogError("ftDefaultAreaLightMat was found in more than one folder. Do you have multiple installations of Bakery?");
                }
                var guid = assetGUIDs[0];
                _bakeryRuntimePath = System.IO.Path.GetDirectoryName(AssetDatabase.GUIDToAssetPath(guid)) + "/";
                return _bakeryRuntimePath;
            }
            _bakeryRuntimePath = "Assets/Bakery/";
        }
        return _bakeryRuntimePath;
    }

    public static string GetEditorPath()
    {
        if (_bakeryEditorPath.Length == 0)
        {
            // Try default path
            var a = AssetDatabase.LoadAssetAtPath("Assets/Editor/x64/Bakery/NormalsFittingTexture_dds", typeof(Object));
            if (a == null)
            {
                // Find elsewhere
                var assetGUIDs = AssetDatabase.FindAssets("NormalsFittingTexture_dds", null);
                if (assetGUIDs.Length == 0)
                {
                    // No extra data present - find ftModelPostProcessor at least (minimum required editor script)
                    var res = Directory.GetFiles(Application.dataPath, "ftModelPostProcessor.cs", SearchOption.AllDirectories);
                    if (res.Length == 0)
                    {
                        Debug.LogError("Can't locate Bakery folder");
                        return "";
                    }
                    return "Assets" + res[0].Replace("ftModelPostProcessor.cs", "").Replace("\\", "/").Replace(Application.dataPath, "");
                }
                if (assetGUIDs.Length > 1)
                {
                    Debug.LogError("NormalsFittingTexture_dds was found in more than one folder. Do you have multiple installations of Bakery?");
                }
                var guid = assetGUIDs[0];
                _bakeryEditorPath = System.IO.Path.GetDirectoryName(AssetDatabase.GUIDToAssetPath(guid)) + "/";
                return _bakeryEditorPath;
            }
            _bakeryEditorPath = "Assets/Editor/x64/Bakery/";
        }
        return _bakeryEditorPath;
    }

    public static string GetProjectSettingsPathOld()
    {
        return "Assets/Settings/";
    }

    public static string GetProjectSettingsPathNew()
    {
        var path = GetRuntimePath();
        for(int i=path.Length-2; i>=0; i--)
        {
            char c = path[i];
            if (c == '/' || c == '\\')
            {
                path = path.Substring(0, i);
                break;
            }
        }
        return path + "/Settings/";
    }

    public static ftGlobalStorage GetGlobalStorage()
    {
        if (gstorage != null) return gstorage;
        var bakeryRuntimePath = GetRuntimePath();
        gstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;
        if (gstorage == null && editorUpdateCalled) // if editorUpdateCalled==false, it may be not imported yet
        {
            var gstorageDefault = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftDefaultGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;

            if (gstorageDefault != null)
            {
                if (AssetDatabase.CopyAsset(bakeryRuntimePath + "ftDefaultGlobalStorage.asset", bakeryRuntimePath + "ftGlobalStorage.asset"))
                {
                    AssetDatabase.Refresh();
                    gstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;
                }
            }

            if (gstorage == null)
            {
                Debug.Log("Created Bakery GlobalStorage");
                gstorage = ScriptableObject.CreateInstance<ftGlobalStorage>();
                AssetDatabase.CreateAsset(gstorage, bakeryRuntimePath + "ftGlobalStorage.asset");
                AssetDatabase.SaveAssets();
            }
            else
            {
                Debug.Log("Created Bakery GlobalStorage from DefaultGlobalStorage");
            }
        }

        if (gstorage != null)
        {
            if (gstorage.modifiedMeshList.Count > 0)
            {
                gstorage.ConvertFromLegacy();
            }
        }

        return gstorage;
    }

    static ftLocalStorage GetLocalStorage()
    {
        if (lstorage != null) return lstorage;
        var bakeryRuntimePath = GetRuntimePath();
        lstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftLocalStorage.asset", typeof(ftLocalStorage)) as ftLocalStorage;
        if (lstorage == null)
        {
            Debug.Log("Created Bakery LocalStorage");
            lstorage = ScriptableObject.CreateInstance<ftLocalStorage>();
            AssetDatabase.CreateAsset(lstorage, bakeryRuntimePath + "ftLocalStorage.asset");
            AssetDatabase.SaveAssets();
        }
        return lstorage;
    }

    public static BakeryProjectSettings GetProjectSettings()
    {
        if (pstorage != null) return pstorage;
        var path = GetProjectSettingsPathOld();
        if (!Directory.Exists(path))
        {
            path = GetProjectSettingsPathNew();
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
        }
        pstorage = AssetDatabase.LoadAssetAtPath(path + "BakeryProjectSettings.asset", typeof(BakeryProjectSettings)) as BakeryProjectSettings;
        if (pstorage == null)
        {
            Debug.Log("Created Bakery ProjectSettings");
            pstorage = ScriptableObject.CreateInstance<BakeryProjectSettings>();
            AssetDatabase.CreateAsset(pstorage, path + "BakeryProjectSettings.asset");
            AssetDatabase.SaveAssets();
        }
        return pstorage;
    }

    static void CreateGlobalStorageAsset()
    {
        if (gstorage == null) gstorage = GetGlobalStorage();
        if (lstorage == null) lstorage = GetLocalStorage();

        if (Application.isPlaying) return;

        var listToProccess = gstorage.modifiedAssetPathList;
        var listToProcessHash = gstorage.modifiedAssetPaddingHash;
        var listProcessed = lstorage.modifiedAssetPathList;
        var listProcessedHash = lstorage.modifiedAssetPaddingHash;
        for(int i=0; i<listToProccess.Count; i++)
        {
            int localID = listProcessed.IndexOf(listToProccess[i]);
            if (localID >= 0)
            {
                if (listToProcessHash.Count > i)
                {
                    int globalPaddingHash = listToProcessHash[i];
                    if (listProcessedHash.Count > localID)
                    {
                        int localPaddingHash = listProcessedHash[localID];
                        if (globalPaddingHash == localPaddingHash)
                        {
                            continue;
                        }
                    }
                }
                else
                {
                    // Hash is not initialized = legacy
                    continue;
                }
            }

#if UNITY_2017_1_OR_NEWER
            var importer = AssetImporter.GetAtPath(listToProccess[i]) as ModelImporter;
            if (importer != null)
            {
                var props = importer.extraUserProperties;
                int propID = -1;
                for(int p=0; p<props.Length; p++)
                {
                    if (props[p].Substring(0,7) == "#BAKERY")
                    {
                        propID = p;
                        break;
                    }
                }
                if (propID >= 0) continue; // should be fine without additional reimport - metadata is always loaded with model
            }
#endif

            var asset = AssetDatabase.LoadAssetAtPath(listToProccess[i], typeof(GameObject)) as GameObject;
            if (asset == null) continue;
            if (asset.tag == "BakeryProcessed") continue; // legacy
            //if (asset.tag != "BakeryProcessed") AssetDatabase.ImportAsset(list[i], ImportAssetOptions.ForceUpdate);
            Debug.Log("Reimporting to adjust UVs: " + listToProccess[i]);
            AssetDatabase.ImportAsset(listToProccess[i], ImportAssetOptions.ForceUpdate);
        }
    }

    /*public static bool IsModelProcessed(string path)
    {
        if (lstorage == null) lstorage = GetLocalStorage();
        var listProcessed = lstorage.modifiedAssetPathList;
        return listProcessed.Contains(path);
    }*/

    public static void MarkModelProcessed(string path, bool enabled)
    {
        if (lstorage == null) lstorage = GetLocalStorage();
        if (gstorage == null) gstorage = GetGlobalStorage();
        if (enabled)
        {
            int gid = gstorage.modifiedAssetPathList.IndexOf(path);
            if (gid < 0) return;
            int hash = gstorage.CalculatePaddingHash(gid);
            while(gstorage.modifiedAssetPaddingHash.Count <= gid) gstorage.modifiedAssetPaddingHash.Add(0);
            gstorage.modifiedAssetPaddingHash[gid] = hash;

            int id = lstorage.modifiedAssetPathList.IndexOf(path);
            if (id < 0)
            {
                lstorage.modifiedAssetPathList.Add(path);
                id = lstorage.modifiedAssetPathList.Count - 1;
            }
            while(lstorage.modifiedAssetPaddingHash.Count <= id) lstorage.modifiedAssetPaddingHash.Add(0);
            lstorage.modifiedAssetPaddingHash[id] = hash;
            EditorUtility.SetDirty(gstorage);
            EditorSceneManager.MarkAllScenesDirty();
        }
        else
        {
            int id = lstorage.modifiedAssetPathList.IndexOf(path);
            if (id >= 0)
            {
                lstorage.modifiedAssetPathList.RemoveAt(id);
                if (lstorage.modifiedAssetPaddingHash.Count > id) lstorage.modifiedAssetPaddingHash.RemoveAt(id);
            }
        }
        EditorUtility.SetDirty(lstorage);
    }

#endif

    static ftLightmaps() {

#if UNITY_EDITOR
        EditorSceneManager.sceneOpening -= OnSceneOpening; // Andrew fix
        EditorSceneManager.sceneOpening += OnSceneOpening;

        EditorApplication.update -= FirstUpdate; // Andrew fix
        EditorApplication.update += FirstUpdate;

        EditorApplication.hierarchyWindowChanged -= OnSceneChangedEditor;
        EditorApplication.hierarchyWindowChanged += OnSceneChangedEditor;
#endif

        SceneManager.activeSceneChanged -= OnSceneChangedPlay;
        SceneManager.activeSceneChanged += OnSceneChangedPlay;
    }

#if UNITY_EDITOR
    static void FirstUpdate()
    {
        editorUpdateCalled = true;
        CreateGlobalStorageAsset();
        GetProjectSettings();
        EditorApplication.update -= FirstUpdate;
    }
#endif

    static void SetDirectionalMode()
    {
        if (directionalMode >= 0) LightmapSettings.lightmapsMode =  directionalMode==1 ? LightmapsMode.CombinedDirectional : LightmapsMode.NonDirectional;
    }

    static void OnSceneChangedPlay(Scene prev, Scene next) {
        //if (Lightmapping.lightingDataAsset == null) {
            SetDirectionalMode();
        //}
    }

#if UNITY_EDITOR
    static void OnSceneChangedEditor() {
        // Unity can modify directional mode on scene change, have to force the correct one
        // activeSceneChangedInEditMode isn't always available
        //if (Lightmapping.lightingDataAsset == null) {
            SetDirectionalMode();
        //}
    }

    // using Opening instead of Opened because it's called before lightmap data is loaded and proper directional mode is set
    //static void OnSceneOpened(Scene scene, OpenSceneMode mode) {
    static void OnSceneOpening(string path, OpenSceneMode mode) {
        //Refresh();
        //if (scene.name == "_tempScene") return;
        if (Path.GetFileNameWithoutExtension(path) == "_tempScene") return;
        mustReloadRenderSettings = true;
        directionalMode = -1;
        /*if (!finalInitDone)
        {
            CreateGlobalStorageAsset();
            finalInitDone = true;
        }*/
    }
#endif

    public static void RefreshFull() {
        var activeScene = SceneManager.GetActiveScene();
        var sceneCount = SceneManager.sceneCount;

        for(int i=0; i<sceneCount; i++)
        {
            var scene = SceneManager.GetSceneAt(i);
            if (!scene.isLoaded) continue;
            SceneManager.SetActiveScene(scene);
            LightmapSettings.lightmaps = new LightmapData[0];
        }

        for(int i=0; i<sceneCount; i++)
        {
            RefreshScene(SceneManager.GetSceneAt(i), null, true);
        }
        SceneManager.SetActiveScene(activeScene);
    }

    public static GameObject FindInScene(string nm, Scene scn)
    {
        var objs = scn.GetRootGameObjects();
        for(int i=0; i<objs.Length; i++)
        {
            if (objs[i].name == nm) return objs[i];
            var obj = objs[i].transform.Find(nm);
            if (obj != null) return obj.gameObject;
        }
        return null;
    }

/*    public static void RefreshScene(int sceneID, ref List<LightmapData> lmaps, int lmCounter) {
        RefreshScene(scene);
    }*/

    static Texture2D GetEmptyDirectionTex(ftLightmapsStorage storage)
    {
#if UNITY_EDITOR
        if (storage.emptyDirectionTex == null)
        {
            var bakeryRuntimePath = GetRuntimePath();
            storage.emptyDirectionTex = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "emptyDirection.tga", typeof(Texture2D)) as Texture2D;
        }
#endif
        return storage.emptyDirectionTex;
    }

    public static void RefreshScene(Scene scene, ftLightmapsStorage storage = null, bool updateNonBaked = false) {
        var sceneCount = SceneManager.sceneCount;

        if (globalMapsAdditional == null) globalMapsAdditional = new List<LightmapAdditionalData>();

        var lmaps = new List<LightmapData>();
        var lmapsAdditional = new List<LightmapAdditionalData>();
        var existingLmaps = LightmapSettings.lightmaps;
        var existingLmapsAdditional = globalMapsAdditional;

        // Acquire storage
        if (storage == null)
        {
            if (!scene.isLoaded)
            {
                //Debug.LogError("dbg: Scene not loaded");
                return;
            }
            SceneManager.SetActiveScene(scene);

            var go = FindInScene("!ftraceLightmaps", scene);
            if (go==null) {
                //Debug.LogError("dbg: no storage");
                return;
            }

            storage = go.GetComponent<ftLightmapsStorage>();
            if (storage == null) {
                //Debug.LogError("dbg: no storage 2");
                return;
            }
        }
        if (storage.idremap == null || storage.idremap.Length != storage.maps.Count)
        {
            storage.idremap = new int[storage.maps.Count];
        }

        // Decide which global engine lightmapping mode to use
        // TODO: allow mixing different modes
        directionalMode = storage.dirMaps.Count != 0 ? 1 : 0;
        bool patchedDirection = false;
        SetDirectionalMode();

        // Set dummy directional tex for non-directional lightmaps in directional mode
        if (directionalMode == 1)
        {
            for(int i=0; i<existingLmaps.Length; i++)
            {
                if (existingLmaps[i].lightmapDir == null)
                {
                    var lm = existingLmaps[i];
                    lm.lightmapDir = GetEmptyDirectionTex(storage);
                    existingLmaps[i] = lm;
                    patchedDirection = true;
                }
            }
        }

        // Detect if changes to lightmap array are necessary
        bool sameArray = false;
        if (existingLmaps.Length == storage.maps.Count)
        {
            sameArray = true;
            for(int i=0; i<storage.maps.Count; i++)
            {
                if (existingLmaps[i].lightmapColor != storage.maps[i])
                {
                    sameArray = false;
                    break;
                }
                if (storage.rnmMaps0.Count > i && (existingLmapsAdditional.Count <= i || existingLmapsAdditional[i].rnm0 != storage.rnmMaps0[i]))
                {
                    sameArray = false;
                    break;
                }
            }
        }

        if (!sameArray) // create new lightmap array
        {
            if (sceneCount >= 1)
            {
                // first add old
                for(int i=0; i<existingLmaps.Length; i++) {
                    // skip empty lightmaps (can be created by 5.6 ldata asset or vertex color)
                    // ... unless there are valid lightmaps around them
                    bool lightmapIsEmpty = existingLmaps[i] == null || (existingLmaps[i].lightmapColor == null && existingLmaps[i].shadowMask == null);
                    bool lightmapCanBeSkipped = lightmapIsEmpty && (i == 0 || i == existingLmaps.Length - 1);
                    if (!lightmapCanBeSkipped)
                    {
                        lmaps.Add(existingLmaps[i]);
                        if (existingLmapsAdditional.Count > i) lmapsAdditional.Add(existingLmapsAdditional[i]);
                    }
                }
            }

            for(int i=0; i<storage.maps.Count; i++) {

                var texlm = storage.maps[i];
                Texture2D texmask = null;
                Texture2D texdir = null;
                Texture2D texrnm0 = null;
                Texture2D texrnm1 = null;
                Texture2D texrnm2 = null;
                int mapMode = 0;
                if (storage.masks.Count > i) texmask = storage.masks[i];
                if (storage.dirMaps.Count > i) texdir = storage.dirMaps[i];
                if (storage.rnmMaps0.Count > i)
                {
                    texrnm0 = storage.rnmMaps0[i];
                    texrnm1 = storage.rnmMaps1[i];
                    texrnm2 = storage.rnmMaps2[i];
                    mapMode = storage.mapsMode[i];
                }

                bool found = false;
                int firstEmpty = -1;
                for(int j=0; j<lmaps.Count; j++) {
                    if (lmaps[j].lightmapColor == texlm && lmaps[j].shadowMask == texmask)
                    {
                        // lightmap already added - reuse
                        storage.idremap[i] = j;
                        found = true;

                        //Debug.LogError("reused "+j);

                        // additional maps array could be flushed due to script recompilation - recover
                        if (texrnm0 != null && (lmapsAdditional.Count <= j || lmapsAdditional[j].rnm0 == null))
                        {
                            while(lmapsAdditional.Count <= j) lmapsAdditional.Add(new LightmapAdditionalData());
                            var l = new LightmapAdditionalData();
                            l.rnm0 = texrnm0;
                            l.rnm1 = texrnm1;
                            l.rnm2 = texrnm2;
                            l.mode = mapMode;
                            lmapsAdditional[j] = l;
                        }

                        break;
                    }
                    else if (firstEmpty < 0 && lmaps[j].lightmapColor == null && lmaps[j].shadowMask == null)
                    {
                        // free (deleted) entry in existing lightmap list - possibly reuse
                        storage.idremap[i] = j;
                        firstEmpty = j;
                    }
                }

                if (!found)
                {
                    LightmapData lm;
                    if (firstEmpty >= 0)
                    {
                        lm = lmaps[firstEmpty];
                    }
                    else
                    {
                        lm = new LightmapData();
                    }

                    lm.lightmapColor = texlm;
                    if (storage.masks.Count > i)
                    {
                        lm.shadowMask = texmask;
                    }
                    if (storage.dirMaps.Count > i && texdir != null)
                    {
                        lm.lightmapDir = texdir;
                    }
                    else if (directionalMode == 1)
                    {
                        lm.lightmapDir = GetEmptyDirectionTex(storage);
                    }

                    if (firstEmpty < 0)
                    {
                        lmaps.Add(lm);
                        storage.idremap[i] = lmaps.Count - 1;
                    }
                    else
                    {
                        lmaps[firstEmpty] = lm;
                    }

                    if (storage.rnmMaps0.Count > i)
                    {
                        var l = new LightmapAdditionalData();
                        l.rnm0 = texrnm0;
                        l.rnm1 = texrnm1;
                        l.rnm2 = texrnm2;
                        l.mode = mapMode;

                        if (firstEmpty < 0)
                        {
                            //Debug.LogError("added "+(lmaps.Count-1));
                            while(lmapsAdditional.Count < lmaps.Count-1) lmapsAdditional.Add(new LightmapAdditionalData());
                            lmapsAdditional.Add(l);
                        }
                        else
                        {
                            //Debug.LogError("set " + firstEmpty);
                            while(lmapsAdditional.Count < firstEmpty+1) lmapsAdditional.Add(new LightmapAdditionalData());
                            lmapsAdditional[firstEmpty] = l;
                        }
                    }
                }
            }
        }
        else // reuse existing lightmap array, only remap IDs
        {
            for(int i=0; i<storage.maps.Count; i++) {
                storage.idremap[i] = i;

                //Debug.LogError("full reuse");

                /*if (storage.rnmMaps0.Count > i)
                {
                    var l = new LightmapAdditionalData();
                    l.rnm0 = storage.rnmMaps0[i];
                    l.rnm1 = storage.rnmMaps1[i];
                    l.rnm2 = storage.rnmMaps2[i];
                    l.mode = storage.mapsMode[i];
                    lmapsAdditional.Add(l);
                }*/
            }
        }

#if UNITY_EDITOR
        // Set editor lighting mode
        if (storage.bakedRenderers != null && storage.bakedRenderers.Count > 0)
        {
            Lightmapping.giWorkflowMode = Lightmapping.GIWorkflowMode.OnDemand;
            Lightmapping.realtimeGI = storage.usesRealtimeGI;
            //Lightmapping.bakedGI = true; // ? only used for enlighten ? makes editor laggy ?
        }
#endif

        // Replace the lightmap array if needed
        if (sameArray && patchedDirection) LightmapSettings.lightmaps = existingLmaps;
        if (!sameArray)
        {
            LightmapSettings.lightmaps = lmaps.ToArray();
            globalMapsAdditional = lmapsAdditional;
        }

        /*
        // Debug
        var lms = LightmapSettings.lightmaps;
        for(int i=0; i<lms.Length; i++)
        {
            var name1 = ((lms[i]==null || lms[i].lightmapColor==null) ? "-" : lms[i].lightmapColor.name);
            var name2 = (globalMapsAdditional.Count > i ?(globalMapsAdditional[i].rnm0==null?"x":globalMapsAdditional[i].rnm0.name) : "-");
            Debug.LogError(i+" "+name1+" "+name2);
        }
        */

        // Attempt to update skybox probe
        if (RenderSettings.ambientMode == UnityEngine.Rendering.AmbientMode.Skybox)// && Lightmapping.lightingDataAsset == null)
        {
            var probe = RenderSettings.ambientProbe ;
            int isEmpty = -1;
            for(int i=0; i<3; i++)
            {
                for(int j=0; j<9; j++)
                {
                    // default bugged probes are [almost] black or 1302?
                    float a = Mathf.Abs(probe[i,j]);
                    if (a > 1000.0f || a < 0.000001f)
                    {
                        isEmpty = 1;
                        break;
                    }
                    if (probe[i,j] != 0)
                    {
                        isEmpty = 0;
                        break;
                    }
                }
                if (isEmpty >= 0) break;
            }
            if (isEmpty != 0)
            {
               DynamicGI.UpdateEnvironment();
            }
        }

        // Set lightmap data on mesh renderers
        var emptyVec4 = new Vector4(1,1,0,0);
        for(int i=0; i<storage.bakedRenderers.Count; i++)
        {
            var r = storage.bakedRenderers[i];
            if (r == null)
            {
                continue;
            }
            //if (r.isPartOfStaticBatch) continue;
            var id = storage.bakedIDs[i];
            Mesh vmesh = null;
            if (i < storage.bakedVertexColorMesh.Count) vmesh = storage.bakedVertexColorMesh[i];

            if (vmesh != null)
            {
                var r2 = r as MeshRenderer;
                if (r2 == null)
                {
                    Debug.LogError("Unity cannot use additionalVertexStreams on non-MeshRenderer");
                }
                else
                {
                    r2.additionalVertexStreams = vmesh;
                    r2.lightmapIndex = 0xFFFF;
                    var prop = new MaterialPropertyBlock();
                    prop.SetFloat("bakeryLightmapMode", 1);
                    r2.SetPropertyBlock(prop);
                }
                continue;
            }

            int globalID = (id < 0 || id >= storage.idremap.Length) ? id : storage.idremap[id];
            r.lightmapIndex = globalID;

            if (!r.isPartOfStaticBatch)
            {
                // scaleOffset is baked on static batches already
                var scaleOffset = id < 0 ? emptyVec4 : storage.bakedScaleOffset[i];
                r.lightmapScaleOffset = scaleOffset;
            }

            if (r.lightmapIndex >= 0 && globalID < globalMapsAdditional.Count)
            {
                var lmap = globalMapsAdditional[globalID];
                if (lmap.rnm0 != null)
                {
                    var prop = new MaterialPropertyBlock();
                    prop.SetTexture("_RNM0", lmap.rnm0);
                    prop.SetTexture("_RNM1", lmap.rnm1);
                    prop.SetTexture("_RNM2", lmap.rnm2);
                    prop.SetFloat("bakeryLightmapMode", lmap.mode);
                    r.SetPropertyBlock(prop);
                }
            }
        }

        // Set lightmap data on definitely-not-baked mesh renderers (can be possibly avoided)
        if (updateNonBaked)
        {
            for(int i=0; i<storage.nonBakedRenderers.Count; i++)
            {
                var r = storage.nonBakedRenderers[i];
                if (r == null) continue;
                if (r.isPartOfStaticBatch) continue;
                r.lightmapIndex = 0xFFFE;
            }
        }

#if USE_TERRAINS
        // Set lightmap data on terrains
        for(int i=0; i<storage.bakedRenderersTerrain.Count; i++)
        {
            var r = storage.bakedRenderersTerrain[i];
            if (r == null)
            {
                continue;
            }
            var id = storage.bakedIDsTerrain[i];
            r.lightmapIndex = (id < 0 || id >= storage.idremap.Length) ? id : storage.idremap[id];

            var scaleOffset = id < 0 ? emptyVec4 : storage.bakedScaleOffsetTerrain[i];
            r.lightmapScaleOffset = scaleOffset;

            if (r.lightmapIndex >= 0 && r.lightmapIndex < globalMapsAdditional.Count)
            {
                var lmap = globalMapsAdditional[r.lightmapIndex];
                if (lmap.rnm0 != null)
                {
                    var prop = new MaterialPropertyBlock();
                    prop.SetTexture("_RNM0", lmap.rnm0);
                    prop.SetTexture("_RNM1", lmap.rnm1);
                    prop.SetTexture("_RNM2", lmap.rnm2);
                    prop.SetFloat("bakeryLightmapMode", lmap.mode);
                    r.SetSplatMaterialPropertyBlock(prop);
                }
            }
        }
#endif

        // Set shadowmask parameters on lights
        for(int i=0; i<storage.bakedLights.Count; i++)
        {
#if UNITY_2017_3_OR_NEWER
            if (storage.bakedLights[i] == null) continue;

            int channel = storage.bakedLightChannels[i];
            var output = new LightBakingOutput();
            output.isBaked = true;
            if (channel < 0)
            {
                output.lightmapBakeType = LightmapBakeType.Baked;
            }
            else
            {
                output.lightmapBakeType = LightmapBakeType.Mixed;
                output.mixedLightingMode = channel > 100 ? MixedLightingMode.Subtractive : MixedLightingMode.Shadowmask;
                output.occlusionMaskChannel = channel > 100 ? -1 : channel;
                output.probeOcclusionLightIndex  = storage.bakedLights[i].bakingOutput.probeOcclusionLightIndex;
            }
            storage.bakedLights[i].bakingOutput = output;
#endif
        }

        // Increment lightmap refcounts
        if (lightmapRefCount == null) lightmapRefCount = new List<int>();
        for(int i=0; i<storage.idremap.Length; i++)
        {
            int currentID = storage.idremap[i];
            while(lightmapRefCount.Count <= currentID) lightmapRefCount.Add(0);
            if (lightmapRefCount[currentID] < 0) lightmapRefCount[currentID] = 0;
            lightmapRefCount[currentID]++;
        }
        //if (loadedStorages == null) loadedStorages = new List<ftLightmapsStorage>();
        //if (loadedStorages.Contains(storage)) loadedStorages.Add(storage);

        //return appendOffset;
    }

    public static void UnloadScene(ftLightmapsStorage storage)
    {
        if (lightmapRefCount == null) return;
        if (storage.idremap == null) return;

        //int idx = loadedStorages.IndexOf(storage);
        //if (idx >= 0) loadedStorages.RemoveAt(idx);

        LightmapData[] existingLmaps = null;
        List<LightmapAdditionalData> existingLmapsAdditional = null;
        //bool rebuild = false;
        for(int i=0; i<storage.idremap.Length; i++)
        {
            int currentID = storage.idremap[i];

            // just never unload the 1st lightmap to prevent Unity from losing LM encoding settings
            // remapping all IDs at runtime would introduce a perf hiccup
            if (currentID == 0) continue;

            if (lightmapRefCount.Count <= currentID) continue;
            lightmapRefCount[currentID]--;
            //Debug.LogError("rem: "+currentID+" "+lightmapRefCount[currentID]);
            if (lightmapRefCount[currentID] == 0)
            {
                if (existingLmaps == null) existingLmaps = LightmapSettings.lightmaps;

                if (existingLmaps.Length > currentID)
                {
                    existingLmaps[currentID].lightmapColor = null;
                    existingLmaps[currentID].lightmapDir = null;
                    existingLmaps[currentID].shadowMask = null;

                    if (existingLmapsAdditional == null) existingLmapsAdditional = globalMapsAdditional;
                    if (existingLmapsAdditional != null && existingLmapsAdditional.Count > currentID)
                    {
                        var emptyEntry = new LightmapAdditionalData();
                        existingLmapsAdditional[currentID] = emptyEntry;
                    }
                }
                //if (currentID == 0) rebuild = true;
            }
        }

        /*
        // If the first lightmap was unloaded, we need to rebuild the lightmap array
        // because Unity uses 1st lightmap to determine encoding
        if (rebuild)
        {
            int newLength = 0;
            for(int i=0; i<existingLmaps.Length; i++)
            {
                if (existingLmaps[i].lightmapColor != null) newLength++;
            }
            var existingLmaps2 = new LightmapData[newLength];
            int ctr = 0;
            for(int i=0; i<existingLmaps.Length; i++)
            {
                if (existingLmaps[i].lightmapColor != null)
                {
                    existingLmaps2[ctr] = existingLmaps[i];
                    ctr++;
                }
            }
            existingLmaps = existingLmaps2;

            for(int i=0; i<)
        }
        */

        if (existingLmaps != null) LightmapSettings.lightmaps = existingLmaps;
    }

    public static void RefreshScene2(Scene scene, ftLightmapsStorage storage)
    {
        Renderer r;
        int id;
        for(int i=0; i<storage.bakedRenderers.Count; i++)
        {
            r = storage.bakedRenderers[i];
            if (r == null) continue;

            id = storage.bakedIDs[i];
            r.lightmapIndex = (id < 0 || id >= storage.idremap.Length) ? id : storage.idremap[id];
        }

#if USE_TERRAINS
        Terrain r2;
        for(int i=0; i<storage.bakedRenderersTerrain.Count; i++)
        {
            r2 = storage.bakedRenderersTerrain[i];
            if (r2 == null) continue;

            id = storage.bakedIDsTerrain[i];
            r2.lightmapIndex = (id < 0 || id >= storage.idremap.Length) ? id : storage.idremap[id];
        }
#endif

        if (storage.anyVolumes)
        {
            if (storage.compressedVolumes)
            {
                Shader.EnableKeyword("BAKERY_COMPRESSED_VOLUME");
            }
            else
            {
                Shader.DisableKeyword("BAKERY_COMPRESSED_VOLUME");
            }
        }
    }
}
