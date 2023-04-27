// This file taken from Item Placement Toolbox

uint16 FreeBlockPosOffset = GetOffset("CGameCtnBlock", "Dir") + 0x8;
uint16 FreeBlockRotOffset = FreeBlockPosOffset + 0xC;

vec3 GetBlockLocation(CGameCtnBlock@ block) {
    if (int(block.CoordX) < 0) {
        // free block mode
        return Dev::GetOffsetVec3(block, FreeBlockPosOffset);
    }
    // using the coord will not give you a consistent corner of the block (i.e., after rotation),
    // pre-adjust the coordinates to account for this based on cardinal dir
    // rclick in editor always rotates around BL (min x/z);
    auto coord = Nat3ToVec3(block.Coord);
    auto coordSize = GetBlockCoordSize(block);
    if (int(block.Dir) == 1) {
        coord.x += coordSize.z - 1;
    }
    if (int(block.Dir) == 2) {
        coord.x += coordSize.x - 1;
        coord.z += coordSize.z - 1;
    }
    if (int(block.Dir) == 3) {
        coord.z += coordSize.x - 1;
    }
    auto pos = CoordToPos(coord);
    auto sqSize = vec3(32, 8, 32);
    auto rot = GetBlockRotation(block);
    return (mat4::Translate(pos) * mat4::Translate(sqSize / 2.) * EulerToMat(rot) * (sqSize / -2.)).xyz;
}

vec3 GetBlockRotation(CGameCtnBlock@ block) {
    if (int(block.CoordX) < 0) {
        // free block mode
        auto ypr = Dev::GetOffsetVec3(block, FreeBlockRotOffset);
        return vec3(ypr.y, ypr.x, ypr.z);
    }
    return vec3(0, CardinalDirectionToYaw(int(block.Dir)), 0);
}

float CardinalDirectionToYaw(int dir) {
    // n:0, e:1, s:2, w:3
    return -Math::PI/2. * float(dir) + (dir >= 2 ? Math::PI*2 : 0);
}

vec3 Nat3ToVec3(nat3 coord) {
    return vec3(coord.x, coord.y, coord.z);
}
vec3 Int3ToVec3(int3 coord) {
    return vec3(coord.x, coord.y, coord.z);
}

vec3 CoordToPos(nat3 coord) {
    return vec3(coord.x * 32, (int(coord.y) - 8) * 8, coord.z * 32);
}

vec3 CoordToPos(vec3 coord) {
    return vec3(coord.x * 32, (int(coord.y) - 8) * 8, coord.z * 32);
}

vec3 GetBlockSize(CGameCtnBlock@ block) {
    return GetBlockCoordSize(block) * vec3(32, 8, 32);
}

vec3 GetBlockCoordSize(CGameCtnBlock@ block) {
    auto @biv = GetBlockInfoVariant(block);
    return Nat3ToVec3(biv.Size);
}

CGameCtnBlockInfoVariant@ GetBlockInfoVariant(CGameCtnBlock@ block) {
    auto bivIx = block.BlockInfoVariantIndex;
    auto bi = block.BlockInfo;
    CGameCtnBlockInfoVariant@ biv;
    if (bivIx > 0) {
        @biv = block.IsGround ? cast<CGameCtnBlockInfoVariant>(bi.AdditionalVariantsGround[bivIx - 1]) : cast<CGameCtnBlockInfoVariant>(bi.AdditionalVariantsAir[bivIx - 1]);
    } else {
        @biv = block.IsGround ? cast<CGameCtnBlockInfoVariant>(bi.VariantGround) : cast<CGameCtnBlockInfoVariant>(bi.VariantAir);
        if (biv is null) {
            @biv = block.IsGround ? cast<CGameCtnBlockInfoVariant>(bi.VariantBaseGround) : cast<CGameCtnBlockInfoVariant>(bi.VariantBaseAir);
        }
    }
    return biv;
}

vec3 GetCtnBlockMidpoint(CGameCtnBlock@ block) {
    return (GetBlockMatrix(block) * (GetBlockSize(block) / 2.)).xyz;
}

mat4 GetBlockMatrix(CGameCtnBlock@ block) {
    return mat4::Translate(GetBlockLocation(block)) * EulerToMat(GetBlockRotation(block));
}
