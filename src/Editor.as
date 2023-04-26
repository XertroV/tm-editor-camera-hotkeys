// This file taken from Item Placement Toolbox

uint16 FreeBlockPosOffset = GetOffset("CGameCtnBlock", "Dir") + 0x8;
uint16 FreeBlockRotOffset = FreeBlockPosOffset + 0xC;

vec3 GetBlockLocation(CGameCtnBlock@ block) {
    if (int(block.CoordX) < 0) {
        // free block mode
        return Dev::GetOffsetVec3(block, FreeBlockPosOffset);
    }
    // using the coord will not give you a consistent corner of the block (i.e., after rotation), so rotate around the midpoint to get the right position
    auto pos = CoordToPos(block.Coord);
    auto size = GetBlockSize(block);
    auto rot = GetBlockRotation(block);
    return (mat4::Translate(pos) * mat4::Translate(size / 2.) * EulerToMat(rot) * (size / -2.)).xyz;
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
    return -Math::PI/2. * float(dir)  + Math::PI;
}

vec3 CoordToPos(nat3 coord) {
    return vec3(coord.x * 32, (int(coord.y) - 8) * 8, coord.z * 32);
}

vec3 GetBlockSize(CGameCtnBlock@ block) {
    // todo: check for bivIx > 0 -- what happens in this case? (and what block to use)
    auto bivIx = block.BlockInfoVariantIndex;
    auto bi = block.BlockInfo;
    // mb use .VariantBaseX instead
    CGameCtnBlockInfoVariant@ biv = block.IsGround ? cast<CGameCtnBlockInfoVariant>(bi.VariantGround) : cast<CGameCtnBlockInfoVariant>(bi.VariantAir);
    return vec3(biv.Size.x * 32, biv.Size.y * 8, biv.Size.z * 32);
}

vec3 GetCtnBlockMidpoint(CGameCtnBlock@ block) {
    return (GetBlockMatrix(block) * (GetBlockSize(block) / 2.)).xyz;
}

mat4 GetBlockMatrix(CGameCtnBlock@ block) {
    return mat4::Translate(GetBlockLocation(block)) * EulerToMat(GetBlockRotation(block));
}
