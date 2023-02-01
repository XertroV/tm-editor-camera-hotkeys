namespace Editor {
    // main waypoints

    bool refreshing = false;
    void Refresh() {
        if (refreshing) return;
        refreshing = true;
        refreshing = false;
    }

    void SetTargetedPosition(vec3 pos, bool updateCam = true) {
        cast<CGameCtnEditorFree>(GetApp().Editor).OrbitalCameraControl.m_TargetedPosition = pos;
        if (updateCam) UpdateCamera();
    }

    void SetOrbitalAngle(float h, float v, bool updateCam = true) {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.OrbitalCameraControl.m_CurrentHAngle = h;
        editor.OrbitalCameraControl.m_CurrentVAngle = v;
        if (updateCam) UpdateCamera();
    }

    void UpdateCamera() {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        auto origPSZP = editor.OrbitalCameraControl.m_ParamScrollZoomPower;
        editor.OrbitalCameraControl.m_ParamScrollZoomPower = 0;
        editor.ButtonZoomInOnClick();
        editor.OrbitalCameraControl.m_ParamScrollZoomPower = origPSZP;
    }
}
