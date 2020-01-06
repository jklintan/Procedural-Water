using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UI : MonoBehaviour
{
    Renderer rend;
    GameObject plane;
    GameObject rock;
    bool display = false;

    void Start()
    {
        plane = GameObject.Find("Water");
        rock = GameObject.Find("Rock");
        rend = plane.GetComponent<Renderer>();
        //rend.material.shader = Shader.Find("custom/Water");

        rend.sharedMaterial.SetFloat("_Opacity", (float) 0.7);
        rend.sharedMaterial.SetFloat("_Glossiness", (float) 0.81);
        rend.sharedMaterial.SetFloat("_RippleHeight", (float)0.1);
        rend.sharedMaterial.SetFloat("_RippleFreq", (float) 1.1);
        rend.sharedMaterial.SetFloat("_WindStrength", (float) 0.8);
        rend.sharedMaterial.SetFloat("_WindInt", (float) 2.5);
        rend.sharedMaterial.SetFloat("_InvFade", (float)0.03);
        Vector4 old = rend.sharedMaterial.GetVector("_WindDir");
        rend.sharedMaterial.SetVector("_WindDir", new Vector4(1, 1, old.z, old.w));
        rend.sharedMaterial.SetFloat("_FoamIntens", (float)0.01);
        rock.SetActive(display);
    }


    public void setOpacity(float o)
    {
        rend.sharedMaterial.SetFloat("_Opacity", o);
    }

    public void setSmoothness(float s)
    {
        rend.sharedMaterial.SetFloat("_Glossiness", s);
    }

    public void setRippleHeight(float h)
    {
        rend.sharedMaterial.SetFloat("_RippleHeight", h);
    }

    public void setRippleStrength(float s)
    {
        float d = (float)2.1 - s;
        rend.sharedMaterial.SetFloat("_RippleFreq", d);
    }

    public void setWindStrength(float s)
    {
        rend.sharedMaterial.SetFloat("_WindStrength", s);
    }

    public void setWindFreq(float s)
    {
        float d = (float)2.8 - s;
        rend.sharedMaterial.SetFloat("_WindInt", d);
    }

    public void setFoam(float f)
    {
        float d = (float)0.11 - f;
        rend.sharedMaterial.SetFloat("_InvFade", d);
    }

    public void setWindx(string x)
    {
        float x_f = float.Parse(x);
        Vector4 old = rend.sharedMaterial.GetVector("_WindDir");
        rend.sharedMaterial.SetVector("_WindDir", new Vector4(x_f, old.y, old.z, old.w));
    }

    public void setWindy(string y)
    {
        float y_f = float.Parse(y);
        Vector4 old = rend.sharedMaterial.GetVector("_WindDir");
        rend.sharedMaterial.SetVector("_WindDir", new Vector4(old.x, y_f, old.z, old.w));
    }

    public void largeFoam(float a)
    {
        rend.sharedMaterial.SetFloat("_FoamIntens", a);
    }


    public void toggleRock()
    {
        display = !display;
        rock.SetActive(display);
    }

}
