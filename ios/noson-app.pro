TEMPLATE = app
TARGET = noson-app
QT += quick quickcontrols2 qml gui core widgets xml svg
CONFIG += c++11

SOURCES += \
  ../gui/noson.cpp \
  ../gui/diskcache/diskcachefactory.cpp \
  ../gui/diskcache/cachingnetworkaccessmanager.cpp \
  ../gui/diskcache/cachereply.cpp \
  ../gui/signalhandler.cpp

HEADERS += \
  ../gui/diskcache/diskcachefactory.h \
  ../gui/diskcache/cachingnetworkaccessmanager.h \
  ../gui/diskcache/cachereply.h \
  ../gui/signalhandler.h

RESOURCES += ../gui/noson.qrc

#QTPLUGIN += NosonApp NosonThumbnailer NosonMediaScanner

target.path = .
INSTALLS += target

LIBS += -L$$PWD/ -lNosonApp -lNosonThumbnailer -lNosonMediaScanner -lnoson -lcrypto -lssl -lFLAC++ -lFLAC
PRE_TARGETDEPS += $$PWD/libcrypto.a $$PWD/libssl.a $$PWD/libFLAC.a $$PWD/libFLAC++.a $$PWD/libnoson.a
