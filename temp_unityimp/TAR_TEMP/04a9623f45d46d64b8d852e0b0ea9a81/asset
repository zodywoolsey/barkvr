using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
#if UNITY_EDITOR

using UnityEngine.Rendering;
using System.Reflection;

public class ftLightingDataGen
{
    // Generates LightingDataAsset for all lights with baked occlusionMaskChannel
    public static bool GenerateShadowmaskLightingData(string outName, ref List<Light> lights, bool subtractive)
    {
        ftRenderLightmap.DebugLogInfo("Generating LightingDataAsset for " + lights.Count + " lights");

        bool success = true;
        try
        {
            PropertyInfo inspectorModeInfo = typeof(SerializedObject).GetProperty("inspectorMode", BindingFlags.NonPublic | BindingFlags.Instance);
            var edPath = ftLightmaps.GetEditorPath();
#if UNITY_2017_1_OR_NEWER
            var bytesP0 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_2017_1_part0.bin");
            var bytesP1 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_2017_1_part1.bin");
            var bytesP2 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_2017_1_part2.bin");
            var bytesP3 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_2017_1_part3.bin");
#else
            var bytesP0 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_5_6_part0.bin");
            var bytesP1 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_5_6_part1.bin");
            var bytesP2 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_5_6_part2.bin");
            var bytesP3 = File.ReadAllBytes(edPath + "lightingDataChunks/LightingData_5_6_part3.bin");
#endif
            var f = new BinaryWriter(File.Open(outName, FileMode.Create));
            f.Write(bytesP0);
#if UNITY_2017_1_OR_NEWER
            f.Write(52 + 28 * lights.Count - 28);
            f.Write(bytesP1);
            f.Write(572 + 28 * lights.Count - 28);
#else
            f.Write(160 + 28 * lights.Count - 28);
            f.Write(bytesP1);
            f.Write(552 + 28 * lights.Count - 28);
#endif
            f.Write(bytesP2);
            f.Write(lights.Count);
            for(int i=0; i<lights.Count; i++)
            {
                var so = new SerializedObject(lights[i]);
                inspectorModeInfo.SetValue(so, InspectorMode.Debug, null);
                long fileid = so.FindProperty("m_LocalIdentfierInFile").longValue;
                f.Write(fileid);
                f.Write(0);
                f.Write(0);
            }
            f.Write(lights.Count);
            for(int i=0; i<lights.Count; i++)
            {
                var so = new SerializedObject(lights[i]);
                var channel = so.FindProperty("m_BakingOutput").FindPropertyRelative("occlusionMaskChannel").intValue;

                int val1 = subtractive ? 0 : -1;
                int val2 = subtractive ? 131076 : 131080;

                f.Write(val1);
                f.Write(channel);
                f.Write(val2);
            }
            f.Write(bytesP3);
            f.Close();
        }
        catch
        {
            ftRenderLightmap.DebugLogError("Failed to generate LightingDataAsset");
            success = false;
            throw;
        }
        return success;
    }

#if UNITY_2017_3_OR_NEWER
#else
    // Patches existing LightingDataAsset shadowmask channels
    public static bool PatchShadowmaskLightingData(string inName, string outName, ref Dictionary<long,long> inID2OutID, ref Dictionary<long,int> outIDChannel, bool subtractive)
    {
        try
        {
            var bytesIn = File.ReadAllBytes(inName);

            var lightCount = inID2OutID.Count;
            if (lightCount == 0) return false;

            var inIDsAsBytes = new byte[lightCount][];
            var outIDsAsBytes = new byte[lightCount][];
            var outChannelsAsBytes = new byte[lightCount][];
            var matches = new int[lightCount];
            int counter = 0;
            foreach(var pair in inID2OutID)
            {
                inIDsAsBytes[counter] = BitConverter.GetBytes(pair.Key);
                outIDsAsBytes[counter] = BitConverter.GetBytes(pair.Value);
                outChannelsAsBytes[counter] = BitConverter.GetBytes(outIDChannel[pair.Value]);
                counter++;
            }

            int replaced = 0;
            int firstAddressReplaced = bytesIn.Length;
            var lightsAsWritten = new int[lightCount];
            int lightsAsWrittenCounter = 0;
            for(int i=0; i<bytesIn.Length; i++)
            {
                var val = bytesIn[i];
                for(int j=0; j<lightCount; j++)
                {
                    var expectedVal = matches[j] >= 8 ? 0 : inIDsAsBytes[j][matches[j]];
                    if (val == expectedVal)
                    {
                        matches[j]++;
                        if (matches[j] == 16)
                        {
                            // Matched long + 8 zeros
                            // Replace fileid
                            for(int k=0; k<8; k++)
                            {
                                //Debug.LogError("Matched " + inIDsAsBytes[j][k]+" "+outIDsAsBytes[j][k]);
                                bytesIn[i - 15 + k] = outIDsAsBytes[j][k];
                            }
                            matches[j] = 0;
                            replaced++;

                            int addr = i - 15;
                            if (addr < firstAddressReplaced) firstAddressReplaced = addr;

                            lightsAsWritten[lightsAsWrittenCounter] = j;
                            lightsAsWrittenCounter++;
                        }
                    }
                    else
                    {
                        matches[j] = 0;
                    }
                }
            }

            if (firstAddressReplaced == bytesIn.Length)
            {
                ftRenderLightmap.DebugLogError("Failed to patch LightingDataAsset: unabled to replace light IDs");
                return false;
            }

            if (lightsAsWrittenCounter != lightCount)
            {
                ftRenderLightmap.DebugLogError("Failed to patch LightingDataAsset: light count differs in temp/real scenes (" + lightsAsWrittenCounter + " vs " + lightCount + ")");
                return false;
            }

            // IDs are patched. Now replace channels.

            for(int i=0; i<lightsAsWrittenCounter; i++)
            {
                int id = lightsAsWritten[i];
                var channelBytes = outChannelsAsBytes[id];
                int channelStartAddr = firstAddressReplaced + 16 * lightCount + 4 + 12 * i + 4;
                if (subtractive)
                {
                    for(int j=0; j<4; j++)
                    {
                        bytesIn[channelStartAddr + j - 4] = 0;
                    }
                }
                for(int j=0; j<4; j++)
                {
                    bytesIn[channelStartAddr + j] = channelBytes[j];
                }
                if (subtractive)
                {
                    var val2 = BitConverter.GetBytes(131076);
                    for(int j=0; j<4; j++)
                    {
                        bytesIn[channelStartAddr + j + 4] = val2[j];
                    }
                }
            }

            var f = new BinaryWriter(File.Open(outName, FileMode.Create));
            f.Write(bytesIn);
            f.Close();
            ftRenderLightmap.DebugLogInfo("PatchShadowmaskLightingData: patched " + replaced + " lights");
        }
        catch
        {
            ftRenderLightmap.DebugLogError("Failed to patch LightingDataAsset");
            return false;
        }

        return true;
    }
#endif
}

#endif
