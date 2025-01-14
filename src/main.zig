const std = @import("std");
const fs = std.fs;
const process = std.process;
const fmt = std.fmt;
const Allocator = std.mem.Allocator;
const log = std.log;
const Dir = std.fs.Dir;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args = try process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip the program name
    _ = args.next();

    const base_repo_url = args.next() orelse {
        log.info("Error: Base repo URL is required\n", .{});
        return error.MissingArgument;
    };
    const new_repo_path = args.next() orelse {
        log.info("Error: New repo path is required\n", .{});
        return error.MissingArgument;
    };

    // Clone the base repository
    log.info("Cloning base repository", .{});
    try cloneRepo(base_repo_url, new_repo_path, allocator);

    // Initialize the new git repository
    try reInitRepo(new_repo_path, allocator);

    log.info("New repository created successfully ", .{});
}

fn cloneRepo(url: []const u8, path: []const u8, allocator: Allocator) !void {
    const argv = [_][]const u8{ "git", "clone", "--depth", "1", url, path };
    try exec(&argv, allocator);
}

fn reInitRepo(path: []const u8, allocator: Allocator) !void {
    var original_cwd = fs.cwd();

    // Create the new repository directory if it doesn't exist
    var dest_dir = try original_cwd.makeOpenPath(path, .{});
    defer dest_dir.close();

    // Change to the new directory
    try dest_dir.setAsCwd();

    // Remove the .git directory
    log.info("Removing old git repo and initializing new one", .{});
    try dest_dir.deleteTree(".git");

    // git init
    const init = [_][]const u8{ "git", "init" };
    try exec(&init, allocator);

    // git add .
    const add = [_][]const u8{ "git", "add", "." };
    try exec(&add, allocator);

    // git commit -m "Initial commit"
    const commit = [_][]const u8{ "git", "commit", "-m", "Initial commit" };
    try exec(&commit, allocator);
}

fn exec(argv: []const []const u8, allocator: Allocator) !void {
    var child = std.process.Child.init(argv, allocator);
    try child.spawn();
    _ = try child.wait();
}
