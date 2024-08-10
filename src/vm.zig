const instruction = @import("inst.zig");
const std = @import("std");
const assert = std.debug.assert;
const STACK_SIZE = 1024 * 64;
const RAM_SIZE = 1024 * 4;
const MAX_INST_BOUND = 1024 * 1024; //supports 1m instructions max at this time
const vmError = error{
    programMissingHalt,
    halted,
    Exhausted,
};
const ax = 0;
const bx = 1;
const cx = 2;
const dx = 3;

// flags  [0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0][0]
//                                                                                                      z

pub const virtualMachine = struct {
    ip: u12 = 0,
    sp: u16 = 0,
    bp: u16 = 0,
    hlt: bool = false,
    gpr: [4]i32 = undefined, //general purpose registers
    flag_register: i32 = 0, //32bit flag register
    stack: [STACK_SIZE / 4]i32 = undefined,
    text: [RAM_SIZE]instruction.Instruction = undefined,

    pub fn init() virtualMachine {
        return virtualMachine{};
    }
    pub fn program_contains(self: *virtualMachine, inst: instruction.Instruction) bool { //language so mature that cant do this shit
        var contains = false;
        for (0..self.text.len) |i| {
            if (@intFromEnum(self.text[i]) == @intFromEnum(inst)) {
                contains = true;
            }
        }
        return contains;
    }
    pub fn load_program_from_memory(self: *virtualMachine, program: []instruction.Instruction) !void {
        assert(program.len < RAM_SIZE);
        @memcpy(self.text[0..program.len], program);
        const is_halt = self.program_contains(.halt);
        if (!is_halt) {
            std.debug.print("error: program should contain halt instruction\n", .{});
            return vmError.programMissingHalt;
        }
    }

    pub fn run(self: *virtualMachine) !void {
        var i: i32 = 0;
        while (self.hlt != true and i < MAX_INST_BOUND) {
            try self.step();
            i += 1;
        }
        if (i == MAX_INST_BOUND) {
            return vmError.Exhausted;
        }
    }
    pub fn step(self: *virtualMachine) !void {
        if (self.hlt == true) {
            return vmError.halted;
        }
        const inst: instruction.Instruction = self.text[@intCast(self.ip)];
        switch (inst) {
            .pushi => |value| {
                assert(self.sp <= self.stack.len);
                self.stack[@intCast(self.sp)] = value;
                self.sp += 1;
                self.ip += 1;
            },
            .popr => |reg| {
                assert(reg >= 0 and reg < 3);
                const value = self.gpr[@intCast(reg)];
                self.stack[@intCast(self.sp)] = value;
                self.sp += 1;
                self.ip += 1;
            },
            .pushr => |reg| {
                assert(reg >= 0 and reg < 3);
                const value = self.stack[@intCast(self.sp - 1)];
                self.gpr[@intCast(reg)] = value;
                self.sp -= 1;
                self.ip += 1;
            },
            .movi => |regs| {
                self.gpr[@intCast(regs >> 32)] = @intCast(regs & 0xffffffff);
                self.ip += 1;
            },
            .add => |regs| {
                const reg1_idx: usize = @intCast(regs >> 2);
                const reg2_idx: usize = @intCast(regs & 0b11);
                const reg1_val = self.gpr[reg1_idx];
                const reg2_val = self.gpr[reg2_idx];
                self.gpr[reg1_idx] = reg1_val + reg2_val;
                self.ip += 1;
            },
            .sub => |regs| {
                const reg1_idx: usize = @intCast(regs >> 2);
                const reg2_idx: usize = @intCast(regs & 0b11);
                const reg1_val = self.gpr[reg1_idx];
                const reg2_val = self.gpr[reg2_idx];
                self.gpr[@intCast(reg1_idx)] = reg1_val - reg2_val;
                self.ip += 1;
            },
            .incr => |reg| {
                self.gpr[@intCast(reg)] += 1;
                self.ip += 1;
            },
            .decr => |reg| {
                self.gpr[@intCast(reg)] -= 1;
                self.ip += 1;
            },
            .div => {
                assert(false and "todo");
                // const ax = self.gpr[ @intCast(@intFromEnum)(register.ax )];
                // const bx = self.gpr[@intCast(@intFromEnum)(register.bx )];
                // self.gpr[@intCast(@intFromEnum)(register.ax )] = ax / bx;
                self.ip += 1;
            },
            .mul => |regs| {
                const reg1_idx: usize = @intCast(regs >> 2);
                const reg2_idx: usize = @intCast(regs & 0b11);
                const reg1_val = self.gpr[reg1_idx];
                const reg2_val = self.gpr[reg2_idx];
                self.gpr[@intCast(reg1_idx)] = reg1_val * reg2_val;
                self.ip += 1;
            },
            .cmp => |regs| {
                const reg1_idx: usize = @intCast(regs >> 2);
                const reg2_idx: usize = @intCast(regs & 0b11);
                const reg1_val = self.gpr[reg1_idx];
                const reg2_val = self.gpr[reg2_idx];
                self.flag_register |= @intFromBool(reg1_val == reg2_val);
                self.ip += 1;
            },
            .jmpnzi => |address| {
                if (self.flag_register & 1 == 1) {
                    self.ip += 1;
                    return;
                }
                self.ip = address;
            },
            .jmpzi => |address| {
                if (self.flag_register & 1 != 1) {
                    self.ip += 1;
                    return;
                }
                self.ip = address;
            },

            .jmpzr => |offset| {
                assert(true); //not implemented
                _ = offset;
            },
            .pushf => {
                const flags = self.stack[@intCast(self.sp - 1)];
                self.flag_register = flags;
                self.sp -= 1;
                self.ip += 1;
            },
            .popf => {
                self.stack[self.sp] = self.flag_register;
                self.sp += 1;
                self.ip += 1;
            },
            .halt => {
                self.hlt = true;
            },
        }
    }
    pub fn print_stack(self: *virtualMachine) void {
        assert(self.sp <= self.stack.len);
        for (0..@intCast(self.sp)) |i| {
            std.debug.print("{d}: {d}\n", .{ i, self.stack[i] });
        }
    }
};
