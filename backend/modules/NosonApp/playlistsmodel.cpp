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

#include "playlistsmodel.h"
#include "sonos.h"
#include "tools.h"
#include "../../lib/noson/noson/src/contentdirectory.h"

PlaylistItem::PlaylistItem(const SONOS::DigitalItemPtr& ptr, const QString& baseURL)
: m_ptr(ptr)
, m_valid(false)
{
  m_id = QString::fromUtf8(ptr->GetObjectID().c_str());
  if (ptr->subType() == SONOS::DigitalItem::SubType_playlistContainer)
  {
    m_title = QString::fromUtf8(ptr->GetValue("dc:title").c_str());
    m_normalized = normalizedString(m_title);
    std::vector<SONOS::ElementPtr> uris = ptr->GetCollection("upnp:albumArtURI");
    if (!uris.empty())
    {
      for (std::vector<SONOS::ElementPtr>::const_iterator it = uris.begin(); it != uris.end(); ++it)
        m_arts.push_back(QString(baseURL).append((*it)->c_str()));
    }
    m_valid = true;
  }
}

QVariant PlaylistItem::payload() const
{
  QVariant var;
  var.setValue<SONOS::DigitalItemPtr>(m_ptr);
  return var;
}

PlaylistsModel::PlaylistsModel(QObject* parent)
: QAbstractListModel(parent)
{
}

PlaylistsModel::~PlaylistsModel()
{
  clearData();
  qDeleteAll(m_items);
  m_items.clear();
}

void PlaylistsModel::addItem(PlaylistItem* item)
{
  {
    SONOS::LockGuard lock(m_lock);
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_items << item;
    endInsertRows();
  }
  emit countChanged();
}

int PlaylistsModel::rowCount(const QModelIndex& parent) const
{
  Q_UNUSED(parent);
  SONOS::LockGuard lock(m_lock);
  return m_items.count();
}

QVariant PlaylistsModel::data(const QModelIndex& index, int role) const
{
  SONOS::LockGuard lock(m_lock);
  if (index.row() < 0 || index.row() >= m_items.count())
      return QVariant();

  const PlaylistItem* item = m_items[index.row()];
  switch (role)
  {
  case PayloadRole:
    return item->payload();
  case IdRole:
    return item->id();
  case TitleRole:
    return item->title();
  case ArtRole:
    return item->art(0);
  case NormalizedRole:
    return item->normalized();
  case ArtsRole:
      return item->arts();
  default:
    return QVariant();
  }
}

QHash<int, QByteArray> PlaylistsModel::roleNames() const
{
  QHash<int, QByteArray> roles;
  roles[PayloadRole] = "payload";
  roles[IdRole] = "id";
  roles[TitleRole] = "title";
  roles[ArtRole] = "art";
  roles[NormalizedRole] = "normalized";
  roles[ArtsRole] = "arts";
  return roles;
}

QVariantMap PlaylistsModel::get(int row)
{
  SONOS::LockGuard lock(m_lock);
  if (row < 0 || row >= m_items.count())
    return QVariantMap();
  const PlaylistItem* item = m_items[row];
  QVariantMap model;
  QHash<int, QByteArray> roles = roleNames();
  model[roles[PayloadRole]] = item->payload();
  model[roles[IdRole]] = item->id();
  model[roles[TitleRole]] = item->title();
  model[roles[ArtRole]] = item->art(0);
  model[roles[NormalizedRole]] = item->normalized();
  model[roles[ArtsRole]] = item->arts();
  return model;
}

bool PlaylistsModel::init(QObject* sonos, const QString& root, bool fill)
{
  QString _root;
  if (root.isEmpty())
    _root = QString::fromUtf8(SONOS::ContentSearch(SONOS::SearchSonosPlaylist,"").Root().c_str());
  else
    _root = root;
  return ListModel::init(sonos, _root, fill);
}

void PlaylistsModel::clearData()
{
  SONOS::LockGuard lock(m_lock);
  qDeleteAll(m_data);
  m_data.clear();
}

bool PlaylistsModel::loadData()
{
  setUpdateSignaled(false);

  if (!m_provider)
  {
    emit loaded(false);
    return false;
  }
  const SONOS::PlayerPtr player = m_provider->getPlayer();
  if (!player)
  {
    emit loaded(false);
    return false;
  }

  SONOS::LockGuard lock(m_lock);
  clearData();
  m_dataState = ListModel::NoData;
  QString port;
  port.setNum(player->GetPort());
  QString url = "http://";
  url.append(player->GetHost().c_str()).append(":").append(port);

  SONOS::ContentDirectory cd(player->GetHost(), player->GetPort());
  SONOS::ContentList cl(cd, m_root.isEmpty() ? SONOS::ContentSearch(SONOS::SearchSonosPlaylist,"").Root() : m_root.toUtf8().constData());
  for (SONOS::ContentList::iterator it = cl.begin(); it != cl.end(); ++it)
  {
    PlaylistItem* item = new PlaylistItem(*it, url);
    if (item->isValid())
      m_data << item;
    else
      delete item;
  }
  if (cl.failure())
  {
    emit loaded(false);
    return false;
  }
  m_updateID = cl.GetUpdateID(); // sync new baseline
  m_dataState = ListModel::Loaded;
  emit loaded(true);
  return true;
}

void PlaylistsModel::handleDataUpdate()
{
  if (!updateSignaled())
  {
    setUpdateSignaled(true);
    dataUpdated();
  }
}

void PlaylistsModel::resetModel()
{
  {
    SONOS::LockGuard lock(m_lock);
    if (m_dataState != ListModel::Loaded)
        return;

    beginResetModel();
    if (m_items.count() > 0)
    {
      beginRemoveRows(QModelIndex(), 0, m_items.count()-1);
      qDeleteAll(m_items);
      m_items.clear();
      endRemoveRows();
    }
    if (m_data.count() > 0)
    {
      beginInsertRows(QModelIndex(), 0, m_data.count()-1);
      foreach (PlaylistItem* item, m_data)
          m_items << item;
      m_data.clear();
      endInsertRows();
    }
    m_dataState = ListModel::Synced;
    endResetModel();
  }
  emit countChanged();
}

bool PlaylistsModel::asyncLoad()
{
  if (m_provider)
  {
    m_provider->runModelLoader(this);
    return true;
  }
  return false;
}
