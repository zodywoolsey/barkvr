#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

// Disable 'obsolete' warnings
#pragma warning disable 0618

[DisallowMultipleComponent]
public class BakeryLightmappedPrefab : MonoBehaviour
{
#if UNITY_EDITOR
    public bool enableBaking = true;
    public bool ignoreWarnings = false;
    public string errorMessage;

    public bool IsValid()
    {
        errorMessage = "";

        if (!enableBaking)
        {
            return false;
        }

        if (ignoreWarnings) return true;

        bool isPartOfPrefab = PrefabUtility.GetPrefabType(gameObject) == PrefabType.PrefabInstance;
        if (!isPartOfPrefab)
        {
            errorMessage = "this GameObject is not a prefab";
            return false;
        }

        bool prefabIsRoot = PrefabUtility.FindPrefabRoot(gameObject) == gameObject;
        if (!prefabIsRoot)
        {
            errorMessage = "this GameObject is not a root prefab object";
            return false;
        }

        var transforms = GetComponentsInChildren<Transform>();
        for(int i=0; i<transforms.Length; i++)
        {
            if (PrefabUtility.FindPrefabRoot(transforms[i].gameObject) != gameObject)
            {
                errorMessage = "prefab contains unapplied object (" + transforms[i].name + ")";
                return false;
            }
        }

        var prefabRootObj = PrefabUtility.GetPrefabObject(gameObject);
        //var prefabRootObj2 = PrefabUtility.FindPrefabRoot(gameObject);

        var mods = PrefabUtility.GetPropertyModifications(gameObject);
        if (mods != null)
        {
            for(int i=0; i<mods.Length; i++)
            {
                if (mods[i] == null) continue;
#if UNITY_2018_3_OR_NEWER
                if (PrefabUtility.IsDefaultOverride(mods[i])) continue;
#endif
                if (mods[i].propertyPath == "m_RootOrder") continue;
                if (mods[i].propertyPath == "errorMessage") continue;
                if (mods[i].propertyPath == "enableBaking") continue;
                if (mods[i].propertyPath.IndexOf("idremap") >= 0) continue;
                if (mods[i].target != null && mods[i].target.name == gameObject.name)
                {
                    if (mods[i].propertyPath.Contains("m_LocalPosition")) continue;
                    if (mods[i].propertyPath.Contains("m_LocalRotation")) continue;
                    if (mods[i].propertyPath.Contains("m_LocalScale")) continue;
                }

                errorMessage = "prefab contains unapplied data (" + mods[i].target+"."+mods[i].propertyPath + ")";
                return false;
            }
        }

        var comps = gameObject.GetComponents<Component>();
        var comps2 = gameObject.GetComponentsInChildren<Component>();

        for(int t=0; t<2; t++)
        {
            var comps3 = t == 0 ? comps : comps2;
            for(int c=0; c<comps3.Length; c++)
            {
                var prefabObj = PrefabUtility.GetPrefabObject(comps3[c]);
                if (prefabObj != prefabRootObj)
                {
                    errorMessage = "prefab contains unapplied component (" + comps3[c] + ")";
                    return false;
                }

                /*bool isRoot = comps3[c].gameObject == gameObject;

                var mods = PrefabUtility.GetPropertyModifications(comps3[c]);
                if (mods == null) continue;
                for(int i=0; i<mods.Length; i++)
                {
                    if (mods[i].propertyPath == "m_RootOrder") continue;
                    if (isRoot)
                    {
                        if (mods[i].propertyPath == "errorMessage") continue;
                        if (mods[i].propertyPath == "enableBaking") continue;
                        if (mods[i].propertyPath.Contains("m_LocalPosition")) continue;
                        if (mods[i].propertyPath.Contains("m_LocalRotation")) continue;
                        if (mods[i].propertyPath.Contains("m_LocalScale")) continue;
                    }
                    else
                    {
                        if (mods[i].propertyPath.Contains("m_LocalPosition"))
                        {
                            var dist = (comps3[c].transform.position - (PrefabUtility.GetPrefabParent(comps3[c].gameObject) as GameObject).transform.position).sqrMagnitude;
                            Debug.LogError(dist);
                            if (dist < 0.001f) continue;
                        }
                        else if (mods[i].propertyPath.Contains("m_LocalRotation"))
                        {
                            continue;
                        }
                    }
                    errorMessage = "Error: prefab contains unapplied data (" + mods[i].target+"."+mods[i].propertyPath + ")";
                    return false;
                }*/
            }
        }

        return true;
    }
#endif
}

