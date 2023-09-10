#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using UnityEngine.SceneManagement;
using System.IO;
using System.Collections.Generic;

public class ftSavePaddingMenu
{
    [MenuItem("Bakery/Utilities/Save UV padding to asset", false, 60)]
    private static void RestorePadding()
    {
        var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
        var gstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;

        if (gstorage == null)
        {
            Debug.Log("Bakery is not initalized");
            return;
        }

        var sel = Selection.objects;
        var pathList = new List<string>();

        for(int i=0; i<sel.Length; i++)
        {
            var path = AssetDatabase.GetAssetPath(sel[i]);
            if (path == "") continue;
            if (!pathList.Contains(path)) pathList.Add(path);
        }

        int ctr = 0;
        for(int i=0; i<pathList.Count; i++)
        {
            var index = gstorage.modifiedAssetPathList.IndexOf(pathList[i]);
            if (index < 0)
            {
                Debug.Log("UV padding wasn't generated yet, skipping " + pathList[i]);
                continue;
            }
            var mod = gstorage.modifiedAssets[index];
            var asset = ScriptableObject.CreateInstance<ftSavedPadding2>();
            asset.data = mod;
            AssetDatabase.CreateAsset(asset, Path.GetDirectoryName(pathList[i]) + "/" + Path.GetFileNameWithoutExtension(pathList[i]) + "_padding.asset");
            Debug.Log("Created padding asset for " + pathList[i]);
            ctr++;
        }

        AssetDatabase.SaveAssets();
        Debug.Log("Created " + ctr + " UV padding assets");
    }
}

#endif
