pub const packages = struct {
    pub const @"zap-0.9.1-GoeB85JTJAADY1vAnA4lTuU66t6JJiuhGos5ex6CpifA" = struct {
        pub const build_root = "/home/mgarce/.cache/zig/p/zap-0.9.1-GoeB85JTJAADY1vAnA4lTuU66t6JJiuhGos5ex6CpifA";
        pub const build_zig = @import("zap-0.9.1-GoeB85JTJAADY1vAnA4lTuU66t6JJiuhGos5ex6CpifA");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "zap", "zap-0.9.1-GoeB85JTJAADY1vAnA4lTuU66t6JJiuhGos5ex6CpifA" },
};
