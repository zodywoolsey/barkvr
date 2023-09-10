using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

using System;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
[DisallowMultipleComponent]
public class BakeryLightMesh : MonoBehaviour
{
    public int UID;

    public Color color = Color.white;
    public float intensity = 1.0f;
    public Texture2D texture = null;
    public float cutoff = 100;
    public int samples = 256;
    public int samples2 = 16;
    public int bitmask = 1;
    public bool selfShadow = true;
    public bool bakeToIndirect = true;
    public bool shadowmask = false;
    public float indirectIntensity = 1.0f;
    public bool shadowmaskFalloff = false;

    public int lmid = -2;

    public static int lightsChanged = 0;

    static GameObject objShownError;

#if UNITY_EDITOR
    void OnValidate()
    {
        if (lightsChanged == 0) lightsChanged = 1;
    }

    public void Start()
    {
        if (gameObject.GetComponent<BakeryDirectLight>() != null ||
            gameObject.GetComponent<BakeryPointLight>() != null ||
            gameObject.GetComponent<BakerySkyLight>() != null)
        {
            if (objShownError != gameObject)
            {
                EditorUtility.DisplayDialog("Bakery", "Can't have more than one Bakery light on one object", "OK");
                objShownError = gameObject;
            }
            else
            {
                Debug.LogError("Can't have more than one Bakery light on one object");
            }
            DestroyImmediate(this);
            return;
        }

        if (EditorApplication.isPlayingOrWillChangePlaymode) return;

        if (UID == 0) UID = Guid.NewGuid().GetHashCode(); // legacy
    }

#endif

	void OnDrawGizmosSelected()
	{
		Gizmos.color = Color.yellow;
        var mr = gameObject.GetComponent<MeshRenderer>();
        if (mr!=null) Gizmos.DrawWireSphere(mr.bounds.center, cutoff);
	}
}



