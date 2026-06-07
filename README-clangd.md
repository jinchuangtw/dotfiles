# clangd Setup SOP for CMake, catkin, and PlatformIO Projects

This note is written for a Neovim + clangd workflow. The key idea is simple:

> **clangd does not guess how your C++ project is built. It needs `compile_commands.json` to understand include paths, macros, C++ standard, compiler flags, and source files.**

---

## 0. Prerequisite: Use a modern clangd

Use a recent clangd version, such as `clangd-18`. Older versions may fail on embedded, cross-compiled, or modern C++ projects.

```bash
which clangd-18
clangd-18 --version
```

In [JVim](https://github.com/jinchuangtw/JVim.git), the clangd config is usually located at:

```bash
~/.config/nvim/lua/jvim/lsp/config/clangd.lua
```

The `cmd` entry should explicitly use:

```lua
"clangd-18",
```

---

## 1. Regular CMake Projects

Use this when the repository root contains:

```text
CMakeLists.txt
```

### Initial setup

```bash
cd <project-root>

cmake -S . -B build \
  -G Ninja \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_BUILD_TYPE=Debug

cmake --build build

ln -sf build/compile_commands.json compile_commands.json
```

### Open Neovim

```bash
cd <project-root>
nvim .
```

Inside Neovim, check:

```vim
:LspInfo
```

Confirm that you see:

```text
server: clangd
cmd: clangd-18 ...
root directory: <project-root>
```

---

## 2. If the README already provides CMake commands

Keep the original CMake options from the README. Only add:

```bash
-DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

For example, if the README says:

```bash
cmake -S . -B build -DUSE_CUDA=ON -DBUILD_TESTS=OFF
```

Use:

```bash
cmake -S . -B build \
  -G Ninja \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_BUILD_TYPE=Debug \
  -DUSE_CUDA=ON \
  -DBUILD_TESTS=OFF

cmake --build build
ln -sf build/compile_commands.json compile_commands.json
```

---

## 3. ROS / catkin_make Projects

Some ROS projects are not built by running CMake directly inside the package root. They are built from the `catkin_ws` workspace root with `catkin_make`.

Assume the workspace is:

```bash
~/catkin_ws
```

and the target package is located at:

```bash
~/catkin_ws/src/my_ros_pkg
```

### Generate the compile database from the workspace root

```bash
cd ~/catkin_ws

source /opt/ros/noetic/setup.bash

catkin_make -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

Verify that the file exists:

```bash
ls -lh build/compile_commands.json
```

### Create a symlink in the package root

Use an absolute symlink to avoid relative-path mistakes:

```bash
cd ~/catkin_ws/src/my_ros_pkg

rm -f compile_commands.json
ln -s "$(realpath ~/catkin_ws/build/compile_commands.json)" compile_commands.json

readlink -f compile_commands.json
```

It should point to something like:

```text
/home/<user>/catkin_ws/build/compile_commands.json
```

### Open Neovim from a ROS-sourced shell

```bash
source /opt/ros/noetic/setup.bash
source ~/catkin_ws/devel/setup.bash

cd ~/catkin_ws/src/my_ros_pkg
nvim .
```

Inside Neovim, check:

```vim
:LspInfo
```

---

## 4. Common ROS / catkin_make Issues

### `ros/ros.h` is not found

First check whether the compile database contains the ROS include path:

```bash
grep -o '\-I/opt/ros/noetic/include' ~/catkin_ws/build/compile_commands.json | head
```

If nothing appears, the workspace was probably built without sourcing ROS first:

```bash
cd ~/catkin_ws
source /opt/ros/noetic/setup.bash
catkin_make -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

### Generated headers or message headers are not found

Examples:

```text
xxxConfig.h not found
xxx/SomeMsg.h not found
```

Build the workspace once so catkin can generate headers under `devel/include`:

```bash
cd ~/catkin_ws
source /opt/ros/noetic/setup.bash
catkin_make -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
source devel/setup.bash
```

Then open Neovim from the same ROS-sourced shell.

### Broken symlink

Check the symlink:

```bash
cd ~/catkin_ws/src/my_ros_pkg

ls -lh compile_commands.json
readlink compile_commands.json
readlink -f compile_commands.json
test -f compile_commands.json && echo OK || echo BROKEN
```

If it is broken, recreate it:

```bash
rm -f compile_commands.json
ln -s "$(realpath ~/catkin_ws/build/compile_commands.json)" compile_commands.json
```

---

## 5. Makefile-only Projects

If the project has no CMake and only provides a Makefile, use Bear to generate `compile_commands.json`.

```bash
sudo apt install bear

cd <project-root>
make clean
bear -- make -j$(nproc)
```

Verify:

```bash
ls -lh compile_commands.json
```

Then open:

```bash
nvim .
```

---

## 6. PlatformIO / ESP32 Projects

PlatformIO projects are not regular CMake projects. If the project root contains:

```text
platformio.ini
```

generate the compile database with:

```bash
pio run -t compiledb
```

If clangd needs full toolchain include paths, create `extra_script.py` in the project root:

```python
import os
Import("env")

env.Replace(COMPILATIONDB_INCLUDE_TOOLCHAIN=True)
env.Replace(COMPILATIONDB_PATH=os.path.join("$PROJECT_DIR", "compile_commands.json"))
```

Then add this to the relevant environment section in `platformio.ini`:

```ini
extra_scripts = pre:extra_script.py
```

For ESP32 projects, keep `--query-driver` in the JVim clangd config so clangd can query the PlatformIO cross compiler.

---

## 7. Project `.clangd` vs Global `~/.config/clangd/config.yaml`

### Recommended rule

Prefer:

```text
compile_commands.json
```

Only add a project-local `.clangd` when absolutely necessary.

Avoid putting unconditional include paths in:

```bash
~/.config/clangd/config.yaml
```

because this global config applies to all C/C++ projects and may pollute unrelated projects.

### What to do with an old global config

If the old global config looks like this:

```yaml
CompileFlags:
  Add:
    - "--include-directory=/usr/local/include"
    - "--include-directory=/usr/include"
    - "--include-directory=/usr/include/eigen3"
    - "--include-directory=/opt/ros/noetic/include"
    - "--include-directory=/usr/local/include/pcl-1.11"
```

do not keep it as an unconditional global setting. Back it up and disable it:

```bash
mv ~/.config/clangd/config.yaml ~/.config/clangd/config.yaml.bak
```

If a global config is truly needed later, restrict it with `If: PathMatch`, for example only for a ROS workspace:

```yaml
If:
  PathMatch: /home/<user>/catkin_ws/.*
CompileFlags:
  Add:
    - -I/opt/ros/noetic/include
```

However, if `catkin_make -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` correctly generates a compile database, this global include-path workaround is usually unnecessary.

---

## 8. Decision Flow for Newly Cloned C++ Projects

```text
If you see CMakeLists.txt
  → Use cmake with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

If you see catkin_ws / package.xml / a ROS package
  → Build from the catkin_ws root with catkin_make -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

If you see platformio.ini
  → Use pio run -t compiledb

If you only see a Makefile
  → Use bear -- make

If clangd still reports errors
  → Check :LspInfo first
  → Confirm root directory and clangd-18
  → Check :LspLog
  → Confirm compile_commands.json actually contains the relevant .cpp file
```

---

## 9. Quick Checks

### Check whether the compile database exists

```bash
ls -lh compile_commands.json
```

### Check whether a source file is included in the compile database

```bash
grep -n "your_file.cpp" compile_commands.json | head
```

### Check clangd version

```bash
clangd-18 --version
```

### Check inside Neovim

```vim
:LspInfo
:LspLog
```

---

## 10. Minimal Commands to Remember

### Regular CMake

```bash
cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ln -sf build/compile_commands.json compile_commands.json
nvim .
```

### my_ros_pkg / catkin_make

```bash
cd ~/catkin_ws
source /opt/ros/noetic/setup.bash
catkin_make -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cd ~/catkin_ws/src/my_ros_pkg
rm -f compile_commands.json
ln -s "$(realpath ~/catkin_ws/build/compile_commands.json)" compile_commands.json

source ~/catkin_ws/devel/setup.bash
nvim .
```
