using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

using System;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
[DisallowMultipleComponent]
public class BakeryPointLight : MonoBehaviour
{
    public enum ftLightProjectionMode
    {
        Omni = 0,
        Cookie = 1,
        Cubemap = 2,
        IES = 3,
        Cone = 4
    };

    public enum Direction
    {
        NegativeY = 0,
        PositiveZ = 1
    };

    public int UID;
    public Color color = Color.white;
    public float intensity = 1.0f;
    public float shadowSpread = 0.05f;
    public float cutoff = 10.0f;
    public bool realisticFalloff = false;
    public bool legacySampling = true;
    public int samples = 8;
    public ftLightProjectionMode projMode;
    public Texture2D cookie;
    public float angle = 30.0f;
    public float innerAngle = 0;
    public Cubemap cubemap;
    public UnityEngine.Object iesFile;
    public int bitmask = 1;
    public bool bakeToIndirect = false;
    public bool shadowmask = false;
    public bool shadowmaskFalloff = false;
    public float indirectIntensity = 1.0f;
    public float falloffMinRadius = 1.0f;
    public int shadowmaskGroupID = 0;
    public Direction directionMode = Direction.NegativeY;
    public int maskChannel;

    const float GIZMO_MAXSIZE = 0.1f;
    const float GIZMO_SCALE = 0.01f;
    float screenRadius = GIZMO_MAXSIZE;

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
            gameObject.GetComponent<BakerySkyLight>() != null ||
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
        Gizmos.color = color;
        var curCam = Camera.current;
        if (curCam != null)
        {
            screenRadius = Mathf.Min((transform.position - curCam.transform.position).magnitude * GIZMO_SCALE, GIZMO_MAXSIZE);
        }
        Gizmos.DrawSphere(transform.position, screenRadius);
    }

    void DrawArrow(Vector3 a, Vector3 b)
    {
        //const float len = 0.125f;

        b = a + b * (shadowSpread + 0.05f);
        Gizmos.DrawLine(a, b);
    }

    void OnDrawGizmosSelected()
    {
      Gizmos.color = color;//Color.yellow;
      Gizmos.DrawWireSphere(transform.position, shadowSpread);

      Gizmos.color = new Color(color.r, color.g, color.b, 0.25f);//Color.gray;
      if (projMode != ftLightProjectionMode.Cookie && projMode != ftLightProjectionMode.Cone) Gizmos.DrawWireSphere(transform.position, cutoff);

      if (projMode != 0)
      {
          Gizmos.color = color;//Color.yellow;
          Vector3 endPoint;
          if (projMode == ftLightProjectionMode.Cookie || projMode == ftLightProjectionMode.Cone)
          {
            endPoint = transform.forward * 2;
            Gizmos.DrawRay(transform.position, endPoint);

            float angle2 = (180 - angle) * Mathf.Deg2Rad * 0.5f;
            //float x = Mathf.Cos(angle2);
            //float radius = x * cutoff;

            float x = 1 / Mathf.Sin(angle2);
            x = Mathf.Sqrt(x * x - 1);
            float radius = x * cutoff;

            const int segments = 16;
            for(int i=0; i<segments; i++)
            {
                float p1 = i / (float)segments;
                float p2 = (i+1) / (float)segments;

                float x1 = Mathf.Cos(p1 * Mathf.PI*2);
                float y1 = Mathf.Sin(p1 * Mathf.PI*2);

                float x2 = Mathf.Cos(p2 * Mathf.PI*2);
                float y2 = Mathf.Sin(p2 * Mathf.PI*2);

                Vector3 A = transform.position + transform.forward * cutoff + transform.right * x1 * radius + transform.up * y1 * radius;
                Vector3 B = transform.position + transform.forward * cutoff + transform.right * x2 * radius + transform.up * y2 * radius;
                Gizmos.DrawLine(A, B);

                if (i % 4 == 0) Gizmos.DrawLine(transform.position, A);
            }
          }
          else
          {
            if (projMode == ftLightProjectionMode.IES && directionMode == Direction.PositiveZ)
            {
                endPoint = transform.forward * 2;
            }
            else
            {
                endPoint = -transform.up * 2;
            }
            Gizmos.DrawRay(transform.position, endPoint);
          }
          endPoint += transform.position;
          Gizmos.DrawLine(endPoint, endPoint + (transform.position + transform.right - endPoint).normalized * 0.5f);
          Gizmos.DrawLine(endPoint, endPoint + (transform.position - transform.right - endPoint).normalized * 0.5f);
          Gizmos.DrawLine(endPoint, endPoint + (transform.position + transform.up - endPoint).normalized * 0.5f);
          Gizmos.DrawLine(endPoint, endPoint + (transform.position - transform.up - endPoint).normalized * 0.5f);
      }
    }
#endif
}



