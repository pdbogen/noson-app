/*
 *      Copyright (C) 2015-2016 Jean-Luc Barriere
 *
 *  This file is part of Noson-App
 *
 *  Noson-App is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Noson is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#ifndef SONOS_H
#define SONOS_H

#include "../../lib/noson/noson/src/sonossystem.h"
#include "../../lib/noson/noson/src/private/os/threads/threadpool.h"
#include "../../lib/noson/noson/src/locked.h"

#include "tools.h"
#include "zonesmodel.h"
#include "roomsmodel.h"
#include "albumsmodel.h"
#include "artistsmodel.h"
#include "genresmodel.h"
#include "tracksmodel.h"
#include "queuemodel.h"
#include "radiosmodel.h"
#include "playlistsmodel.h"
#include "favoritesmodel.h"
#include "servicesmodel.h"
#include "mediamodel.h"
#include "allservicesmodel.h"

#include <QObject>
#include <QString>
#include <QQmlEngine>

class Sonos : public QObject
{
  Q_OBJECT
  Q_PROPERTY(int jobCount READ jobCount NOTIFY jobCountChanged)

public:
  explicit Sonos(QObject *parent = 0);
  ~Sonos();

  Q_INVOKABLE bool startInit(int debug = 0); // asynchronous
  Q_INVOKABLE bool init(int debug = 0);

  Q_INVOKABLE void setLocale(const QString& locale);

  Q_INVOKABLE QString getLocale();

  Q_INVOKABLE void addServiceOAuth(const QString& type, const QString& sn, const QString& key, const QString& token, const QString& username);
  Q_INVOKABLE void deleteServiceOAuth(const QString& type, const QString& sn);

  Q_INVOKABLE void renewSubscriptions();

  Q_INVOKABLE ZonesModel* getZones();

  Q_INVOKABLE bool connectZone(const QString& zoneName);

  Q_INVOKABLE QString getZoneName() const;

  Q_INVOKABLE QString getZoneShortName() const;

  Q_INVOKABLE bool joinRoom(const QVariant& roomPayload, const QVariant& toZonePayload);

  Q_INVOKABLE bool joinZone(const QVariant& zonePayload, const QVariant& toZonePayload);
  Q_INVOKABLE bool joinZones(const QVariantList& zonePayloads, const QVariant& toZonePayload);
  Q_INVOKABLE bool startJoinZones(const QVariantList& zonePayloads, const QVariant& toZonePayload);

  Q_INVOKABLE bool unjoinRoom(const QVariant& roomPayload);
  Q_INVOKABLE bool unjoinRooms(const QVariantList& roomPayloads);
  Q_INVOKABLE bool startUnjoinRooms(const QVariantList& roomPayloads);

  Q_INVOKABLE bool unjoinZone(const QVariant& zonePayload);
  Q_INVOKABLE bool startUnjoinZone(const QVariant& zonePayload);

  const SONOS::System& getSystem() const;
  const SONOS::PlayerPtr& getPlayer() const;

  Q_INVOKABLE void runLoader();
  void loadEmptyModels();

  void runModelLoader(ListModel* model);
  void loadModel(ListModel* model);

  void runCustomizedModelLoader(ListModel* model, int id);
  void customizedLoadModel(ListModel* model, int id);

  void registerModel(ListModel* model, const QString& root);
  void unregisterModel(ListModel* model);

  bool startJob(SONOS::OS::CWorker* worker);
  int jobCount() { return *(m_jobCount.Get()); }
  void beginJob();
  void endJob();

  // Define singleton provider functions
  static QObject* sonos_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new Sonos;
  }

  static QObject* allZonesModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new ZonesModel;
  }

  static QObject* allAlbumsModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new AlbumsModel;
  }

  static QObject* allArtistsModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new ArtistsModel;
  }

  static QObject* allGenresModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new GenresModel;
  }

  static QObject* allRadiosModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new RadiosModel;
  }

  static QObject* allPlaylistsModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new PlaylistsModel;
  }

  static QObject* allFavoritesModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new FavoritesModel;
  }

  static QObject* allServicesModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new AllServicesModel;
  }

  static QObject* MyServicesModel_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
  {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new ServicesModel;
  }

  // Helpers
  Q_INVOKABLE static QString normalizedInputString(const QString& str)
  {
    return normalizedString(str);
  }

signals:
  void initDone(bool succeeded);
  void loadingStarted();
  void loadingFinished();
  void transportChanged();
  void renderingControlChanged();
  void topologyChanged();

  void jobCountChanged();

private:
  struct RegisteredContent
  {
    RegisteredContent(ListModel* _model, const QString& _root)
    : model(_model)
    , root(_root) { }
    ListModel* model;
    QString root;
  };
  typedef QList<RegisteredContent> ManagedContents;
  SONOS::Locked<ManagedContents> m_library;
  unsigned m_shareUpdateID; // Current updateID of SONOS shares

  SONOS::System m_system;
  SONOS::OS::CThreadPool m_threadpool;
  SONOS::LockedNumber<int> m_jobCount;

  SONOS::Locked<QString> m_locale; // language_COUNTRY

  static void playerEventCB(void* handle);
  static void topologyEventCB(void* handle);
};

#endif // SONOS_H
