namespace Editor {
    void EnableCustomCameraInputs() {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.PluginMapType.EnableEditorInputsCustomProcessing = true;
        editor.PluginMapType.Camera.IgnoreCameraCollisions(true);
        editor.OrbitalCameraControl.m_MaxVAngle = TAU * 100;
        editor.OrbitalCameraControl.m_MinVAngle = -TAU * 100;
        startnew(Editor::DisableCustomCameraInputs);
    }

    void DisableCustomCameraInputs() {
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.EnableEditorInputsCustomProcessing = false;
    }

    void SetTargetedPosition(vec3 pos) {
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.CameraTargetPosition = pos;
    }

    void SetTargetedDistance(float dist) {
        cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.CameraToTargetDistance = dist;
    }

    void SetOrbitalAngle(float h, float v) {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.PluginMapType.CameraHAngle = h;
        editor.PluginMapType.CameraVAngle = v;
    }
}
