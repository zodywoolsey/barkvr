using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

using System;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
[DisallowMultipleComponent]
public class BakeryDirectLight : MonoBehaviour
{
    public Color color = Color.white;
    public float intensity = 1.0f;
    public float shadowSpread = 0.01f;//0.05f;
    public int samples = 16;
    //public uint bitmask = 1;
    public int bitmask = 1;
    public bool bakeToIndirect = false;
    public bool shadowmask = false;
    public bool shadowmaskDenoise = false;
    public float indirectIntensity = 1.0f;
    public Texture2D cloudShadow;
    public float cloudShadowTilingX = 0.01f;
    public float cloudShadowTilingY = 0.01f;
    public float cloudShadowOffsetX, cloudShadowOffsetY;
    public bool supersample = false;

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
        if (gameObject.GetComponent<BakerySkyLight>() != null ||
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
      Gizmos.color = Color.yellow;
      Gizmos.DrawSphere(transform.position, 0.1f);

      //Gizmos.DrawWireSphere(transform.position, 0.5f);
    }

    void OnDrawGizmosSelected()
    {
      Gizmos.color = Color.yellow;
      var endPoint = transform.position + transform.forward * 2;
      Gizmos.DrawLine(transform.position, endPoint);

      //Gizmos.color = Color.blue;
      Gizmos.DrawWireSphere(transform.position, 0.2f);

      Gizmos.DrawLine(endPoint, endPoint + (transform.position + transform.right - endPoint).normalized * 0.5f);
      Gizmos.DrawLine(endPoint, endPoint + (transform.position - transform.right - endPoint).normalized * 0.5f);
      Gizmos.DrawLine(endPoint, endPoint + (transform.position + transform.up - endPoint).normalized * 0.5f);
      Gizmos.DrawLine(endPoint, endPoint + (transform.position - transform.up - endPoint).normalized * 0.5f);
    }

#endif
}

