!include("../Common/retroshare_plugin.pri"): error("Could not include file ../Common/retroshare_plugin.pri")

TARGET = FriendMap

CONFIG += qt uic qrc resources

greaterThan(QT_MAJOR_VERSION, 4) {
    # Qt 5
    QT += widgets
}

HEADERS -= upnp/upnputil.h
SOURCES -= upnp/upnputil.c

win32{
    # Fixing libGeoIP compile errors
    DEFINES += WINVER=0x0501 _WIN32_WINNT=0x0501 PACKAGE_VERSION=\\\"1.6\\\"

    MARBLE_DIR   = ../../../marble/install
    INCLUDEPATH += ../../../geoip-api-c/libGeoIP $$MARBLE_DIR/include
    SOURCES += ../../../geoip-api-c/libGeoIP/GeoIP.c \
               ../../../geoip-api-c/libGeoIP/GeoIPCity.c \
               ../../../geoip-api-c/libGeoIP/GeoIP_deprecated.c
    LIBS += -L$$MARBLE_DIR/lib -lws2_32
}

RESOURCES += \
    fmimages.qrc

HEADERS += \
    FriendMapPlugin.h \
    FriendMapPage.h \
    MarbleWidget.h \
    PaintLayer.h \
    FriendMapSettings.h \
    FriendMapConfigPage.h \
    FriendMapDetached.h \
    FriendMapController.h

SOURCES += \
    FriendMapPlugin.cpp \
    FriendMapPage.cpp \
    PaintLayer.cpp \
    FriendMapSettings.cpp \
    FriendMapConfigPage.cpp \
    FriendMapDetached.cpp \
    FriendMapController.cpp

# Marble library name follows the Qt major version (marblewidget-qt5 / marblewidget-qt6)
MARBLE_LIB = marblewidget-qt$$QT_MAJOR_VERSION

win32{
    LIBS += -L$$MARBLE_DIR/lib -l$$MARBLE_LIB
} else {
    LIBS += -l$$MARBLE_LIB -lGeoIP
}

FORMS += \
    FriendMapPage.ui \
    FriendMapConfigPage.ui \
	FriendMapDetached.ui
