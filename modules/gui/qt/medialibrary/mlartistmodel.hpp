/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#ifndef MLARTISTMODEL_HPP
#define MLARTISTMODEL_HPP

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <QObject>
#include "mlbasemodel.hpp"
#include "mlartist.hpp"

class MLArtistModel : public MLBaseModel
{
    Q_OBJECT
public:
    enum Roles
    {
        ARTIST_ID = Qt::UserRole + 1,
        ARTIST_NAME,
        ARTIST_SHORT_BIO,
        ARTIST_COVER,
        ARTIST_NB_ALBUMS,
        ARTIST_NB_TRACKS
    };

public:
    explicit MLArtistModel(QObject *parent = nullptr);
    virtual ~MLArtistModel() = default;

    QHash<int, QByteArray> roleNames() const override;

protected:
    QVariant itemRoleData(MLItem *item, int role) const override;

    ListCacheLoader<std::unique_ptr<MLItem>> *createLoader() const override;

private:
    vlc_ml_sorting_criteria_t roleToCriteria(int role) const override;
    vlc_ml_sorting_criteria_t nameToCriteria(QByteArray name) const override;
    QByteArray criteriaToName(vlc_ml_sorting_criteria_t criteria) const override;
    virtual void onVlcMlEvent(const MLEvent &event) override;
    void thumbnailUpdated(int idx) override;

    static QHash<QByteArray, vlc_ml_sorting_criteria_t> M_names_to_criteria;

    struct Loader : public BaseLoader
    {
        Loader(const MLArtistModel &model) : BaseLoader(model) {}
        size_t count() const override;
        std::vector<std::unique_ptr<MLItem>> load(size_t index, size_t count) const override;
    };
};

#endif // MLARTISTMODEL_HPP
