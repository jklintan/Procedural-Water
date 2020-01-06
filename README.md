# Procedural Water tool in Unity
This is a procedural ocean shader for Unity completely procedural and using mathematical noise for normal displacement instead of normal maps. The shader includes large wave displacement from wind direction, small ripple displacement from normaldistortion using noise, fresnel effect, depth rendering for foamlines and using scene height for large wave foam.

Working on expanding the project into an unlit shader that computes reflection and refraction. 

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



