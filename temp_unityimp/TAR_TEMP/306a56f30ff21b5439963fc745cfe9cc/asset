using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

using System;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
[DisallowMultipleComponent]
public class BakerySkyLight : MonoBehaviour
{
    public string texName = "sky.dds";
    public Color color = Color.white;
    public float intensity = 1.0f;
    public int samples = 32;
    public bool hemispherical = false;
    public int bitmask = 1;
    public bool bakeToIndirect = true;
    public float indirectIntensity = 1.0f;
    public bool tangentSH = false;
    public bool correctRotation = false;

    public Cubemap cubemap;

    public int UID;

    public static int lightsChanged = 0; // 1 = const, 2 = full

    static GameObject objShownError;

#if UNITY_EDITOR
    void OnValidate()
    {
        if (lightsChanged == 0) lightsChanged = 1;
    }
    void OnEnable()
    {
        lightsChanged = 2;
    }
    void OnDisable()
    {
        lightsChanged = 2;
    }

    public void Start()
    {
        if (gameObject.GetComponent<BakeryDirectLight>() != null ||
            gameObject.GetComponent<BakeryPointLight>() != null ||
            gameObject.GetComponent<BakeryLightMesh>() != null)
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

    void OnDrawGizmos()
    {
      Gizmos.color = new Color(49/255.0f, 91/255.0f, 191/255.0f);
      Gizmos.DrawSphere(transform.position, 0.1f);
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = new Color(49/255.0f, 91/255.0f, 191/255.0f);
        Vector3 origin = transform.position;
        const int segments = 16;
        for(int i=0; i<segments; i++)
        {
            float p1 = i / (float)segments;
            float p2 = (i+1) / (float)segments;

            float x1 = Mathf.Cos(p1 * Mathf.PI*2);
            float y1 = Mathf.Sin(p1 * Mathf.PI*2);

            float x2 = Mathf.Cos(p2 * Mathf.PI*2);
            float y2 = Mathf.Sin(p2 * Mathf.PI*2);

            Gizmos.DrawLine(origin + new Vector3(x1,0,y1), origin + new Vector3(x2,0,y2));

            if (hemispherical)
            {
                x1 = Mathf.Cos(p1 * Mathf.PI);
                y1 = Mathf.Sin(p1 * Mathf.PI);

                x2 = Mathf.Cos(p2 * Mathf.PI);
                y2 = Mathf.Sin(p2 * Mathf.PI);
            }

            Gizmos.DrawLine(origin + new Vector3(x1,y1,0), origin + new Vector3(x2,y2,0));
            Gizmos.DrawLine(origin + new Vector3(0,y1,x1), origin + new Vector3(0,y2,x2));
        }
    }

#endif
}

