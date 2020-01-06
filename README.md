# Procedural Water tool in Unity
This is a procedural ocean shader for Unity completely procedural and using mathematical noise for normal displacement instead of normal maps. The shader includes large wave displacement from wind direction, small ripple displacement from normaldistortion using noise, fresnel effect, depth rendering for foamlines and using scene height for large wave foam.

Working on expanding the project into an unlit shader that computes reflection and refraction. 

![Ocean](/images/final1.PNG)

<h2>Large wave displacement</h2>

![Trochoidal waves](/images/waves.PNG)

The large waves are parametrized according to the wind direction and the wind strength, as well as how frequently the waves should appear (smaller wavelength). A set of trochoidal waves are used for displacement that successfully describes a progressive wave of permanent form on the surface. Since some problems occur with looping when the amplitude of a wave is too large compared to its wavelength, a third trochoidal wave is only added if a high enough wavelength are chosen. 

![Trochoidal wave](/images/wireframe.PNG)

<h2>Small wave displacement</h2>

The small ripples on the surface are consisting of a combination of Perlin noise with different octaves. This combination of noise with different frequencies creates an almost "cloudlike" feeling when using smaller octaves, and will be much more detailed with a higher octave. 

![Noise displacement](/images/ripples.PNG)

<h2>Foamline around objects</h2>

![foamline](/images/foamline.PNG)

In order to being able to use the depth texture, it is needed to enable this on the current rendering camera. Attach the following script to the camera that is being used for the scene. 

```C#
[ExecuteInEditMode]
public class depth : MonoBehaviour
{

    private Camera cam;

    void Start()
    {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.Depth;
    }

}
```

If correctly attached, you can see the following appearing in the inspector for the camera. 

![depth rendering](/images/messageDepth.PNG)

When the camera depth texture exists, this can be used for calculating if points on the surface are near objects that cut through the surface or close to a shoreline. 

```C#
float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
float sceneZ = LinearEyeDepth(rawZ);
float partZ = IN.eyeDepth;

float fade = 1.0;
if (rawZ > 0.0) // Make sure the depth texture exists
    fade = abs(saturate(_InvFade * (sceneZ - partZ)));
			
o.Alpha = 1;
if (fade < _FadeLimit)
    o.Albedo += (0, 0, 0, 0) * fade +_ColorDetail * (1 - fade);
```

<h2>Foam on top of the large waves</h2>
Since the top of the waves are consisting of a smaller amount of water than below, it should get brighter in color at the top. In real life, the waves break over and creates a splashing of foam. This is a possible expansion of this shader but currently, a foam color and pattern from a multioctave perlin noise is added with a gradient to the waves if they are above a certain height in z. 

![Large wave foam](/images/heightFoam.PNG)

<h2>Fresnel Effect</h2>
I am still working on adding full lightning features but a small adjustment that made the appearance more realistic was the implementation of the fresnel effect. This is determined by looking at the angle of the viewer and determine how much of a reflection that should occur. According to physical principles, we get a weak reflection close by the viewer and a strong in the distance. 

![Fresnel Effect](/images/fresnel.PNG)

