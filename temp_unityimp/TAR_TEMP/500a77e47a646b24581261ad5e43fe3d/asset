using UnityEngine;
using UnityEditor.SceneManagement;
using System.Text;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;

public class ftClient
{
    public const byte SERVERTASK_COPY = 0;
    public const byte SERVERTASK_FTRACE = 1;
    public const byte SERVERTASK_FTRACERTX = 2;
    public const byte SERVERTASK_COMBINEMASKS = 3;
    public const byte SERVERTASK_COMBINESH = 4;

    public const byte SERVERTASK_DENOISE5 = 5;
    public const byte SERVERTASK_DENOISE6 = 6;
    public const byte SERVERTASK_DENOISE7 = 7;
    public const byte SERVERTASK_DENOISEOIDN = 8;

    public const byte SERVERTASK_HF2HDR = 9;
    public const byte SERVERTASK_RGBA2TGA = 10;
    public const byte SERVERTASK_SEAMFIX = 11;

    public const byte SERVERTASK_LMREBAKE = 12;
    public const byte SERVERTASK_LMREBAKESIMPLE = 13;
    public const byte SERVERTASK_LODGEN = 14;
    public const byte SERVERTASK_LODGENINIT = 15;
    public const byte SERVERTASK_GIPARAMS = 16;
    public const byte SERVERTASK_RECEIVEFILE = 17;
    public const byte SERVERTASK_REPORTSTATUS = 18;
    public const byte SERVERTASK_SETSCENENAME = 19;
    public const byte SERVERTASK_GETDATA = 20;
    public const byte SERVERTASK_GETDATAREADY = 21;

    public const byte SERVERERROR_IDLE = 0;
    public const byte SERVERERROR_COPY = 1;
    public const byte SERVERERROR_EXEC = 2;
    public const byte SERVERERROR_APPERR = 3;
    public const byte SERVERERROR_GIPARAMS = 4;
    public const byte SERVERERROR_NOTIMPLEMENTED = 5;
    public const byte SERVERERROR_UNKNOWNTASK = 6;
    public const byte SERVERERROR_BUSY = 7;
    public const byte SERVERERROR_UNKNOWN = 8;
    public const byte SERVERERROR_SCENENAMETOOLONG = 9;
    public const byte SERVERERROR_FILENOTFOUND = 10;
    public const byte SERVERERROR_FILEHASZEROSIZE = 11;
    public const byte SERVERERROR_NOMEM = 12;
    public const byte SERVERERROR_INCORRECT = 13;
    public const byte SERVERERROR_INCORRECTFILENAME = 14;
    public const byte SERVERERROR_WRITEFAILED = 15;
    public const byte SERVERERROR_INCORRECTARGS = 16;
    public const byte SERVERERROR_FILESIZE = 17;
    public const byte SERVERERROR_STATUSLIMIT = 18;

    public static string serverAddress = "127.0.0.1";
    const int serverPort = 27777;
    public static bool connectedToServer = false;
    public static string lastServerMsg = "Server: no data";
    public static string lastServerScene = ""; // last baked scene
    public static int lastServerErrorCode = 0;
    public static bool lastServerMsgIsError = false;
    public static bool serverGetDataMode = false; // if we're in download mode or status polling mode
    public static bool serverMustRefreshData = false; // if ready to apply downloaded data

    static string lastServerFile = ""; // last file loaded via GETDATA on the server
    static int lastServerFileHash = 0;
    static int lastServerFileSize = 0;
    static double timeToUpdateServerStatus = 0;
    static double serverStatusInterval = 1000.0;
    static double serverConnectionTimeout = 2000.0;

    static Socket statusSocket;
    //static System.Threading.Thread statusThread;
    static IEnumerator statusProc;

    public static Dictionary<string, byte> app2serverTask = new Dictionary<string, byte>
    {
        {"ftrace", SERVERTASK_FTRACE},
        {"ftraceRTX", SERVERTASK_FTRACERTX},
        {"combineMasks", SERVERTASK_COMBINEMASKS},
        {"combineSH", SERVERTASK_COMBINESH},

        {"denoiserLegacy", SERVERTASK_DENOISE5},
        {"denoiser", SERVERTASK_DENOISE6},
        {"denoiser72", SERVERTASK_DENOISE7},
        {"denoiserOIDN", SERVERTASK_DENOISEOIDN},

        {"halffloat2hdr", SERVERTASK_HF2HDR},
        {"rgba2tga", SERVERTASK_RGBA2TGA},
        {"seamfixer", SERVERTASK_SEAMFIX},
        {"lmrebake (simple)", SERVERTASK_LMREBAKESIMPLE},
        {"lmrebake", SERVERTASK_LMREBAKE}

    };
    public static List<string> serverFileList, serverGetFileList;
    public static int serverGetFileIterator = 0;


    public static IEnumerator UpdateConnection()//WaitForMessages()
    {
        var ipAdd = System.Net.IPAddress.Parse(serverAddress);
        var remoteEP = new IPEndPoint(ipAdd, serverPort);
        var request = new byte[1];
        request[0] = SERVERTASK_REPORTSTATUS;
        var requestGet = new byte[5];
        requestGet[0] = SERVERTASK_GETDATAREADY;
        int numTasks = 1;
        var taskGet = new byte[1];
        var nullByte = new byte[1];
        taskGet[0] = SERVERTASK_GETDATA;
        nullByte[0] = 0;

        lastServerMsg = "Connecting...";
        lastServerErrorCode = 0;
        lastServerMsgIsError = false;
        var status = new byte[256];
        byte[] fileBuffer = null;
        bool waitingForGet = false;

        while (connectedToServer)
        {
            if (statusSocket != null)
            {
                statusSocket.Close();
                statusSocket = null;
            }

            waitingForGet = false;


            // Attempt connecting to server
            bool connectionInProgress = true;
            bool connectionError = false;
            double timeout = ftRenderLightmap.GetTimeMs() + serverConnectionTimeout;
            while(connectionInProgress)
            {
                connectionInProgress = false;
                try
                {
                    if (statusSocket == null)
                    {
                        statusSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                        statusSocket.Blocking = false;
                        statusSocket.Connect(remoteEP);
                    }
                    else
                    {
                        if (statusSocket.Poll(0, SelectMode.SelectError))
                        {
                            connectionError = true;
                            break;
                        }
                        if (!statusSocket.Poll(0, SelectMode.SelectWrite) && ftRenderLightmap.GetTimeMs() < timeout)
                        {
                            connectionInProgress = true;
                        }
                    }
                }
                catch(SocketException s)
                {
                    if (s.ErrorCode == 10035) // WSAEWOULDBLOCK
                    {
                        connectionInProgress = true;
                    }
                    else
                    {
                        connectionError = true;
                        break;
                    }
                }
                if (connectionInProgress) yield return null;
            }
            statusSocket.Blocking = true;

            // Send request(s)
            try
            {
                if (connectionError) throw new SocketException();
                if (serverGetDataMode && serverGetFileList == null) serverGetDataMode = false;
                if (serverGetDataMode && serverGetFileList.Count <= serverGetFileIterator)
                {
                    serverMustRefreshData = true;
                    serverGetDataMode = false;
                }
                if (serverGetDataMode)
                {
                    var fname = serverGetFileList[serverGetFileIterator];
                    if (lastServerFile != fname)
                    {
                        int len = fname.Length;
                        statusSocket.Send(System.BitConverter.GetBytes(numTasks));
                        statusSocket.Send(taskGet);
                        statusSocket.Send(System.BitConverter.GetBytes(len));
                        statusSocket.Send(Encoding.ASCII.GetBytes(fname));
                        statusSocket.Send(nullByte);
                        statusSocket.Close();

                        statusSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                        statusSocket.Connect(remoteEP);
                        statusSocket.Send(request);
#if BAKERY_NETDEBUG
                        Debug.Log("Request sent (load file " + fname + ")");
#endif
                    }
                    else
                    {
                        fileBuffer = new byte[lastServerFileSize];
                        System.Buffer.BlockCopy(System.BitConverter.GetBytes(lastServerFileHash), 0, requestGet, 1, 4);
                        statusSocket.Send(requestGet);
#if BAKERY_NETDEBUG
                        Debug.Log("Request sent (get file)");
#endif
                        waitingForGet = true;
                    }
                }
                else
                {
                    statusSocket.Send(request);
#if BAKERY_NETDEBUG
                    Debug.Log("Request sent");
#endif
                }
            }
            catch(SocketException s)
            {
                lastServerMsg = "Failed to get data from server (" + s.ErrorCode + ")";
                lastServerMsgIsError = true;
                lastServerErrorCode = 0;

                Debug.LogError(lastServerMsg);
                statusSocket.Close();
                statusSocket = null;
                statusProc = null;
                //statusThread = null;
                connectedToServer = false;
                //return;
                yield break;
            }

#if BAKERY_NETDEBUG
            Debug.Log("Waiting for server to respond");
#endif

            int serverErrCode = 0;
            int appCode = 0;
            int appErrCode = 0;
            int textLen = 0;
            int fileReady = 0;
            int fileHash = 0;
            int fileSize = 0;
            string text = "";
            string fileNameReady = "";

            int byteCount = 0;
            bool interrupted = false;
            double maxTimeToReceive = 10.0;
            double timeToInterrupt = ftRenderLightmap.GetTimeMs() + maxTimeToReceive;

            while(!interrupted)
            {
                if (ftRenderLightmap.GetTimeMs() > timeToInterrupt)
                {
                    timeToInterrupt = ftRenderLightmap.GetTimeMs() + maxTimeToReceive;
                    yield return null;
                }
                //while(statusSocket.Available == 0) yield return null;
                //while(!statusSocket.Poll(0, SelectMode.SelectRead)) yield return null;
                try
                {
                    //while(true)
                    //{
                        if (waitingForGet)
                        {
                            int bytesReceived = statusSocket.Receive(fileBuffer, byteCount, fileBuffer.Length - byteCount, SocketFlags.None);
                            byteCount += bytesReceived;
                            //Debug.Log("Received " + bytesReceived);
                            if (bytesReceived == 0) interrupted = true;//break;
                        }
                        else
                        {
                            byteCount = statusSocket.Receive(status);
                            //break;
                            interrupted = true;
                        }
                    //}
                }
                catch
                {
                    if (waitingForGet)
                    {
                        Debug.LogError("Error getting file from server - retrying");
                        lastServerFile = "";
                    }
                    else
                    {
                        lastServerMsg = "Server disconnected";
                        lastServerMsgIsError = true;
                        lastServerErrorCode = 0;

                        Debug.LogError(lastServerMsg);
                        statusSocket.Close();
                        statusSocket = null;
                        //statusThread = null;
                        statusProc = null;
                        connectedToServer = false;
                        yield break;
                    }
                }
            }

            if (byteCount > 0)
            {
                if (waitingForGet)
                {
                    Debug.Log("Data received: " + byteCount);
                    var ext = lastServerFile.Substring(lastServerFile.Length-3).ToLower();
                    string outPath;
                    if (ext == "lz4" || ext == "dds")
                    {
                        outPath = ftRenderLightmap.scenePath + "/" + lastServerFile;
                    }
                    else
                    {
                        outPath = "Assets/" + ftRenderLightmap.outputPath + "/" + lastServerFile;
                    }
                    BinaryWriter bw = null;
                    try
                    {
                        bw = new BinaryWriter(File.Open(outPath, FileMode.Create));
                    }
                    catch
                    {
                        Debug.LogError("Failed writing " + outPath);
                    }
                    if (bw != null)
                    {
                        bw.Write(fileBuffer);
                        bw.Close();
                        Debug.Log("File saved: " + outPath);
                    }
                    yield return null;
                    serverGetFileIterator++;
                }
                else
                {
                    if (byteCount == 150)
                    {
                        serverErrCode = System.BitConverter.ToInt32(status, 0);
                        appCode = System.BitConverter.ToInt32(status, 4);
                        appErrCode = System.BitConverter.ToInt32(status, 8);
                        textLen = status[12];
                        fileReady = status[13];
                        fileHash = System.BitConverter.ToInt32(status, 14);
                        fileSize = System.BitConverter.ToInt32(status, 18);
                        if (textLen > 0)
                        {
                            text = Encoding.ASCII.GetString(status, 22, textLen);
                        }
                        if (fileReady > 0)
                        {
                            fileNameReady = Encoding.ASCII.GetString(status, 22 + textLen + 1, fileReady);
                        }
                    }
                    else
                    {
                        serverErrCode = SERVERERROR_UNKNOWN;
                        Debug.LogError("Unrecognized response size: " + byteCount);
                    }
                    //if (serverErrCode != 0)
                    {
                        var serverMsg = "Server: " + ftErrorCodes.TranslateServer(serverErrCode, appCode, appErrCode);
                        bool isError = serverErrCode != SERVERERROR_IDLE && serverErrCode != SERVERERROR_BUSY;
                        if (isError)
                        {
                            Debug.LogError(serverMsg);
                        }
                        else
                        {
#if BAKERY_NETDEBUG
                            Debug.Log(serverMsg);
#else
                            if (lastServerMsg != serverMsg) Debug.Log(serverMsg);
#endif
                        }
                        lastServerMsg = serverMsg;
                        lastServerMsgIsError = isError;
                        lastServerErrorCode = serverErrCode;
                        lastServerScene = text;
                        lastServerFile = fileNameReady;
                        lastServerFileHash = fileHash;
                        lastServerFileSize = fileSize;
                    }
                }
            }


            if (!serverGetDataMode)
            {
                //var sleepTime = timeToUpdateServerStatus - curTime;
                //if (sleepTime > 0) System.Threading.Thread.Sleep((int)sleepTime);
                while(true)
                {
                    var curTime = ftRenderLightmap.GetTimeMs();
                    if (curTime >= timeToUpdateServerStatus) break;
                    yield return null;
                }

                timeToUpdateServerStatus = ftRenderLightmap.GetTimeMs() + serverStatusInterval;
            }
        }

        statusSocket.Close();
        statusSocket = null;
        //statusThread = null;
        statusProc = null;
    }

    public static void Disconnect()
    {
        if (statusSocket != null)
        {
            statusSocket.Close();
            statusSocket = null;
        }

        statusProc = null;
        /*if (statusThread != null)
        {
            statusThread.Abort();
            statusThread = null;
        }*/

        connectedToServer = false;
        serverGetDataMode = false;
    }

    public static void ConnectToServer()
    {
        try
        {
            Disconnect();
            connectedToServer = true;

            timeToUpdateServerStatus = 0;
            //statusThread = new System.Threading.Thread(WaitForMessages);
            //statusThread.Start();
            statusProc = UpdateConnection();
            statusProc.MoveNext();
        }
        catch
        {
            Debug.LogError("Failed getting data from server");
            throw;
        }
    }

    public static bool SendRenderSequence(byte[] renderSequence)
    {
        Socket soc = null;
        var ipAdd = System.Net.IPAddress.Parse(serverAddress);
        var remoteEP = new IPEndPoint(ipAdd, serverPort);
        bool connectionInProgress;

        for(int i=0; i<serverFileList.Count; i++)
        {
            var fsoc = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            connectionInProgress = true;
            while(connectionInProgress)
            {
                try
                {
                    connectionInProgress = false;
                    fsoc.Connect(remoteEP);
                }
                catch(SocketException s)
                {
                    if (s.ErrorCode == 10035) // WSAEWOULDBLOCK
                    {
                        connectionInProgress = true;
                    }
                    else if (s.ErrorCode == 10061) //  WSAECONNREFUSED
                    {
                        connectionInProgress = true;
                        System.Threading.Thread.Sleep(1000); // apparently we're sending more than the server can chew - wait a bit
                    }
                    else
                    {
                        Debug.LogError("Socket error");
                        throw s;
                    }
                }
            }
            if (!fsoc.Poll(0, SelectMode.SelectWrite)) return false;

            var sceneFile = File.ReadAllBytes(ftRenderLightmap.scenePath + "/" + serverFileList[i]);
            int headerSize = 5 + serverFileList[i].Length + 1;
            var buff = new byte[sceneFile.Length + headerSize];

            int numTasks = 1;
            System.Buffer.BlockCopy(System.BitConverter.GetBytes(numTasks), 0, buff, 0, 4);
            buff[4] = SERVERTASK_RECEIVEFILE;
            buff[5] = (byte)serverFileList[i].Length;
            for(int j=0; j<serverFileList[i].Length; j++) buff[6+j] = (byte)serverFileList[i][j];
            System.Buffer.BlockCopy(sceneFile, 0, buff, headerSize, sceneFile.Length);

            connectionInProgress = true;
            while(connectionInProgress)
            {
                try
                {
                    connectionInProgress = false;
                    fsoc.Send(buff);
                }
                catch(SocketException s)
                {
                    if (s.ErrorCode == 10035) // WSAEWOULDBLOCK
                    {
                        connectionInProgress = true;
                    }
                    else if (s.ErrorCode == 10061) //  WSAECONNREFUSED
                    {
                        connectionInProgress = true;
                        System.Threading.Thread.Sleep(1000); // apparently we're sending more than the server can chew - wait a bit
                    }
                    else
                    {
                        Debug.LogError("Socket error (2)");
                        throw s;
                    }
                }
            }

            fsoc.Close();
        }

        soc = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
        soc.Connect(remoteEP);
        if (!soc.Poll(0, SelectMode.SelectWrite)) return false;
        soc.Send(renderSequence);
        soc.Close();
        return true;
    }

    public static void ServerGetData(List<string> fileList)
    {
        serverGetFileList = fileList;
        serverGetFileIterator = 0;
        serverGetDataMode = true;
    }

    public static void Update()
    {
        if (statusProc != null) statusProc.MoveNext();
    }
}

