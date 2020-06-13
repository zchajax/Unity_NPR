using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class PencilEffect : MonoBehaviour
{
    public Material m_PencilMat;

    [Range(0.000001f, 0.01f)]
    public float GradiantThreshold = 0.001f;

    [Range(0.0f, 1.0f)]
    public float ColorThreshold = 0.5f;

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        int _GradiantThresholdId = Shader.PropertyToID("_GradiantThreshold");
        int _ColorThresholdId = Shader.PropertyToID("_ColorThreshold");

        m_PencilMat.SetFloat(_GradiantThresholdId, GradiantThreshold);
        m_PencilMat.SetFloat(_ColorThresholdId, ColorThreshold);
        Graphics.Blit(src, dest, m_PencilMat);
    }
}
