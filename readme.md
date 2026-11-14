# FriendsMap
## Geographic Friend Map
This extension for RetroShare shows your friends on a map or globe.

This product uses GeoLite data created by MaxMind.

## Features
- Shows your friends on an interactive globe or flat map (based on [Marble](https://marble.kde.org))
- Locates friends by their public IPv4 address using a GeoIP City database
- Every location (node) of a friend is shown with its name
- Online friends are drawn in green, offline friends in red
- Optional friend avatars on the map
- Optional links between friends who know each other (from RetroShare discovery)
- Three projections: Spherical (globe), Equirectangular and Mercator
- Several map themes: Blue Marble, OpenStreetMap, City Lights, Schagen 1689 and Plain, or any other Marble theme
- Optional map layers: grid, borders, cities, ice, clouds, city lights and sun shading (day/night)
- Settings apply immediately and are saved
- Optional standalone window: the map only opens on request and uses no resources while closed
- Finds Marble and the GeoIP data automatically; paths can also be set by hand

<img width="1270" height="758" alt="image" src="https://github.com/user-attachments/assets/54e3904a-becd-4a40-affc-26f69725ee05" />



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
  -DCMAKE_DISABLE_FIND_PACKAGE_Protobuf=TRUE \
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
- `-DCMAKE_DISABLE_FIND_PACKAGE_Protobuf=TRUE` builds Marble's OSM plugin without `.osm.pbf`
  support (FriendsMap does not need it). Marble 23.08 does not link with the current MSYS2 protobuf;
  without this option the build stops with
  *"undefined reference to `__emutls_v._ZN6google8protobuf8internal15ThreadSafeArena13thread_cache_E'"*
  in `OsmPlugin.dll`.
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
Run the deploy script from the FriendsMap folder (in a normal `cmd` window):
```bat
deploy-friendsmap.bat "C:\path\to\RetroShare"
```
(the folder that contains `retroshare.exe`). It copies:
- the plugin DLL to `Data\extensions6` (portable) or `%APPDATA%\RetroShare\extensions6`,
- the Marble DLLs next to `retroshare.exe`,
- Marble `data` and `plugins` to `RetroShare\marble\`,
- missing MinGW/Qt runtime DLLs from MSYS2 (found with `ldd`),
- `GeoLiteCity.dat` to the extensions folder (downloaded once, see below).

Edit `MSYS2_DIR` / `MARBLE_DIR` at the top of the script if your paths differ.

#### GeoIP data (GeoLiteCity.dat)
MaxMind no longer publishes the legacy `GeoLiteCity.dat`. The plugin still uses the legacy
GeoIP format, so use a GeoLite2 database converted to legacy format, e.g. from
<https://www.miyuru.lk/geoiplegacy> — **City, MaxMind, IPv4** (`maxmind4.dat.gz`).
Unpack it and rename it to `GeoLiteCity.dat`. The deploy script does this automatically and keeps a
copy next to the script; delete that copy to get a newer one.

Attribution: *Geolocation database of MaxMind converted by Miyuru Sankalpa.*

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
