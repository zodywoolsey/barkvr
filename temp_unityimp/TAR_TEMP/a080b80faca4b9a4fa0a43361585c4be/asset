using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(BakeryLightmappedPrefab))]
[CanEditMultipleObjects]
public class ftLightmappedPrefabInspector : UnityEditor.Editor
{
    bool allPrefabsGood = true;
    SerializedProperty isEnabled;
    SerializedProperty ignoreWarnings;

    void Refresh(BakeryLightmappedPrefab selected)
    {
        allPrefabsGood = selected.IsValid() && allPrefabsGood;
    }

    void OnPrefabInstanceUpdate(GameObject go)
    {
        allPrefabsGood = true;
        foreach(BakeryLightmappedPrefab selected in targets)
        {
            //if (go != selected.gameObject) continue;
            Refresh(selected);
        }
    }

    void OnEnable()
    {
        allPrefabsGood = true;
        foreach(BakeryLightmappedPrefab selected in targets)
        {
            Refresh(selected);
        }
        PrefabUtility.prefabInstanceUpdated += OnPrefabInstanceUpdate;
        isEnabled = serializedObject.FindProperty("enableBaking");
        ignoreWarnings = serializedObject.FindProperty("ignoreWarnings");
    }

    void OnDisable()
    {
        PrefabUtility.prefabInstanceUpdated -= OnPrefabInstanceUpdate;
    }

    public ftLightmapsStorage FindPrefabStorage(BakeryLightmappedPrefab pref)
    {
        var p = pref.gameObject;
        var bdataName = "BakeryPrefabLightmapData";
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
        return pstore;
    }

    public override void OnInspectorGUI() {

        serializedObject.Update();
        var prev = isEnabled.boolValue;
        EditorGUILayout.PropertyField(isEnabled, new GUIContent("Enable baking", "Prefab contents will be patched after baking if this checkbox is on. Patched prefab will be lightmapped when instantiated in any scene."));
        EditorGUILayout.PropertyField(ignoreWarnings, new GUIContent("Ignore warnings", "Still attempt to bake the prefab, even if it has unapplied properties."));
        serializedObject.ApplyModifiedProperties();

        if (isEnabled.boolValue != prev)
        {
            allPrefabsGood = true;
            foreach(BakeryLightmappedPrefab selected in targets)
            {
                selected.enableBaking = isEnabled.boolValue;
                Refresh(selected);
            }
        }

        if (allPrefabsGood)
        {
            EditorGUILayout.LabelField("Prefab connection: OK");
        }
        else
        {
            foreach(BakeryLightmappedPrefab selected in targets)
            {
                if (selected.errorMessage.Length > 0) EditorGUILayout.LabelField("Error: " + selected.errorMessage);
            }
        }

        if (GUILayout.Button("Load render settings from prefab"))
        {
            if (EditorUtility.DisplayDialog("Bakery", "Change current render settings to prefab?", "OK", "Cancel"))
            {
                var storage = ftRenderLightmap.FindRenderSettingsStorage();
                foreach(BakeryLightmappedPrefab pref in targets)
                {
                    var prefabStorage = FindPrefabStorage(pref);
                    ftLightmapsStorage.CopySettings(prefabStorage, storage);
                }
                var instance = (ftRenderLightmap)EditorWindow.GetWindow(typeof(ftRenderLightmap));
                if (instance != null) instance.LoadRenderSettings();
            }
        }

        if (GUILayout.Button("Save current render settings to prefab"))
        {
            if (EditorUtility.DisplayDialog("Bakery", "Save current render settings to prefab?", "OK", "Cancel"))
            {
                var storage = ftRenderLightmap.FindRenderSettingsStorage();
                foreach(BakeryLightmappedPrefab pref in targets)
                {
                    var prefabStorage = FindPrefabStorage(pref);
                    ftLightmapsStorage.CopySettings(storage, prefabStorage);
                    EditorUtility.SetDirty(prefabStorage);
                }
            }
        }
    }
}

