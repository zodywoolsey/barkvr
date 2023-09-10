using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace VRCMarker
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class MarkerTrail : UdonSharpBehaviour
    {
        public Marker marker;
        public Transform trailPosition;
        public Color color = Color.white;
        public float minDistance = 0.002f;
        public float width = 0.003f;
        public float updateRate = 0.03f;
        public float smoothing = 0.67f;
        private float _smoothingCached = 1;

        private Vector3[] _vertices = new Vector3[0];
        private int[] _triangles = new int[0];
        private Vector3[] _normals = new Vector3[0];
        private Vector2[] _uv = new Vector2[0];

        public int vertexLimit = 32000;
        private int _verticesUsed = 0;
        private int _lastVerticesUsed = 0;
        private int _trianglesUsed = 0;
        private int _lastTrianglesUsed = 0;

        private Mesh _mesh;
        private Mesh _trailing;
        public MeshFilter trailingMesh;
        public MeshFilter trailStorage;

        private float _time = 0;
        private Vector3 _previousPosition = Vector3.zero;
        private Vector3 _previousSmoothingPosition = Vector3.zero;
        private Vector3 _smoothingPosition = Vector3.zero;

        public bool isLocal = true;

        private Vector3[] _syncLines = new Vector3[MarkerSync.MaxSyncCount];
        private int _syncLinesUsed = 0;

        private const string Version = "1";

        private void Start()
        {
            _mesh = new Mesh();
            _mesh.name = "Trail";
            _mesh.MarkDynamic();
            trailStorage.GetComponent<MeshFilter>().sharedMesh = _mesh;

            _trailing = new Mesh();
            _trailing.name = "Traling";
            _trailing.MarkDynamic();
            trailingMesh.sharedMesh = _trailing;

            var propertyBlock = new MaterialPropertyBlock();
            propertyBlock.SetColor("_Color", color);
            propertyBlock.SetFloat("_Scale", width);
            trailStorage.GetComponent<MeshRenderer>().SetPropertyBlock(propertyBlock);
            trailingMesh.GetComponent<MeshRenderer>().SetPropertyBlock(propertyBlock);

            trailingMesh.gameObject.SetActive(false);

            ResetTransforms();

            CreateTrailingLineConstants();
            enabled = false;
        }


        

        private void Update()
        {
            _time += Time.deltaTime;


            _smoothingPosition = Vector3.Lerp(trailPosition.position, _previousSmoothingPosition, _smoothingCached);
            _previousSmoothingPosition = _smoothingPosition;

            UpdateTrailingLine(_smoothingPosition, _previousPosition);

            if (_time <= updateRate || !enabled || Vector3.Distance(_smoothingPosition, _previousPosition) < minDistance)
            {
                return;
            }

            CreateTrailLine(_previousPosition, _smoothingPosition);
            UpdateMeshData();
            StoreLastLinesTransform(_smoothingPosition);
            if (_syncLinesUsed == 6)
            {
                // prevent wrong first lines from object sync
                marker.StartWritingRemote();
            }

            _previousPosition = _smoothingPosition;
            _time = 0;
        }

        public void StartWriting()
        {
            if (enabled) return;

            _time = 0;
            _smoothingCached = smoothing;
            _lastVerticesUsed = _verticesUsed;
            _lastTrianglesUsed = _trianglesUsed;

            var position = trailPosition.position;
            _smoothingPosition = position;
            _previousSmoothingPosition = position;
            _previousPosition = position;
            trailingMesh.gameObject.SetActive(true);
            CreateTrailLine(position, position);

            UpdateTrailingLine(position, position);
            StoreLastLinesTransform(position);
            UpdateMeshData();


            enabled = true;
        }

        public void StopWriting()
        {
            if (!enabled) return;
            enabled = false;

            _time = 0;
            _smoothingCached = 1;
            trailingMesh.gameObject.SetActive(false);


            if (isLocal && GetSyncLines().Length > 1)
            {
                AddEndCap();
                StoreLastLinesTransform(_smoothingPosition);
            }
        }

        public void AddEndCap()
        {
            CreateTrailLine(_previousPosition, _smoothingPosition);
            //CreateTrailLine(_smoothingPosition, _previousPosition); // mot needed anymore
            UpdateMeshData();
        }

        public void UpdateMeshData()
        {
            _mesh.vertices = _vertices;
            _mesh.triangles = _triangles;
            _mesh.normals = _normals;
            _mesh.SetUVs(0, _uv);
            _mesh.RecalculateBounds();
        }

        public void Clear()
        {
            _time = 0;
            _vertices = new Vector3[0];
            _triangles = new int[0];
            _normals = new Vector3[0];
            _uv = new Vector2[0];

            _mesh.triangles = _triangles;
            _mesh.normals = _normals;
            _mesh.SetUVs(0, _uv);
            _mesh.vertices = _vertices;

            _verticesUsed = 0;
            _trianglesUsed = 0;
            _lastVerticesUsed = 0;
            _lastTrianglesUsed = 0;
            ResetSyncLines();
        }

        private void CreateTrailingLineConstants()
        {
            var vertices = new Vector3[10];
            // lines
            vertices[0] = Vector3.zero;
            vertices[1] = Vector3.zero;
            vertices[2] = Vector3.zero;
            vertices[3] = Vector3.zero;
            // connections
            vertices[4] = Vector3.zero;
            vertices[5] = Vector3.zero;
            vertices[6] = Vector3.zero;
            vertices[7] = Vector3.zero;
            vertices[8] = Vector3.zero;
            vertices[9] = Vector3.zero;

            var triangles = new int[12];
            // lines
            triangles[0] = 0;
            triangles[1] = 1;
            triangles[2] = 2;
            triangles[3] = 0;
            triangles[4] = 2;
            triangles[5] = 3;
            // connections
            triangles[6] = 6;
            triangles[7] = 5;
            triangles[8] = 4;
            triangles[9] = 9;
            triangles[10] = 8;
            triangles[11] = 7;

            var uv = new Vector2[10];
            // lines
            uv[0] = _UV_0;
            uv[1] = _UV_1;
            uv[2] = _UV_2;
            uv[3] = _UV_3;
            // connections
            uv[4] = _UV_4;
            uv[5] = _UV_5;
            uv[6] = _UV_6;
            uv[7] = _UV_4;
            uv[8] = _UV_5;
            uv[9] = _UV_6;

            var normals = new Vector3[10];
            // lines
            normals[0] = Vector3.zero;
            normals[1] = Vector3.zero;
            normals[2] = Vector3.zero;
            normals[3] = Vector3.zero;
            // connections
            //normals[4] = Vector3.zero;
            //normals[5] = Vector3.zero;
            //normals[6] = Vector3.zero;

            _trailing.vertices = vertices;
            _trailing.triangles = triangles;
            _trailing.normals = normals;
            _trailing.SetUVs(0, uv);
        }

        private void UpdateTrailingLine(Vector3 start, Vector3 end)
        {
            var vertices = new Vector3[10];
            // lines
            vertices[0] = start;
            vertices[1] = start;
            vertices[2] = end;
            vertices[3] = end;
            // connections
            vertices[4] = start;
            vertices[5] = start;
            vertices[6] = start;
            vertices[7] = end;
            vertices[8] = end;
            vertices[9] = end;

            var normals = new Vector3[10];
            // lines
            normals[0] = end;
            normals[1] = end;
            normals[2] = start;
            normals[3] = start;
            // connections
            //normals[4] = Vector3.zero;
            //normals[5] = Vector3.zero;
            //normals[6] = Vector3.zero;

            _trailing.vertices = vertices;
            _trailing.normals = normals;
            _trailing.RecalculateBounds();
        }

        private readonly Vector2 _UV_0 = new Vector2(0, 0);
        private readonly Vector2 _UV_1 = new Vector2(0, 1);
        private readonly Vector2 _UV_2 = new Vector2(1, 1);
        private readonly Vector2 _UV_3 = new Vector2(1, 0);
        private readonly Vector2 _UV_4 = new Vector2(-0.077350269189625764509148780501f, 0);
        private readonly Vector2 _UV_5 = new Vector2(0.5f, 1);
        private readonly Vector2 _UV_6 = new Vector2(1.077350269189625764509148780501f, 0);

        public void CreateTrail(Vector3[] positions)
        {
            RevertUsedVertices();

            CreateTrailLine(positions[0], positions[0]);

            for (int i = 1; i < positions.Length; i++)
            {
                CreateTrailLine(positions[i - 1], positions[i]);
            }


            UpdateUsedVertices();

            UpdateMeshData();
        }
        
        public void RevertUsedVertices()
        {
            _verticesUsed = _lastVerticesUsed;
            _trianglesUsed = _lastTrianglesUsed;
        }

        public void UpdateUsedVertices()
        {
            _lastVerticesUsed = _verticesUsed;
            _lastTrianglesUsed = _trianglesUsed;
        }

        const int vertexIncrement = 7;
        const int triangleIncrement = 9;
        public void CreateTrailLine(Vector3 end, Vector3 start)
        {
            
            UpdateArraySize(vertexIncrement, triangleIncrement);

            int v0 = _verticesUsed;
            int v1 = _verticesUsed + 1;
            int v2 = _verticesUsed + 2;
            int v3 = _verticesUsed + 3;
            int v4 = _verticesUsed + 4;
            int v5 = _verticesUsed + 5;
            int v6 = _verticesUsed + 6;

            int t0 = _trianglesUsed;
            int t1 = _trianglesUsed + 1;
            int t2 = _trianglesUsed + 2;
            int t3 = _trianglesUsed + 3;
            int t4 = _trianglesUsed + 4;
            int t5 = _trianglesUsed + 5;
            int t6 = _trianglesUsed + 6;
            int t7 = _trianglesUsed + 7;
            int t8 = _trianglesUsed + 8;


            // line
            _vertices[v0] = start;
            _vertices[v1] = start;
            _vertices[v2] = end;
            _vertices[v3] = end;

            _triangles[t0] = v0;
            _triangles[t1] = v1;
            _triangles[t2] = v2;
            _triangles[t3] = v0;
            _triangles[t4] = v2;
            _triangles[t5] = v3;

            _uv[v0] = _UV_0;
            _uv[v1] = _UV_1;
            _uv[v2] = _UV_2;
            _uv[v3] = _UV_3;

            _normals[v0] = end;
            _normals[v1] = end;
            _normals[v2] = start;
            _normals[v3] = start;

            // triangle
            _vertices[v4] = start;
            _vertices[v5] = start;
            _vertices[v6] = start;

            _triangles[t6] = v6;
            _triangles[t7] = v5;
            _triangles[t8] = v4;

            _uv[v4] = _UV_4;
            _uv[v5] = _UV_5;
            _uv[v6] = _UV_6;

            _normals[v4] = Vector3.zero;
            _normals[v5] = Vector3.zero;
            _normals[v6] = Vector3.zero;

            _verticesUsed += vertexIncrement;
            _trianglesUsed += triangleIncrement;
        }

        private void StoreLastLinesTransform(Vector3 position)
        {
            if (!isLocal)
            {
                return;
            }

            if (_syncLinesUsed > _syncLines.Length - 1)
            {
                return;
            }
            _syncLines[_syncLinesUsed] = position;
            _syncLinesUsed++;
        }
 
        public bool UndoLastLines()
        {
            if (_verticesUsed == 0)
            {
                return false;
            }


            int newVertexCount = _verticesUsed - vertexIncrement;
            for (int i = _verticesUsed; i >= newVertexCount; i--)
            {
                _vertices[i] = Vector3.zero;
            }
            _verticesUsed = newVertexCount;

            return true;
        }

        public bool IsLastPositionEndOfLine()
        {
            if (_verticesUsed <= vertexIncrement)
            {
                return false;
            }

            Vector3 startPos = _vertices[_verticesUsed - 1];
            Vector3 endPos = _vertices[_verticesUsed - 4];
            return Equals(startPos, endPos);
        }

        public bool MarkerInitialized()
        {
            return _vertices.Length != 0 && _verticesUsed != 0;
        }


        public Vector3[] GetSyncLines()
        {
            var arr = new Vector3[_syncLinesUsed];
            Array.Copy(_syncLines, arr, _syncLinesUsed);
            return arr;
        }

        public void ResetSyncLines()
        {
            _syncLinesUsed = 0;
        }

        private void UpdateArraySize(int verticesReserved, int trianglesReserved)
        {
            const int multiplier = 100;
            trianglesReserved *= multiplier;
            verticesReserved *= multiplier;

            int vCount = _verticesUsed + verticesReserved;
            if (vCount > _vertices.Length)
            {
                if (vCount > vertexLimit)
                {
                    _verticesUsed = 0;
                    _trianglesUsed = 0;
                    return;
                }
                _vertices = ResizeArray(_vertices, verticesReserved);
                _normals = ResizeArray(_normals, verticesReserved);
                _uv = ResizeArray(_uv, verticesReserved);
            }

            if (_trianglesUsed + trianglesReserved > _triangles.Length)
            {
                _triangles = ResizeArray(_triangles, trianglesReserved);
            }
        }

        private static T[] ResizeArray<T>(T[] sourceArray, int incrementSize)
        {
            var newArray = new T[incrementSize + sourceArray.Length];
            Array.Copy(sourceArray, newArray, sourceArray.Length);
            return newArray;
        }

        /// <summary>
        /// Fix culling and other issues caused by transforms not being at zero when moving the root after Start.
        /// </summary>
        public void ResetTransforms()
        {
            ResetTRS(transform);
            ResetTRS(trailingMesh.transform);
            ResetTRS(trailStorage.transform);
        }

        private static void ResetTRS(Transform transform)
        {
            var parent = transform.parent;
            transform.parent = null;
            transform.localScale = Vector3.one;
            transform.parent = parent;

            transform.position = Vector3.zero;
            transform.rotation = Quaternion.identity;
        }
    }
}