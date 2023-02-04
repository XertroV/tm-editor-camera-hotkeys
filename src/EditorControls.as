namespace Editor {
    bool refreshing = false;
    void Refresh() {
        if (refreshing) return;
        refreshing = true;
        refreshing = false;
    }

    void EnableCustomCameraInputs() {
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.EnableEditorInputsCustomProcessing = true;
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.Camera.IgnoreCameraCollisions(true);
        cast<CGameCtnEditorFree>(GetApp().Editor).OrbitalCameraControl.m_MaxVAngle = TAU * 100;
        cast<CGameCtnEditorFree>(GetApp().Editor).OrbitalCameraControl.m_MinVAngle = -TAU * 100;
    }

    void DisableCustomCameraInputs() {
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.EnableEditorInputsCustomProcessing = false;
    }

    void SetTargetedPosition(vec3 pos, bool updateCam = true) {
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.CameraTargetPosition = pos;
    }

    void SetTargetedDistance(float dist, bool updateCam = true) {
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.CameraToTargetDistance = dist;
        // if (updateCam) UpdateCamera();
    }

    void SetOrbitalAngle(float h, float v, bool updateCam = true) {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.PluginMapType.CameraHAngle = h;
        editor.PluginMapType.CameraVAngle = v;
        // if (updateCam) UpdateCamera();
    }

    // void UpdateCamera() {
    //     auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    //     auto orbital = editor.OrbitalCameraControl;
    //     auto origPSZP = editor.OrbitalCameraControl.m_ParamScrollZoomPower;
    //     editor.OrbitalCameraControl.m_ParamScrollZoomPower = 0;
    //     editor.ButtonZoomInOnClick();
    //     editor.OrbitalCameraControl.m_ParamScrollZoomPower = origPSZP;
    // }
}
