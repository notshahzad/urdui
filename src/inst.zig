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
    jmpzi: i12,
    jmpnzi: i12,
    jmpzr: u4,
    pushf,
    popf,
    halt,
    pub fn create_movi_inst(register: u2, data: i32) u34 {
        const reg: u34 = register;
        return reg << 32 | data;
    }
};
