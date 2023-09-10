using UnityEngine;
using UnityEditor;
using UnityEngine.SceneManagement;
using System.Collections;
using System.Collections.Generic;

public class ftClearMenu : EditorWindow
{
    public enum SceneClearingMode
    {
        nothing = 0,
        lightmapReferences = 1,
        lightmapReferencesAndBakeSettings = 2
    }

    static public string[] options = new string[] {"Nothing", "Baked data references", "All (data and bake settings)"};

    public SceneClearingMode sceneClearingMode = SceneClearingMode.lightmapReferences;
    public bool clearLightmapFiles = false;

    [MenuItem("Bakery/Utilities/Clear baked data", false, 44)]
    private static void ClearBakedDataShow()
    {
        var instance = (ftClearMenu)GetWindow(typeof(ftClearMenu));
        instance.titleContent.text = "Clear menu";
        instance.minSize = new Vector2(320, 90);
        instance.maxSize = new Vector2(instance.minSize.x, instance.minSize.y + 1);
        instance.Show();
    }

    void OnGUI()
    {
        sceneClearingMode = (SceneClearingMode)EditorGUILayout.Popup("Clear from scenes", (int)sceneClearingMode, options);
        clearLightmapFiles = EditorGUILayout.Toggle("Delete lightmap files", clearLightmapFiles);

        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorGUILayout.Space();

        if (GUILayout.Button("Clear"))
        {
            string txt = "";
            if (sceneClearingMode == SceneClearingMode.nothing)
            {
                if (clearLightmapFiles)
                {
                    txt += "Delete currently used lightmap files";
                }
                else
                {
                    return;
                }
            }
            else
            {
                if (sceneClearingMode == SceneClearingMode.lightmapReferences)
                {
                    txt = "Clear all Bakery data for currently loaded scenes";
                }
                else
                {
                    txt = "Clear all Bakery data and settings for currently loaded scenes";
                }
                if (clearLightmapFiles) txt += " and delete currently used lightmap files";
            }

            if (EditorUtility.DisplayDialog("Bakery", txt + "?", "Yes", "No"))
            {
                ClearBakedData(sceneClearingMode, clearLightmapFiles);
            }
        }
    }

    static void RemoveFiles(Texture2D map)
    {
        var path = AssetDatabase.GetAssetPath(map);
        AssetDatabase.DeleteAsset(path);
        ftRenderLightmap.DebugLogInfo("Deleted " + path);
    }

    static void RemoveFiles(List<Texture2D> maps)
    {
        for(int i=0; i<maps.Count; i++)
        {
            RemoveFiles(maps[i]);
        }
    }

    public static void ClearBakedData(SceneClearingMode sceneClearMode, bool removeLightmapFiles)
    {
        if (removeLightmapFiles)
        {
            var sceneCount = SceneManager.sceneCount;
            for(int i=0; i<sceneCount; i++)
            {
                var scene = SceneManager.GetSceneAt(i);
                if (!scene.isLoaded) continue;
                var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
                if (go == null) continue;
                var storage = go.GetComponent<ftLightmapsStorage>();
                if (storage == null) continue;

                RemoveFiles(storage.maps);
                RemoveFiles(storage.masks);
                RemoveFiles(storage.dirMaps);
                RemoveFiles(storage.rnmMaps0);
                RemoveFiles(storage.rnmMaps1);
                RemoveFiles(storage.rnmMaps2);
            }
        }

        if (sceneClearMode == SceneClearingMode.lightmapReferences)
        {
            var newStorages = new List<GameObject>();
            var sceneCount = SceneManager.sceneCount;
            for(int i=0; i<sceneCount; i++)
            {
                var scene = SceneManager.GetSceneAt(i);
                if (!scene.isLoaded) continue;
                var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
                if (go == null) continue;
                var storage = go.GetComponent<ftLightmapsStorage>();
                if (storage != null)
                {
                    var newGO = new GameObject();
                    var newStorage = newGO.AddComponent<ftLightmapsStorage>();
                    ftLightmapsStorage.CopySettings(storage, newStorage);
                    newStorages.Add(newGO);
                }
                Undo.DestroyObjectImmediate(go);
            }
            LightmapSettings.lightmaps = new LightmapData[0];
            for(int i=0; i<newStorages.Count; i++)
            {
                newStorages[i].name = "!ftraceLightmaps";
            }
        }
        else if (sceneClearMode == SceneClearingMode.lightmapReferencesAndBakeSettings)
        {
            var sceneCount = SceneManager.sceneCount;
            for(int i=0; i<sceneCount; i++)
            {
                var scene = SceneManager.GetSceneAt(i);
                if (!scene.isLoaded) continue;
                var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
                if (go == null) continue;
                Undo.DestroyObjectImmediate(go);
            }
            LightmapSettings.lightmaps = new LightmapData[0];
        }

#if UNITY_2017_3_OR_NEWER
        var lights = FindObjectsOfType<Light>() as Light[];
        for(int i=0; i<lights.Length; i++)
        {
            var output = lights[i].bakingOutput;
            output.isBaked = false;
            lights[i].bakingOutput = output;
        }
#endif
    }
}

