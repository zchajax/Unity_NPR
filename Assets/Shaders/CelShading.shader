﻿Shader "NPR/CelShading"
{
    Properties
    {
        _Color ("Tint Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _Outline ("Outline", Range(0, 1)) = 0.05
        _OutlineColor ("Outline Color", Color) = (0 ,0 , 0, 0)
        _Shininess ("Shininess", Range(1, 600)) = 200
        _DiffuseSegment ("Diffuse Segment", Vector) = (0.1, 0.3, 0.6, 1.0)
        _RampSmooth("Ramp Smooth", Range(0, 0.1)) = 0.02
        _SpecularSmooth("Specualr Smooth", Range(0, 1)) = 0.02 
        _RimPower("Rim Power", Range(1., 10.)) = 3.
        _RimStrenth("Rim Strength", Range(0., 1.)) = 1.
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            NAME "OUTLINE"
            Cull front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            fixed _Outline;
            fixed4 _OutlineColor;

            v2f vert (appdata v)
            {
                // Scale with distance from view point
                /*v2f o;
                float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 viewNormal = mul(UNITY_MATRIX_IT_MV, v.normal);
                viewNormal.z = -0.5;
                viewPos += float4(normalize(viewNormal), 0) * _Outline;
                o.vertex = mul(UNITY_MATRIX_P, viewPos);*/

                // Not scale with distance from view point
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                float2 extendDir = normalize(TransformViewToProjection(viewNormal.xy));
                o.vertex.xy += extendDir * (o.vertex.w * _Outline * 0.1);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }

        Pass
        {
            Tags {
                    "LightMode" = "ForwardBase"
                    "RenderType"="Opaque"
                 }

            Cull back

            ZWrite On
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define PI 3.14159265358979323846264338327950288419716939937510
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _DiffuseSegment;
            float _Shininess;
            float _RampSmooth;
            float _SpecularSmooth;
            float _RimPower;
            float _RimStrenth;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            };

            fixed4 frag(v2f i) : SV_Target
            {

                float3 normal = normalize(i.worldNormal);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfVector = normalize(viewDir + lightDir);

                // diffuse item
                float nl = dot(normal, lightDir);
                nl = nl * 0.5 + 0.5;
                fixed w = _RampSmooth;

                if (nl < _DiffuseSegment.x + w)
                {
					nl = lerp(_DiffuseSegment.x, _DiffuseSegment.y, smoothstep(_DiffuseSegment.x - w, _DiffuseSegment.x + w, nl));
				}
                 else if (nl < _DiffuseSegment.y + w)
                 {
					nl = lerp(_DiffuseSegment.y, _DiffuseSegment.z, smoothstep(_DiffuseSegment.y - w, _DiffuseSegment.y + w, nl));
				}
                else if (nl < _DiffuseSegment.z + w)
                {
					nl = lerp(_DiffuseSegment.z, _DiffuseSegment.w, smoothstep(_DiffuseSegment.z - w, _DiffuseSegment.z + w, nl));
				}
                else
                {
					nl = _DiffuseSegment.w;
				}

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color;
                fixed3 diffuse = albedo / PI * nl * _LightColor0.rgb;

                // specular item
                float spec = max(0, dot(normal, halfVector));
                spec = pow(spec, _Shininess);

                w = _SpecularSmooth;
                spec = smoothstep(0.5 - w * 0.5, 0.5 + w * 0.5, spec);
                fixed3 specular = spec * _LightColor0.rgb;

                // rim
                half rim = pow(1.0 - saturate(dot(viewDir, normal)), _RimPower);
                rim *= smoothstep(-0.3, 0.3, -dot(viewDir, lightDir));
                rim *= _LightColor0.rgb * _RimStrenth;

                // ambient
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                fixed3 col = diffuse + specular + ambient + rim;
                
                return fixed4(col, 1);
            }

            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
 
            ZWrite On ZTest LEqual
 
            CGPROGRAM
            #pragma target 2.0
 
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster
 
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
 
            #include "UnityStandardShadow.cginc"
 
            ENDCG
        }
    }
}
