const std = @import("std");
pub const Instruction = union(enum) {
    lota: i32,
    lotn: u2, //TODO: this doesn't look good
    khechr: u2, //TODO: support khechi i guess?
    hilaa: u34,
    jama: u4,
    waza: u4,
    taqseem: u4,
    zarab: u4,
    bdha: u2,
    ghta: u2,
    mawazna: u4, //takes 2 registers to compare
    kud0ia: u12,
    kudn0ia: u12,
    kud0ir: u4,
    kudn0ir: u4,
    lotjh,
    khechjh,
    ruk,
    pub fn create_movi_inst(register: u2, data: i32) u34 {
        const reg: u34 = register;
        return reg << 32 | data;
    }
    pub fn from_string(str: []const u8) Instruction {
        inline for (std.meta.fields(Instruction)) |variant| {
            if (variant.type == void and std.mem.eql(u8, variant.name, str)) {
                return @field(Instruction, variant.name);
            }
        }
        return .ruk;
    }
};
