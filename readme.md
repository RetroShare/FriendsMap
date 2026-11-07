# FriendsMap
## Geographic Friend Map
This extension for RetroShare shows your friends on a map or globe.

This product uses GeoLite data created by MaxMind, available from <a href="https://www.maxmind.com">https://www.maxmind.com</a>.

> **Qt version:** the plugin, RetroShare and Marble must all use the **same Qt major version**.
> A Qt 5 RetroShare cannot load a Qt 6 Marble, and the other way round.
>
> | Qt | Marble | Library linked |
> |----|--------|----------------|
> | Qt 6 | current Marble (KDE Gear 24.02 and later) | `libmarblewidget-qt6` |
> | Qt 5 | Marble `release/23.08` (last Qt 5 series) | `libmarblewidget-qt5` |
>
> `FriendMap.pro` picks the right library automatically from the Qt version of the `qmake` you run.

#### Build the main RetroShare project before building this plugin.

---

## Linux (Debian / Ubuntu) — Qt 6

### Dependencies
```bash
sudo apt-get install qt6-base-dev qt6-svg-dev libmarble-dev libgeoip-dev
```
Recent distributions (Debian 13, Ubuntu 25.04 and later) ship Marble built with Qt 6
(`libmarblewidget-qt6`). Check with:
```bash
ls /usr/lib/*/libmarblewidget-qt*
```
If your distribution only has `libmarblewidget-qt5`, build RetroShare and the plugin with Qt 5
instead (use `qmake` / `qmake-qt5` in the steps below).

To build Marble with Qt 6 from source instead:
```bash
git clone https://invent.kde.org/education/marble.git
cd marble && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_MARBLE_APPS=OFF -DBUILD_MARBLE_TESTS=OFF -DBUILD_MARBLE_EXAMPLES=OFF
make -j$(nproc)
sudo make install
```

### Get the source
```bash
cd RetroShare/plugins/
git clone https://github.com/RetroShare/FriendsMap.git FriendsMap
```

### Build
RetroShare itself must also be built with Qt 6.
```bash
cd FriendsMap
qmake6
make clean
make
```

### Install
```bash
cp libFriendMap.so.1.0.0 ~/.retroshare/extensions/libFriendMap.so
```

---

## Windows (MSYS2 MinGW64)

The steps below use **Qt 5**. For Qt 6, see [Windows with Qt 6](#windows-with-qt-6) at the end of this section.

All commands below are run in the **MSYS2 MINGW64** shell.

### Folder layout
`FriendMap.pro` expects GeoIP and Marble to sit **next to** the RetroShare checkout:

```
GitHub/
├── RetroShare/
│   └── plugins/FriendsMap/
├── geoip-api-c/
└── marble/
    ├── build/
    └── install/        <- created by "make install"
```

### Dependencies
```bash
pacman -S --needed mingw-w64-x86_64-cmake mingw-w64-x86_64-extra-cmake-modules \
                   mingw-w64-x86_64-qt5-base mingw-w64-x86_64-qt5-svg \
                   mingw-w64-x86_64-qt5-tools mingw-w64-x86_64-qt5-declarative
```

### libGeoIP
Only the source files are needed — the plugin compiles `GeoIP.c`, `GeoIPCity.c` and
`GeoIP_deprecated.c` directly, so there is no need to build the library.
```bash
cd /c/Users/<you>/Documents/GitHub
git clone https://github.com/maxmind/geoip-api-c.git
```

### Marble (Qt 5)
```bash
cd /c/Users/<you>/Documents/GitHub
git -c core.autocrlf=false clone --branch release/23.08 --depth 1 \
    https://invent.kde.org/education/marble.git marble
cd marble

mkdir build && cd build
cmake .. -G "MSYS Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DQT_MAJOR_VERSION=5 \
  -DCMAKE_INSTALL_PREFIX=/c/Users/<you>/Documents/GitHub/marble/install \
  -DBUILD_MARBLE_APPS=OFF -DBUILD_MARBLE_TESTS=OFF -DBUILD_MARBLE_EXAMPLES=OFF
make -j8
make install
```

Notes:
- Check the CMake output says it found **Qt5**. If it picks Qt 6, delete `build/` and try again.
- If you already have a Marble checkout on master, switching with `git checkout release/23.08`
  can fail with *"Your local changes ... would be overwritten"* (usually only line endings).
  Simplest fix: delete the `marble` folder and clone again with the command above.
- If a configure step failed, remove `build/CMakeCache.txt` and `build/CMakeFiles` before running
  `cmake` again.
- **Always set `CMAKE_INSTALL_PREFIX`.** Without it Marble tries to install into
  `C:\Program Files (x86)\marble` and fails with *"Maybe need administrative privileges"*.
- `make install` is required: it collects the headers into `install/include/marble/` and copies the
  generated `marble_export.h`. Without it you get
  `fatal error: marble/MarbleWidget.h: No such file or directory`.

After installing you should have:
```
marble/install/include/marble/MarbleWidget.h
marble/install/lib/libmarblewidget-qt5.dll.a
```

### Windows with Qt 6
Only use this if RetroShare itself is built with Qt 6.

Dependencies:
```bash
pacman -S --needed mingw-w64-x86_64-cmake mingw-w64-x86_64-extra-cmake-modules \
                   mingw-w64-x86_64-qt6-base mingw-w64-x86_64-qt6-svg \
                   mingw-w64-x86_64-qt6-tools mingw-w64-x86_64-qt6-declarative
```
Build Marble from master (no branch checkout, no `QT_MAJOR_VERSION`):
```bash
cd /c/Users/<you>/Documents/GitHub/marble
git checkout master
rm -rf build && mkdir build && cd build
cmake .. -G "MSYS Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/c/Users/<you>/Documents/GitHub/marble/install \
  -DBUILD_MARBLE_APPS=OFF -DBUILD_MARBLE_TESTS=OFF -DBUILD_MARBLE_EXAMPLES=OFF
make -j8
make install
```
This gives `install/lib/libmarblewidget-qt6.dll.a`. Build the plugin with the Qt 6 qmake
(`qmake6`) instead of `qmake`; everything else is the same.

### Build the plugin
Add the plugin to `RetroShare/plugins/plugins.pro`:
```
FriendsMap \
```

Or build it on its own:
```bash
cd RetroShare/plugins/FriendsMap
qmake          # Qt 5   (use qmake6 for Qt 6)
mingw32-make
```
Re-run `qmake` whenever `FriendMap.pro` or the Marble paths change.

In Qt Creator open `RetroShare.pro` (not `FriendMap.pro`); you can then rebuild only this plugin once
the other RetroShare components are built.

### Install the plugin
- Copy `FriendMap.dll` from `plugins/FriendsMap/lib/` to `RetroShare\Data\extensions` (portable)
  or `%APPDATA%\RetroShare\extensions`.
- Copy `libmarblewidget-qt5.dll` (or `-qt6`) from `marble\install` (or `marble\install\bin`) next to `retroshare.exe`.
- Copy the DLLs Marble depends on next to `retroshare.exe`. To list them:
  ```bash
  ldd /c/Users/<you>/Documents/GitHub/marble/install/libmarblewidget-qt*.dll | grep mingw64
  ```
- Put the GeoLite City database (`GeoLiteCity.dat`, legacy GeoIP format) in the extensions folder.
  Note: MaxMind no longer distributes the legacy `.dat` files from the old
  `geolite.maxmind.com` URL.

Start RetroShare. The first start can be slow.
If needed, set the correct paths under **Options → FriendMap**.

### For distributors
FriendMap needs Marble's data and plugins. Either ask users to install Marble, or ship these files
with RetroShare:

- Create a `marble` folder inside the RetroShare folder.
- Copy `marble\install\data` to `RetroShare\marble\data`.
- Copy `marble\install\plugins` to `RetroShare\marble\plugins`.
- `marble.exe` and the other Marble apps are not needed.

---

## Credits
- **Nyfor** — original author
- **Chozabu** — updates and maintenance

Contributors:
- Morpheus Being
- hunbernd
