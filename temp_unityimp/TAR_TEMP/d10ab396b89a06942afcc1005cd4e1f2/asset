using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BakerySector : MonoBehaviour
{
    public enum CaptureMode
    {
        None = -1,
        CaptureInPlace = 0,
        CaptureToAsset = 1,
        LoadCaptured = 2
    }

    public CaptureMode captureMode = CaptureMode.CaptureInPlace;
    public string captureAssetName = "";
    public BakerySectorCapture captureAsset;
    public bool allowUVPaddingAdjustment = false;
    public List<Transform> tforms = new List<Transform>();
    public List<Transform> cpoints = new List<Transform>();

#if UNITY_EDITOR
    public List<Renderer> previewDisabledRenderers;
    public List<GameObject> previewTempObjects;
    public bool previewEnabled = false;
#endif

    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.green;
        for(int i=0; i<cpoints.Count; i++)
        {
            if (cpoints[i] != null) Gizmos.DrawWireSphere(cpoints[i].position, 1.0f);
        }
    }
}
