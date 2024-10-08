const std = @import("std");
pub const Instruction = union(enum) {
    pushi: i32,
    pushr: u2, //TODO: this doesn't look good
    popr: u2, //TODO: support popi iguess?
    movi: u34,
    add: u4,
    sub: u4,
    div: u4,
    mul: u4,
    incr: u2,
    decr: u2,
    cmp: u4, //takes 2 registers to compare
    jmpzi: u12,
    jmpnzi: u12,
    jmpzr: u4,
    pushf,
    popf,
    halt,
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
