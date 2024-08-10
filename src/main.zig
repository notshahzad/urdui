const std = @import("std");
const virtMach = @import("./vm.zig");
const instructions = @import("./inst.zig");
const Instructions = instructions.Instruction;
const ax = 0;
const bx = 1;
const cx = 2;
const dx = 3;
//calculates the first 20 digit of fibonacci
var program = [_]instructions.Instruction{
    .{ .pushi = 0 },
    .{ .pushi = 1 },
    .{ .movi = Instructions.create_movi_inst(cx, 18) }, //loop upper bound
    .{ .movi = Instructions.create_movi_inst(dx, 0) }, // lower bound

    //copy first 2 elements in the register
    .{ .pushr = bx },
    .{ .pushr = ax },
    .{ .popr = ax },
    .{ .popr = bx },

    //add elements in the register and put it back on stack
    .{ .add = ax << 2 | bx },
    .{ .popr = ax },

    //check if loop ended and jump if not
    .{ .decr = cx },
    .{ .cmp = cx << 2 | dx },
    .{ .jmpnzi = 4 },

    .halt,
};

pub fn main() !void {
    var vm = virtMach.virtualMachine.init();
    try vm.load_program_from_memory(&program);
    try vm.run();
    vm.print_stack();
}
