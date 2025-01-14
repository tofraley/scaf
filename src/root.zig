const Dir = std.fs.Dir;
const Allocator = std.mem.Allocator;
const log = std.log;

fn copyDir(src: Dir, dest: Dir, allocator: Allocator) !void {
    // Iterate through the source directory
    var iterator = src.iterate();
    while (try iterator.next()) |entry| {
        if (entry.kind == .directory) {
            // Open the source directory
            var src_sub_dir = try src.openDir(entry.name, .{ .iterate = true });
            defer src_sub_dir.close();

            // Create and open the destination directory
            var dest_sub_dir = try dest.makeOpenPath(entry.name, .{});
            defer dest_sub_dir.close();

            // Recursively copy the subdirectory
            try copyDir(src_sub_dir, dest_sub_dir, allocator);
        } else if (entry.kind == .file) {
            // Open the source file
            const source_file = try src.openFile(entry.name, .{});
            defer source_file.close();

            // Create the destination file
            const dest_file = try dest.createFile(entry.name, .{});
            defer dest_file.close();

            // Get the file size
            const file_size = try source_file.getEndPos();

            // Copy the contents
            const bytes_copied = try source_file.copyRange(0, dest_file, 0, file_size);

            if (bytes_copied != file_size) {
                log.warn("Copied {} bytes out of {} for file: {s}\n", .{ bytes_copied, file_size, entry.name });
            } else {
                log.info("Copied file: {s} ({} bytes)\n", .{ entry.name, file_size });
            }
        }
    }
}
