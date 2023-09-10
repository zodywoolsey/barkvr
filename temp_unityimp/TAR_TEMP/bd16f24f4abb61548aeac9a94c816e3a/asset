#if UNITY_EDITOR

// Disable 'obsolete' warnings
#pragma warning disable 0618

using UnityEngine;
using UnityEditor;
using System.Collections;

// For reasons unknown Unity will reset all shader variables set by Shader.SetGlobal... if you save a scene
// So here is a hack to fix it
public class ftFixResettingsGlobalsOnSave : SaveAssetsProcessor
{
    static void ProcUpdate()
    {
        if (BakeryVolume.globalVolume != null) BakeryVolume.globalVolume.OnEnable(); // set global volume again
        EditorApplication.update -= ProcUpdate; // remove the callback
    }

    static string[] OnWillSaveAssets(string[] paths)
    {
        // Only do anything if there is a global volume in the scene
        if (BakeryVolume.globalVolume != null)
        {
            EditorApplication.update += ProcUpdate; // wait for the next editor update
        }
        return paths;
    }
}

#endif

