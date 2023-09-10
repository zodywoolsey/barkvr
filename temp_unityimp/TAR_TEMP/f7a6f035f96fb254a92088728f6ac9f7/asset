using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VolumeTestScene2 : MonoBehaviour
{
    public Transform secondFloor;
    public BakeryVolumeTrigger[] secondFloorVolumes;
    public float secondFloorHeight;
    public bool randomizeLastRoom;
    public Transform baseRoom;
    public Transform alternativeRoom;

    void SwapRooms()
    {
        var tmp = alternativeRoom.position;
        alternativeRoom.position = baseRoom.position;
        baseRoom.position = tmp;
    }

    void UpdateRooms()
    {
        for(int i=0; i<secondFloorVolumes.Length; i++)
        {
            secondFloorVolumes[i].UpdateBounds();
        }
    }

    void Start()
    {
        if (randomizeLastRoom)
        {
            if (Random.Range(0,2) == 1)
            {
                SwapRooms();
            }
        }

        secondFloor.position += Vector3.up * secondFloorHeight;

        UpdateRooms();
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            SwapRooms();
            UpdateRooms();
        }
    }
}
