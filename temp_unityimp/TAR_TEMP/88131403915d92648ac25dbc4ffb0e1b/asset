using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Example volume switching script
//
// The high-level logic is following:
//
// - Volumes overlap each other a bit, so we don't need blending! The size of the overlap is the size of your largest dynamic object.
// - As object enters the volume, set volume data to it. Increment the counter.
// - As object leaves the volume, decrement the counter. If it equals 0, use global volume (set empty property block).
// - If the volume is moving, set volume data every frame, in LateUpdate.
//
public class BakeryVolumeTrigger : MonoBehaviour
{
    public bool movable;

    BakeryVolume vol;
    MaterialPropertyBlock mb; // current volume shader properties

    static MaterialPropertyBlock mbEmpty; // default empty block, no values (will revert to global volume)
    static int mVolumeMin, mVolumeInvSize; // shader property IDs

    void Awake()
    {
        if (mbEmpty == null) mbEmpty = new MaterialPropertyBlock();

        // Create a MaterialPropertyBlock with Volume parameters for future use
        vol = GetComponent<BakeryVolume>();
        mb = new MaterialPropertyBlock();
        if (vol.bakedTexture0 != null)
        {
            mb.SetTexture("_Volume0", vol.bakedTexture0);
            mb.SetTexture("_Volume1", vol.bakedTexture1);
            mb.SetTexture("_Volume2", vol.bakedTexture2);
            if (vol.bakedTexture3 != null) mb.SetTexture("_Volume3", vol.bakedTexture3);
        }
        if (vol.bakedMask != null) mb.SetTexture("_VolumeMask", vol.bakedMask);
        if (mVolumeMin == 0) mVolumeMin = Shader.PropertyToID("_VolumeMin");
        if (mVolumeInvSize == 0) mVolumeInvSize = Shader.PropertyToID("_VolumeInvSize");
        mb.SetVector(mVolumeMin, vol.GetMin());
        mb.SetVector(mVolumeInvSize, vol.GetInvSize());
        if (vol.supportRotationAfterBake) mb.SetMatrix("_VolumeMatrix", vol.GetMatrix());
    }

    // Apply MaterialPropertyBlock to renderers entering the trigger
    void OnTriggerEnter(Collider c)
    {
        var rcv = c.GetComponent<BakeryVolumeReceiver>();
        if (rcv == null) return;

        Debug.Log(c.name + " entered " + this.name);

        rcv.enterCounter++;
        rcv.movableTrigger = movable ? this : null;
        rcv.SetPropertyBlock(mb);
    }

    // Handle exiting the trigger
    void OnTriggerExit(Collider c)
    {
        var rcv = c.GetComponent<BakeryVolumeReceiver>();
        if (rcv == null) return;

        Debug.Log(c.name + " exited " + this.name);

        // Only set empty property block, if the counter is 0 (= exited ALL volumes)
        rcv.enterCounter--;
        if (rcv.enterCounter == 0) rcv.SetPropertyBlock(mbEmpty);
    }

    public void UpdateBounds()
    {
        vol.UpdateBounds();
        mb.SetVector(mVolumeMin, vol.GetMin());
        mb.SetVector(mVolumeInvSize, vol.GetInvSize());
    }
}
