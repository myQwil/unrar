# unrar

This is [UnRAR](https://www.rarlab.com/rar_add.htm),
packaged for [Zig](https://ziglang.org/).

## How to use it

First, update your `build.zig.zon`:

```
zig fetch --save https://github.com/myQwil/unrar/archive/refs/heads/main.tar.gz
```

Next, add this snippet to your `build.zig` script:

```zig
const unrar_dep = b.dependency("unrar", .{
    .target = target,
    .optimize = optimize,
});
```

From here, you can add it to `your_compilation`, either as a library or a module.

### As a library
```zig
your_compilation.linkLibrary(unrar_dep.artifact("unrar"));
```

### As a module
```zig
your_compilation.root_module.addImport("unrar", unrar_dep.module("unrar")),
```
