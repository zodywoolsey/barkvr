using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace VRCMarker
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class MarkerSync : UdonSharpBehaviour
    {
        public MarkerTrail markerTrail;

        [UdonSynced] public Vector3[] syncedLastTrailPoints = new Vector3[0];
        [UdonSynced] public int state = -1;

        public const int MaxSyncCount = 300;

        private void Start()
        {
            state = -1;
        }

        private readonly Vector3[] _vector3A0 = new Vector3[0];
        public override void OnDeserialization()
        {
            switch (state)
            {
                case 0: // start writing
                    if (markerTrail.enabled)
                    {
                        markerTrail.StopWriting();
                        markerTrail.AddEndCap();
                    }
                    markerTrail.StartWriting();
                    return;
                case 1: // stop writing without sync
                    markerTrail.StopWriting();
                    markerTrail.AddEndCap();
                    markerTrail.UpdateUsedVertices();
                    return;
                case 2: // stop writing with sync
                    markerTrail.StopWriting();
                    int length = syncedLastTrailPoints.Length;
                    if (length >= 2)
                    {
                        markerTrail.CreateTrail(syncedLastTrailPoints);
                    }
                    else if (length == 1)
                    {
                        markerTrail.RevertUsedVertices();
                        markerTrail.CreateTrailLine(syncedLastTrailPoints[0], syncedLastTrailPoints[0]);
                        markerTrail.UpdateUsedVertices();
                        markerTrail.UpdateMeshData();
                    }
                    return;
            }
        }

        public void SyncMarker()
        {
            var syncLines = markerTrail.GetSyncLines();

            if (!markerTrail.enabled && syncLines.Length < MaxSyncCount)
            {
                syncedLastTrailPoints = syncLines;
                state = 2;
            }
            else
            {
                syncedLastTrailPoints = _vector3A0;
            }
            if (syncLines.Length >= MaxSyncCount)
            {
                state = 1;
            }

            RequestSerialization();

            if (state != 0)
            {
                markerTrail.ResetSyncLines();
            }
        }

    }
}
