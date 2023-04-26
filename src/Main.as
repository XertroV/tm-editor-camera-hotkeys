const float TAU = 6.28318530717958647692;

void Main() {
    startnew(WatchEditorAndValues);
}

bool lastEditorOpen = false;

void WatchEditorAndValues() {
    while (true) {
        yield();
        if (lastEditorOpen != (cast<CGameCtnEditorFree>(GetApp().Editor) !is null)) {
            lastEditorOpen = !lastEditorOpen;
        }
    }
}

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
    Editor::SetTargetedDistance(Math::Lerp(g_StartingTargetDist, g_EndingTargetDist, t));
    Editor::SetTargetedPosition(Math::Lerp(g_StartingPos, g_EndingPos, t));
    Editor::SetOrbitalAngle(
        SimplifyRadians(AngleLerp(g_StartingHAngle, g_EndingHAngle, t)),
        SimplifyRadians(AngleLerp(g_StartingVAngle, g_EndingVAngle, t))
    );
}

float AngleLerp(float start, float stop, float t) {
    float diff = stop - start;
    while (diff > Math::PI) { diff -= TAU; }
    while (diff < -Math::PI) { diff += TAU; }
    return start + diff * t;
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

enum MouseBtn {
    Left = 0,
    Right = 1,
    Middle = 2
}

/** Called whenever a mouse button is pressed. `x` and `y` are the viewport coordinates.
*/
UI::InputBlocking OnMouseButton(bool down, int button, int x, int y) {
    // 0: left, 1: right, 2: mid
    // trace('' + button + ' ' + down);
    if (S_CtrlRightClickToFocus && down && button == int(MouseBtn::Right)) {
        OnFocusPickedElement();
    }
    return UI::InputBlocking::DoNothing;
}

string LastPickedBlockIdName;
uint LastPickedBlockRClickTime = 0;
uint lastPBRClickXZPointIx = 0;

void OnFocusPickedElement() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    vec3 targetPos;
    if (editor.PickedBlock !is null) {
        bool reClicked = LastPickedBlockIdName == editor.PickedBlock.IdName && (Time::Now - 10000) < LastPickedBlockRClickTime;
        LastPickedBlockIdName = editor.PickedBlock.IdName;
        LastPickedBlockRClickTime = Time::Now;
        // on first click go to midpoint of block
        targetPos = GetCtnBlockMidpoint(editor.PickedBlock);
        if (reClicked) {
            auto midPoint = targetPos;
            auto block = editor.PickedBlock;
            auto blockPos = GetBlockLocation(block);
            // otherwise, go through the XZ edge/face midpoints (for easier freeblock placement)
            lastPBRClickXZPointIx = (lastPBRClickXZPointIx + 1) % 8;
            // want to go something like corner, edge, corner, edge...
            bool corner = lastPBRClickXZPointIx & 0x1 == 1;
            uint dirIx = lastPBRClickXZPointIx >> 1;
            auto size = GetBlockSize(block);
            auto angle = CardinalDirectionToYaw(dirIx);
            // do offsets in (-.5,.5) for rotations, and (0,1) for multiplying by size so this works for non-square blocks
            vec3 offset = corner ? vec3(-.5, 0, -.5) : vec3(-.5, 0, 0);
            offset = (mat4::Rotate(angle, vec3(0, 1, 0)) * offset).xyz + vec3(.5);
            targetPos = (GetBlockMatrix(block) * (size * offset)).xyz;
        }
    } else if (editor.PickedObject !is null) {
        targetPos = editor.PickedObject.AbsolutePositionInMap;
    } else {
        return;
    }

    auto camPos = editor.OrbitalCameraControl.Pos;
    auto dir = (targetPos - camPos).Normalized();
    SetAnimationGoTo(DirToLookUv(dir), targetPos, S_CameraFocusDistance);
}


vec2 DirToLookUv(vec3 &in dir) {
    auto xz = (dir * vec3(1, 0, 1)).Normalized();
    auto pitch = -Math::Asin(Math::Dot(dir, vec3(0, 1, 0)));
    auto yaw = Math::Asin(Math::Dot(xz, vec3(1, 0, 0)));
    if (Math::Dot(xz, vec3(0, 0, -1)) > 0) {
        yaw = - yaw - Math::PI;
        // trace('alt case');
    }
    auto lookUv = vec2(yaw, pitch) / Math::PI * 2.;
    return lookUv;
}


/** Called whenever a key is pressed on the keyboard. See the documentation for the [`VirtualKey` enum](https://openplanet.dev/docs/api/global/VirtualKey).
*/
UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (!S_Enabled) return UI::InputBlocking::DoNothing;
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
    return SetAnimationDistance(DestOrCurrentTargetDist() / (S_NearFar));
}
bool OnOemMinus() {
    return SetAnimationDistance(DestOrCurrentTargetDist() * (S_NearFar));
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


uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    return memberTy.Offset;
}
