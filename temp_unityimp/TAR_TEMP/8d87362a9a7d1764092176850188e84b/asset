using UnityEngine;
using UnityEditor;
using UnityEngine.SceneManagement;
using System.Collections;
using System.Collections.Generic;
using System.IO;

public class ftClearCache
{
    static void Clear(string[] files)
    {
        for(int i=0; i<files.Length; i++) File.Delete(files[i]);
    }

    [MenuItem("Bakery/Utilities/Clear cache", false, 51)]
    private static void ClearCache()
    {
        var list = new HashSet<string>();

        var defaultPath = System.Environment.GetEnvironmentVariable("TEMP", System.EnvironmentVariableTarget.Process) + "\\frender";

        var sceneCount = SceneManager.sceneCount;
        for(int i=0; i<sceneCount; i++)
        {
            var scene = SceneManager.GetSceneAt(i);
            if (!scene.isLoaded) continue;
            var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
            if (go == null) continue;
            var storage = go.GetComponent<ftLightmapsStorage>();
            if (storage == null) continue;

            list.Add(storage.renderSettingsTempPath == "" ? defaultPath : storage.renderSettingsTempPath);
        }

        foreach(var tempPath in list)
        {
            if (EditorUtility.DisplayDialog("Bakery", "Clear cache from '" + tempPath + "'?", "OK", "Cancel"))
            {
                var files = Directory.GetFiles(tempPath, "*.lz4");
                Clear(files);

                files = Directory.GetFiles(tempPath, "*.dds");
                Clear(files);

                files = Directory.GetFiles(tempPath, "*.bin");
                Clear(files);

                files = Directory.GetFiles(tempPath, "lastscene.txt");
                Clear(files);
            }
        }

        Debug.Log("Done");
    }
}

