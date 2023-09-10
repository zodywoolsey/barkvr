using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using VRC.Udon.Common;

namespace VRCMarker
{

    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class EraseHandler : UdonSharpBehaviour
    {
        public MarkerTrail markerTrail;
        public VRC_Pickup markerPickup;

        public EraseUndo eraseUndo;

        public const float HoldDelay = 0.2f;
        private float _heldTime = 0;
        private float _lastTime = 0;

        private bool _interactDown = false;

        private bool _isHeldDown = false;

        public override void Interact()
        {
            if (markerPickup.IsHeld && !Networking.IsOwner(Networking.LocalPlayer, markerPickup.gameObject))
            {
                return;
            }

            eraseUndo.enabled = true;
            _lastTime = Time.time;
            _interactDown = true;
        }

        public override void InputUse(bool value, UdonInputEventArgs args)
        {
            if (_interactDown && !value)
            {
                OnInteractUp();
                _interactDown = false;
            }
        }

        private void OnInteractUp()
        {
            _heldTime = Time.time - _lastTime;

            if (_heldTime < HoldDelay)
            {
                eraseUndo.StopErasing();
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, nameof(ClearTrail));
            }
            else
            {
                eraseUndo.StopErasingAndSync();
            }
        }

        public void ClearTrail()
        {
            markerTrail.Clear();
        }

        [UdonSynced] public int undoCountSync = 0;
        public override void OnDeserialization()
        {
            if (undoCountSync > EraseUndo.MaxEraseCount + 1)
            {
                return;
            }

            for (int i = 0; i < undoCountSync; i++)
            {
                markerTrail.UndoLastLines();
            }

            markerTrail.UpdateMeshData();
        }

    }
}
