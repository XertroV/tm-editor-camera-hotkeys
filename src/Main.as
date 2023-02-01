const float TAU = 6.28318530717958647692;

void Main() {
    startnew(WatchEditorAndValues);
}

bool lastEditorOpen = false;
uint lastVertexCount = 0;

UI::Font@ largerFont = UI::LoadFont("DroidSans.ttf", 20.0);
UI::Font@ regularFont = UI::LoadFont("DroidSans.ttf", 16.0, -1, -1, true, true, true);

void WatchEditorAndValues() {
    while (true) {
        yield();
        if (lastEditorOpen != (cast<CGameCtnEditorFree>(GetApp().Editor) !is null)) {
            lastEditorOpen = !lastEditorOpen;
            if (lastEditorOpen)
                // do this in a coro so we update vertex count first.
                startnew(Editor::Refresh);
        }
        if (lastEditorOpen) {
            auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
            // editor.OrbitalCameraControl.m_CurrentVAngle = 3.14159 / 2.0 * ((Math::Sin(float(Time::Now) / 10000.0) * .5 + .5));
            // Editor::UpdateCamera();
        }
    }
}

AnimMgr@ CameraAnimMgr = null;

/** Called every frame. `dt` is the delta time (milliseconds since last frame).
*/
void Update(float dt) {
    if (lastEditorOpen && CameraAnimMgr !is null && CameraAnimMgr.Update(true)) {
        UpdateCameraProgress(CameraAnimMgr.Progress);
        if (CameraAnimMgr.Progress >= 1.0) {
            @CameraAnimMgr = null;
        }
    }
}


void UpdateCameraProgress(float t) {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto cam = editor.OrbitalCameraControl;
    Editor::SetOrbitalAngle(
        Math::Lerp(g_StartingHAngle, g_EndingHAngle, t),
        Math::Lerp(g_StartingVAngle, g_EndingVAngle, t)
    );
}


void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

const string PluginIcon = Icons::Kenney::StickMoveBtAlt;
const string MenuTitle = "\\$f61" + PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

// show the window immediately upon installation
[Setting hidden]
bool ShowWindow = true;

/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}

void Render() {
    if (!ShowWindow) return;
    if (UI::Begin(Meta::ExecutingPlugin().Name, ShowWindow)) {
        if (UI::Button("Test Angles: Set Current")) TestAnglesSetCurrent();
    }
    UI::End();
}

/** Called whenever a key is pressed on the keyboard. See the documentation for the [`VirtualKey` enum](https://openplanet.dev/docs/api/global/VirtualKey).
*/
UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (down && lastEditorOpen && CheckHotKey(key))
        // return UI::InputBlocking::Block;
        // for the moment, don't block. it bugs editor inputs (and blocking inputs in general seems non-deterministic based on which plugins are installed)
        return UI::InputBlocking::DoNothing;
    return UI::InputBlocking::DoNothing;
}

bool CheckHotKey(VirtualKey k) {
    if (k == S_FrontView) return OnFrontView();
    if (k == S_SideView) return OnSideView();
    if (k == S_TopDownView) return OnTopDownView();
    if (k == S_FlipAxis) return OnFlipAxis();
    return false;
}

bool OnFrontView() {
    return SetAnimationGoTo(vec2(2, 0));
}
bool OnSideView() {
    return SetAnimationGoTo(vec2(1, 0));
}
bool OnTopDownView() {
    return SetAnimationGoTo(vec2(0, 1));
}
bool OnFlipAxis() {
    auto c = CameraAnimMgr is null ? CurrentOrientation() : (vec2(g_EndingHAngle, g_EndingVAngle) / TAU * 4.0);
    return SetAnimationGoTo(c * vec2(1, -1) + vec2(2, 0));
}

vec2 CurrentOrientation() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    float h = editor.OrbitalCameraControl.m_CurrentHAngle;
    float v = editor.OrbitalCameraControl.m_CurrentVAngle;
    return vec2(h, v) / TAU * 4.0;
}

float g_StartingHAngle = 0;
float g_StartingVAngle = 0;
float g_EndingHAngle = 0;
float g_EndingVAngle = 0;

bool SetAnimationGoTo(vec2 lookAngleUV) {
    @CameraAnimMgr = AnimMgr(false, S_AnimationDuration);
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto cam = editor.OrbitalCameraControl;
    g_StartingHAngle = cam.m_CurrentHAngle;
    g_StartingVAngle = cam.m_CurrentVAngle;
    g_EndingHAngle = lookAngleUV.x * TAU / 4.0;
    g_EndingVAngle = lookAngleUV.y * TAU / 4.0;
    return true;
}

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}
