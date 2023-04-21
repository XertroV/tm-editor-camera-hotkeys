[Setting hidden]
bool S_Enabled = true;

// [Setting category="Hotkeys" name="Front View (Blender: Numpad 1)"]
[Setting hidden]
VirtualKey S_FrontView = VirtualKey::Numpad1;
// [Setting category="Hotkeys" name="Side View (Blender: Numpad 3)"]
[Setting hidden]
VirtualKey S_SideView = VirtualKey::Numpad3;
// [Setting category="Hotkeys" name="Top Down View (Blender: Numpad 7)"]
[Setting hidden]
VirtualKey S_TopDownView = VirtualKey::Numpad7;
// [Setting category="Hotkeys" name="Rotate 180 around Y (Blender: Numpad 9)"]
[Setting hidden]
VirtualKey S_FlipAxis = VirtualKey::Numpad9;

[Setting category="Camera" name="Animation Duration (ms)" min=0 max=1000.0]
float S_AnimationDuration = 150.0;

[Setting category="Camera" name="Override Editor Cam Controls (Numpad 2,4,6,8)"]
bool S_OverrideGameCamControls = true;

[Setting category="Camera" name="Numpad 4,6: H Rotate (degrees)" description="90 => Rotate 1/4 each time. 45 => Rotate 1/8 each time."]
float S_RotationHAmount = 90.0;

[Setting category="Camera" name="Numpad 2,8: V Rotate (degrees)" description="90 => Rotate 1/4 each time. 45 => Rotate 1/8 each time."]
float S_RotationVAmount = 45.0;

[Setting category="Camera" name="Rotate-align to Standard Angles" description="If rotation amount is 90 degrees, the camera will rotate only to 0, 90, 180, or 270 degrees. These are the 'standard' angles. When disabled, rotation will always be +- X degress."]
bool S_RotationAlign = true;

[Setting category="Camera" name="Toggle Alt controls with Numpad 5" description="Toggles between rotation and XZ movement."]
bool S_EnableAltToggle = true;

[Setting category="Camera" name="Alt Numpad 2,4,6,8: Step Size (blocks)" description="How many blocks to move when override mode is set to move instead of rotate."]
float S_MovementAmount = 3.0;

[Setting category="Camera" min=1.0 max=5.0 name="Main KB +/-: Near/Far Zoom Ratio" description="If set to 2.0, pressing + will reduce your distance by 50% (zoom), pressing - will increase it by 100% (unzoom)."]
float S_NearFar = 2.0;

[Setting category="Camera" name="Ctrl+Right Click to Focus Blocks/Items (overrides game)" description="When set, ctrl+right click acts like Blenders focus function ('.' on the numpad)."]
bool S_CtrlRightClickToFocus = true;

[Setting category="Camera" name="Camera Focus Distance" description="How far ctrl+right click will set the camera from the block/item."]
float S_CameraFocusDistance = 96.;


[SettingsTab name="Editor Camera Hotkeys" icon="Th" order="1"]
void S_MainTab() {
    if (UI::BeginTable("bindings", 3, UI::TableFlags::SizingStretchSame)) {
        UI::TableSetupColumn("Key", UI::TableColumnFlags::WidthStretch, 1.1);
        UI::TableSetupColumn("Binding", UI::TableColumnFlags::WidthStretch, .3f);
        UI::TableSetupColumn("", UI::TableColumnFlags::WidthStretch, 1.3);
        UI::TableHeadersRow();

        S_FrontView = DrawKeyBinding("Front View (Blender: Numpad 1)", S_FrontView);
        S_SideView = DrawKeyBinding("Side View (Blender: Numpad 3)", S_SideView);
        S_TopDownView = DrawKeyBinding("Top Down View (Blender: Numpad 7)", S_TopDownView);
        S_FlipAxis = DrawKeyBinding("Rotate 180 around Y (Blender: Numpad 9)", S_FlipAxis);

        UI::EndTable();
    }
    UI::Separator();

}

string activeKeyName;
VirtualKey tmpKey;
bool gotNextKey = false;
bool rebindInProgress = false;
bool rebindAborted = false;
VirtualKey DrawKeyBinding(const string &in name, VirtualKey &in valIn) {
    bool amActive = rebindInProgress && activeKeyName == name;
    bool amDone = (rebindAborted || gotNextKey) && !rebindInProgress && activeKeyName == name;
    UI::PushID(name);

    UI::TableNextRow();
    UI::TableNextColumn();
    UI::AlignTextToFramePadding();
    UI::Text(name);

    UI::TableNextColumn();
    UI::Text(tostring(valIn));

    UI::TableNextColumn();
    UI::BeginDisabled(rebindInProgress);
    if (UI::Button("Rebind")) StartRebind(name);
    UI::EndDisabled();

    UI::PopID();
    if (amActive) {
        UI::SameLine();
        UI::Text("Press a key to bind, or Esc to cancel.");
    }
    if (amDone) {
        if (gotNextKey) {
            ResetBindingState();
            return tmpKey;
        } else {
            UI::SameLine();
            UI::Text("\\$888Rebind aborted.");
        }
    }
    return valIn;
}

void ResetBindingState() {
    rebindInProgress = false;
    activeKeyName = "";
    gotNextKey = false;
    rebindAborted = false;
}

void StartRebind(const string &in name) {
    if (rebindInProgress) return;
    rebindInProgress = true;
    activeKeyName = name;
    gotNextKey = false;
    rebindAborted = false;
}

void ReportRebindKey(VirtualKey key) {
    if (!rebindInProgress) return;
    if (key == VirtualKey::Escape) {
        rebindInProgress = false;
        rebindAborted = true;
    } else {
        rebindInProgress = false;
        gotNextKey = true;
        tmpKey = key;
    }
}
