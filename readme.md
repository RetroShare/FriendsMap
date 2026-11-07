# FriendsMap 
## GeoGraphic Friend Map  
This extension for retroshare will show your friends on a map or globe.

Original Author: Nyfor.

Chozabus Updates include:
 - Update to work with latest RS
 - Fix Crashes
 - Show Friend links
 - Choice of several map
 - Cache Data
 - optional friend links, clouds, citys, borders, avatars, etc
 - persistant settings  

This product requires GeoLite2 data created by MaxMind, available from <a href="http://www.maxmind.com">http://www.maxmind.com</a>.

#### Before attempting to build this plugin, you must build the main retroshare project and it's plugins

### Debian GNU/Linux
#### Dependencies
Install libmarble-dev and libgeoip-dev:  
<pre>
sudo apt-get  install libmarble-dev libgeoip-dev
</pre>

#### Clone From Github
Obtain the source code into the appropriate folder, it is important that the plugin folder is called FriendMap, otherwise it will not find the FriendMap.pro file:
<pre>
cd myretrosharetrunk/plugins/  
git clone git@github.com:RetroShare/FriendsMap.git FriendMap
</pre>

#### Build
Note: on some Gnu/Linux versions, you may have to type qmake instead of qmake-qt4.
<pre>
cd FriendMap  
qmake-qt4  
make clean
make  
</pre>


#### Install
The following copies the library to the default location:
<pre>
cp libFriendMap.so.1.0.0 ~/.retroshare/extensions  
cd ~/.retroshare/extensions  
mv libFriendMap.so.1.0.0 libFriendMap.so  
</pre>

Now get the required mapping data:
<pre>
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz  
gunzip GeoLiteCity.dat.gz  
</pre>  
  

### Windows

#### LibGeoIP
GeoIP is a C library that enables the user to find geographical and network information of an IP address. To use this library, you may download our free GeoLite Country or City databases. These are updated at the beginning of every month.

##### Get the source
Checkout the source code under c:\Development\geoip-api-c from https://github.com/maxmind/geoip-api-c.git

Using command line:
<pre>
cd c:\Development
git clone https://github.com/maxmind/geoip-api-c.git
</pre>

Building libGeoIp is problematic, but we don't need the lib, the source files are enough.

#### Marble
To read more about some of the features of marble, visit http://marble.kde.org/features.php .

##### Get the source
Checkout the source code under c:\Development\marble.

Using command line:
<pre>
cd c:\Development
git clone https://invent.kde.org/education/marble.git marble
cd marble
</pre>

##### Build and install
Marble will be installed under c:\Program Files (x86)\marble\ or c:\Program Files\marble\ by default, you can change the install path by changing the parameters of the cmake.  

For more information visit https://community.kde.org/Marble/WindowsCompiling

#### Compiling Marble using MinGW

Require for MINGW64:
<pre>
pacman -S mingw-w64-x86_64-extra-cmake-modules
</pre>

<pre>
cd c:/Development/marble
mkdir build
cd build
cmake -G "MSYS Makefiles" -DQTONLY=ON -DCMAKE_BUILD_TYPE=Release -DWITH_DESIGNER_PLUGIN=ON ..
make
make install
</pre>

##### Locating Files
Put some files from Marble to the right place in order to make FriendMap compile
* Copy libmarblewidget.dll.a from c:\Development\marble\build\src\lib\ to c:\Development\lib\
* Copy include folder from c:\Program Files (x86)\marble\include\ to c:\Development\marble\include\

#### FriendMap plugin
##### Get the source
Checkout the source code under c:\Development\src\plugins

Using command line:
<pre>
cd c:\Development\src\plugins  
git clone https://github.com/RetroShare/FriendsMap.git  
</pre>

##### Build
Open the file c:\Development\git\plugins\plugins.pro in text editor and add this line:
<pre>
FriendsMap \
</pre>

Using command line:
<pre>
cd FriendsMap  
qmake
mingw32-make
</pre>

Alternative build the plugin use the build script, or you can use the Qt Creator.   
If you are using Qt Creator, open the retroshare.pro, not the FriendMap.pro. With Qt Creator you can rebuild only this plugin, if you have built the other RetroShare components before.

##### Install the plugin

To install correctly, complete the following steps:

* Copy FriendMap.dll from c:\Development\build...\plugins\FriendMap\release to Retroshare\Data\extensions (portable) or to %appdata%\RetroShare\extensions  
* Download http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz  
* Extract GeoLiteCity.dat under Retroshare\Data\extensions (portable) or to %appdata%\RetroShare\extensions  
* Copy libmarblewidget.dll from c:\Development\marble\build\src\lib\ to c:\Program Files (x86)\RetroShare\  
* Copy the following dlls from c:\Qt\4.8.5\bin\ to c:\Program Files (x86)\RetroShare\:  
-QtCore4.dll  
-QtDeclarative4.dll  
-QtGui4.dll  
-QtNetwork4.dll  
-QtSvg4.dll  
-QtWebKit4.dll  
-QtXml4.dll  
-QtScript4.dll  
-QtSql4.dll  
-QtXmlPatterns4.dll  

Finally start RetroShare, at the first time it will be slow.

You may have to set the correct paths under options->FriendMap.

####For distributors
FriendMap plugin needs data and plugins from Marble. Please include instructions for installing standalone Marble.  
Or you can distribute the required Marble files along with this plugin:  

* Make a folder called "marble" under RetroShare folder
* Copy folder from c:\Program Files (x86)\marble\data to RetroShare\marble\data
* Copy folder from c:\Program Files (x86)\marble\plugins to RetroShare\marble\plugins
* marble.exe and other files are not needed
