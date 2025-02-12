const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const InstructionMode = enum(u2) {
    MemoryMode,
    MemoryMode8bitDisplacement,
    MemoryMode16bitDisplacement,
    RegisterMode,
};

const Registers = enum(u4) { al, ax, cl, cx, dl, dx, bl, bx, ah, sp, ch, bp, dh, si, bh, di };
const OpCodes = enum(u6) {
    mov = 34,
};

fn to_string(comptime T: type, value: T) []const u8 {
    const info = @typeInfo(T);
    if (info != .Enum) {
        @compileError("to_string: Expected an enum type");
    }
    const int_value = @intFromEnum(value);
    inline for (info.Enum.fields) |field| {
        if (int_value == @as(@TypeOf(int_value), field.value)) {
            return field.name;
        }
    }
    unreachable;
}

const Instruction = packed struct {
    r_m: u3,
    reg: u3,
    mod: InstructionMode,
    w: u1,
    d: u1,
    op_code: OpCodes,

    pub fn print(self: Instruction) void {
        std.debug.print("{b:0<8}_{b:0<8} => {b:0<6} {b:<1} {b:<1} {b:0<2} {b:0<3} {b:0<3}\n", .{
            @as(u16, @bitCast(self)) & @as(u16, 0xFF),
            @as(u16, @bitCast(self)) >> 8 & @as(u16, 0xFF),
            @intFromEnum(self.op_code),
            self.d,
            self.w,
            @intFromEnum(self.mod),
            self.reg,
            self.r_m,
        });
    }
};

fn read_data(allocator: Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, File.OpenFlags{ .mode = .read_only });
    defer file.close();

    const file_stats = try file.stat();
    const buffer = try file.readToEndAlloc(allocator, file_stats.size);
    std.debug.assert(buffer.len == file_stats.size);
    return buffer;
}

fn parse_instruction(allocator: Allocator, data: []u8) ![]Instruction {
    if (std.mem.trim(u8, data, " \r\n\t").len & 1 != 0) {
        return error.InvalidInstructionSize;
    }
    const count = @as(f32, @floatFromInt(std.mem.trim(u8, data, " \r\n\t").len)) / 2.0;
    const instructions = try allocator.alloc(Instruction, @intFromFloat(count));
    for (instructions, 0..) |*instr, idx| {
        const raw_value = @as(u16, data[idx * 2]) << 8 | @as(u16, data[idx * 2 + 1]);

        instr.* = @bitCast(raw_value);

        // instr.* = Instruction{
        //     .op_code = @enumFromInt(@as(u6, @intCast((raw_value >> 10) & 0b111111))),
        //     .d = @intCast((raw_value >> 9) & 0b1),
        //     .w = @intCast((raw_value >> 8) & 0b1),
        //     .mod = @enumFromInt((raw_value >> 6) & 0b11),
        //     .reg = @intCast((raw_value >> 3) & 0b111),
        //     .r_m = @intCast(raw_value & 0b111),
        // };
    }
    return instructions;
}

fn disassemble(instructions: []Instruction) void {
    for (instructions) |instr| {
        var source: Registers = undefined;
        var destination: Registers = undefined;
        if (instr.d == 0) {
            destination = @enumFromInt(@as(u4, instr.r_m << 1) + instr.w);
            source = @enumFromInt(@as(u4, instr.reg << 1) + instr.w);
        } else {
            destination = @enumFromInt(@as(u4, instr.reg << 1) + instr.w);
            source = @enumFromInt(@as(u4, instr.r_m << 1) + instr.w);
        }
        std.debug.print("{s} {s}, {s}\n", .{
            to_string(OpCodes, instr.op_code),
            to_string(Registers, destination),
            to_string(Registers, source),
        });
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len == 2) {
        const filename = args[1];

        const data: []u8 = try read_data(allocator, filename);
        defer allocator.free(data);

        const instructions: []Instruction = try parse_instruction(allocator, data);
        defer allocator.free(instructions);

        for (instructions) |instruction| {
            instruction.print();
        }
        // disassemble(instructions);
    } else {
        std.debug.print("Usage: {s} <input_file>", .{args[0]});
    }
}

test "single_instruction" {
    const allocator = std.testing.allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len == 2) {
        const filename = args[1];

        const data: []u8 = try read_data(allocator, filename);
        defer allocator.free(data);

        const instructions: []Instruction = try parse_instruction(allocator, data);
        defer allocator.free(instructions);

        disassemble(instructions);
    } else {
        std.debug.print("Usage: {s} <input_file>", .{args[0]});
    }
}
