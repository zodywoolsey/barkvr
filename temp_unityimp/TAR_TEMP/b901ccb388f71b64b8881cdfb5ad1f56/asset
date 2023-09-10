using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using VRC.Udon.Common;

namespace VRCMarker
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class EraseUndo : UdonSharpBehaviour
    {
        public MarkerTrail markerTrail;
        private float _updateRate = 1f;
        private float _updateRateCached = 1f;
        private float _time = 0;

        public EraseHandler erase;

        public const int MaxEraseCount = 500; // prevent lag if all sent at once

        private int _undoCount = 0;

        private void Start()
        {
            _updateRate = markerTrail.updateRate;
            _updateRateCached = _updateRate;
            enabled = false;
        }

        public void StopErasingAndSync()
        {
            enabled = false;

            if (_undoCount == 0)
            {
                return;
            }

            erase.undoCountSync = _undoCount;
            _undoCount = 0;
            erase.RequestSerialization();
        }

        public void StopErasing()
        {
            _undoCount = 0;
            enabled = false;
        }


        private void OnEnable()
        {
            if (!markerTrail.MarkerInitialized())
            {
                enabled = false;
            }

            _time = 0;
            _updateRate = EraseHandler.HoldDelay;
        }


        private void Update()
        {
            _time += Time.deltaTime;

            if (_time <= _updateRate || !markerTrail.MarkerInitialized())
            {
                return;
            }

            _updateRate = _updateRateCached;

            bool erased = markerTrail.UndoLastLines();
            if (erased) _undoCount++;

            if (markerTrail.IsLastPositionEndOfLine() || _undoCount >= MaxEraseCount)
            {
                erased = markerTrail.UndoLastLines();
                if (erased) _undoCount++;
                StopErasingAndSync();
            }

            markerTrail.UpdateMeshData();

            _time = 0;
        }
    }
}
