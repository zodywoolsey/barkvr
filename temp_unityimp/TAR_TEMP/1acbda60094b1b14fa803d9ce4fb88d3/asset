using UnityEngine;
using UnityEditor;
using UnityEngine.SceneManagement;

public class ftRestorePaddingMenu
{
    [MenuItem("Bakery/Utilities/Re-adjust UV padding", false, 43)]
    private static void RestorePadding()
    {
        var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
        var gstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;

        if (gstorage == null)
        {
            Debug.Log("Bakery is not initalized");
            return;
        }

        if (EditorUtility.DisplayDialog("Bakery", "Re-unwrap and reimport lightmapped scene models to match last bake?", "OK", "Cancel"))
        {
            var sceneCount = SceneManager.sceneCount;
            int reimported = 0;
            for(int i=0; i<sceneCount; i++)
            {
                var scene = SceneManager.GetSceneAt(i);
                if (!scene.isLoaded) continue;
                var go = ftLightmaps.FindInScene("!ftraceLightmaps", scene);
                if (go == null) continue;
                var store = go.GetComponent<ftLightmapsStorage>();
                if (store == null) continue;

                for(int j=0; j<store.modifiedAssetPathList.Count; j++)
                {
                    bool updated = false;
                    var path = store.modifiedAssetPathList[j];
                    var data = store.modifiedAssets[j];
                    int mstoreIndex = gstorage.modifiedAssetPathList.IndexOf(path);
                    if (mstoreIndex < 0)
                    {
                        mstoreIndex = gstorage.modifiedAssetPathList.Count;
                        gstorage.modifiedAssetPathList.Add(path);
                        gstorage.modifiedAssets.Add(data);
                        updated = true;
                    }
                    else
                    {
                        var dataExisting = gstorage.modifiedAssets[mstoreIndex];
                        for(int k=0; k<data.meshName.Count; k++)
                        {
                            int ind = dataExisting.meshName.IndexOf( data.meshName[k] );
                            if (ind >= 0)
                            {
                                if (dataExisting.padding[ind] != data.padding[k])
                                {
                                    dataExisting.padding[ind] = data.padding[k];
                                    updated = true;
                                }
                                if (dataExisting.unwrapper[ind] != data.unwrapper[k])
                                {
                                    dataExisting.unwrapper[ind] = data.unwrapper[k];
                                    updated = true;
                                }
                            }
                            else
                            {
                                dataExisting.meshName.Add( data.meshName[k] );
                                dataExisting.padding.Add( data.padding[k] );
                                dataExisting.unwrapper.Add( data.unwrapper[k] );
                                updated = true;
                            }
                        }
                    }
                    if (updated)
                    {
#if UNITY_2017_1_OR_NEWER
                        gstorage.SyncModifiedAsset(mstoreIndex);
#endif
                        EditorUtility.SetDirty(gstorage);
                        (AssetImporter.GetAtPath(path) as ModelImporter).SaveAndReimport();
                        reimported++;
                    }
                }
            }
            Debug.Log(reimported > 0 ? ("Updated " + reimported + " models") : "No changes detected");
        }
    }
}

