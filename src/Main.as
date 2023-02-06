const float TAU = 6.28318530717958647692;

void Main() {
}

bool lastEditorOpen = false;

AnimMgr@ CameraAnimMgr = AnimMgr(true);

/** Called every frame. `dt` is the delta time (milliseconds since last frame).
*/
void Update(float dt) {
    if (!S_Enabled) return;
    UpdateAnimAndCamera();
}

void UpdateAnimAndCamera() {
    if (lastEditorOpen && CameraAnimMgr !is null && !CameraAnimMgr.IsDone && CameraAnimMgr.Update(true)) {
        UpdateCameraProgress(CameraAnimMgr.Progress);
        if (CameraAnimMgr.IsDone) Editor::DisableCustomCameraInputs();
    }
}


void UpdateCameraProgress(float t) {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    // auto cam = editor.OrbitalCameraControl;
    Editor::SetTargetedDistance(Math::Lerp(g_StartingTargetDist, g_EndingTargetDist, t), false);
    Editor::SetTargetedPosition(Math::Lerp(g_StartingPos, g_EndingPos, t), false);
    Editor::SetOrbitalAngle(
        SimplifyRadians(Math::Lerp(g_StartingHAngle, g_EndingHAngle, t)),
        SimplifyRadians(Math::Lerp(g_StartingVAngle, g_EndingVAngle, t))
    );
}

float SimplifyRadians(float a) {
    uint count = 0;
    while (Math::Abs(a) > TAU / 2.0 && count < 100) {
        a += (a < 0 ? 1. : -1.) * TAU;
        count++;
    }
    return a;
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


/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void RenderInterface() {
    if (!S_Enabled) return;
    UpdateAnimAndCamera();
}

/** Called whenever a key is pressed on the keyboard. See the documentation for the [`VirtualKey` enum](https://openplanet.dev/docs/api/global/VirtualKey).
*/
UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (!S_Enabled) return;
    if (down && rebindInProgress) {
        ReportRebindKey(key);
        return UI::InputBlocking::Block;
    }
    if (down && lastEditorOpen && CheckHotKey(key)) {
        // return UI::InputBlocking::Block;
        // for the moment, don't block. it bugs editor inputs (and blocking inputs in general seems non-deterministic based on which plugins are installed)
        return UI::InputBlocking::DoNothing;
    }
    return UI::InputBlocking::DoNothing;
}

bool overrideModeIsRotation = true;

bool CheckHotKey(VirtualKey k) {
    if (k == S_FrontView) return OnFrontView();
    if (k == S_SideView) return OnSideView();
    if (k == S_TopDownView) return OnTopDownView();
    if (k == S_FlipAxis) return OnRotate180();
    if (S_OverrideGameCamControls) {
        if (k == VirtualKey::Numpad4) return OnNumpad4();
        if (k == VirtualKey::Numpad6) return OnNumpad6();
        if (k == VirtualKey::Numpad2) return OnNumpad2();
        if (k == VirtualKey::Numpad8) return OnNumpad8();
        if (k == VirtualKey::Numpad5) return OnNumpad5();
        if (k == VirtualKey::OemPlus) return OnOemPlus();
        if (k == VirtualKey::OemMinus) return OnOemMinus();
    }
    return false;
}

bool OnOemPlus() {
    return SetAnimationDistance(DestOrCurrentTargetDist() * (S_NearFar));
}
bool OnOemMinus() {
    return SetAnimationDistance(DestOrCurrentTargetDist() / (S_NearFar));
}

bool OnNumpad5() {
    overrideModeIsRotation = S_EnableAltToggle ? !overrideModeIsRotation : true;
    return true;
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
bool OnRotate180() {
    auto c = DestOrCurrentOrientation();
    return SetAnimationGoTo(c * vec2(1, 1) + vec2(2, 0));
}

bool TurnH(float amt) {
    auto c = DestOrCurrentOrientation();
    if (S_RotationAlign) c.x = Math::Round(c.x * 90. / S_RotationHAmount) * S_RotationHAmount / 90.;
    SetAnimationGoTo(c + vec2(amt, 0));
    return true;
}

bool TurnV(float amt) {
    auto c = DestOrCurrentOrientation();
    if (S_RotationAlign) c.y = Math::Round(c.y * 90. / S_RotationVAmount) * S_RotationVAmount / 90.;
    SetAnimationGoTo(c + vec2(0, amt));
    return true;
}

bool MoveCam(float fwdAmt, float sideAmt, int numpadNumber) {
    vec4 moveAmt(fwdAmt, 0, sideAmt, 0);
    bool lr = numpadNumber == 4 || numpadNumber == 6;
    bool ud = numpadNumber == 2 || numpadNumber == 8;
    cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType.EnableEditorInputsCustomProcessing = true;
    auto c = DestOrCurrentOrientation();
    moveAmt = mat4::Rotate(c.x * TAU / 4.0, vec3(0, 1, 0)) * moveAmt;
    SetAnimationGoTo(c, DestOrTargetedPosition() + moveAmt.xyz);
    return true;
}

bool OnNumpad4() {
    if (overrideModeIsRotation)
        return TurnH(-1.0 * S_RotationHAmount / 90.0);
    return MoveCam(1.0 * S_MovementAmount * 32.0, 0, 4);
}

bool OnNumpad6() {
    if (overrideModeIsRotation)
        return TurnH(1.0 * S_RotationHAmount / 90.0);
    return MoveCam(-1.0 * S_MovementAmount * 32.0, 0, 6);
}

bool OnNumpad2() {
    if (overrideModeIsRotation)
        return TurnV(-1.0 * S_RotationVAmount / 90.0);
    return MoveCam(0, -1.0 * S_MovementAmount * 32.0, 2);
}

bool OnNumpad8() {
    if (overrideModeIsRotation)
        return TurnV(1.0 * S_RotationVAmount / 90.0);
    return MoveCam(0, 1.0 * S_MovementAmount * 32.0, 8);
}

bool cancelLeftFirst = true;


vec2 DestOrCurrentOrientation() {
    return CameraAnimMgr.IsDone ? CurrentOrientation() : (vec2(g_EndingHAngle, g_EndingVAngle) / TAU * 4.0);
}

vec2 CurrentOrientation() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    float h = editor.OrbitalCameraControl.m_CurrentHAngle;
    float v = editor.OrbitalCameraControl.m_CurrentVAngle;
    return vec2(h, v) / TAU * 4.0;
}

vec3 DestOrTargetedPosition() {
    return CameraAnimMgr.IsDone ? CurrentTargetedPosition() : g_EndingPos;
}

vec3 CurrentTargetedPosition() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    return editor.OrbitalCameraControl.m_TargetedPosition;
}

float DestOrCurrentTargetDist() {
    return CameraAnimMgr.IsDone ? CurrentTargetDist() : g_EndingTargetDist;
}

float CurrentTargetDist() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    return editor.OrbitalCameraControl.m_CameraToTargetDistance;
}


void OffsetAnimAngles() {
    g_StartingHAngle += TAU;
    g_StartingVAngle += TAU;
    g_EndingHAngle += TAU;
    g_EndingVAngle += TAU;
}


float g_StartingHAngle = 0;
float g_StartingVAngle = 0;
float g_EndingHAngle = 0;
float g_EndingVAngle = 0;
float g_StartingTargetDist = 0;
float g_EndingTargetDist = 0;
vec3 g_StartingPos();
vec3 g_EndingPos();

bool SetAnimationDistance(float targetDist) {
    return SetAnimationGoTo(DestOrCurrentOrientation(), DestOrTargetedPosition(), targetDist);
}

bool SetAnimationGoTo(vec2 lookAngleUV) {
    return SetAnimationGoTo(lookAngleUV, DestOrTargetedPosition());
}

bool SetAnimationGoTo(vec2 lookAngleUV, vec3 position) {
    return SetAnimationGoTo(lookAngleUV, position, DestOrCurrentTargetDist());
}

bool SetAnimationGoTo(vec2 lookAngleUV, vec3 position, float targetDist) {
    Editor::EnableCustomCameraInputs();
    @CameraAnimMgr = AnimMgr(false, S_AnimationDuration);
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto cam = editor.OrbitalCameraControl;
    g_StartingHAngle = cam.m_CurrentHAngle;
    g_StartingVAngle = cam.m_CurrentVAngle;
    g_StartingPos = cam.m_TargetedPosition;
    g_StartingTargetDist = cam.m_CameraToTargetDistance;
    g_EndingHAngle = lookAngleUV.x * TAU / 4.0;
    g_EndingVAngle = lookAngleUV.y * TAU / 4.0;
    g_EndingPos = position;
    g_EndingTargetDist = targetDist;
    return true;
}

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}
