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

#include "mlvideomodel.hpp"

template<typename T>
QVariantList getVariantList(const QList<T> & desc)
{
    QVariantList list;

    for (const T & item : desc)
    {
        list.append(QVariant::fromValue(item));
    }

    return list;
}

QHash<QByteArray, vlc_ml_sorting_criteria_t> MLVideoModel::M_names_to_criteria = {
    {"id", VLC_ML_SORTING_DEFAULT},
    {"title", VLC_ML_SORTING_ALPHA},
    {"duration", VLC_ML_SORTING_DURATION},
    {"playcount", VLC_ML_SORTING_PLAYCOUNT},
};

MLVideoModel::MLVideoModel(QObject* parent)
    : MLBaseModel(parent)
{
}

QVariant MLVideoModel::itemRoleData(MLItem *item, int role) const
{
    const auto video = static_cast<MLVideo *>(item);
    if ( video == nullptr )
        return {};

    switch (role)
    {
        case VIDEO_ID:
            return QVariant::fromValue( video->getId() );
        case VIDEO_IS_NEW:
            return QVariant::fromValue( video->isNew() );
        case VIDEO_FILENAME:
            return QVariant::fromValue( video->getFileName() );
        case VIDEO_TITLE:
            return QVariant::fromValue( video->getTitle() );
        case VIDEO_THUMBNAIL:
            return QVariant::fromValue( video->getThumbnail() );
        case VIDEO_DURATION:
            return QVariant::fromValue( video->getDuration() );
        case VIDEO_PROGRESS:
            return QVariant::fromValue( video->getProgress() );
        case VIDEO_PLAYCOUNT:
            return QVariant::fromValue( video->getPlayCount() );
        case VIDEO_RESOLUTION:
            return QVariant::fromValue( video->getResolutionName() );
        case VIDEO_CHANNEL:
            return QVariant::fromValue( video->getChannel() );
        case VIDEO_MRL:
            return QVariant::fromValue( video->getMRL() );
        case VIDEO_DISPLAY_MRL:
            return QVariant::fromValue( video->getDisplayMRL() );
        case VIDEO_VIDEO_TRACK:
            return getVariantList( video->getVideoDesc() );
        case VIDEO_AUDIO_TRACK:
            return getVariantList( video->getAudioDesc() );
        case VIDEO_TITLE_FIRST_SYMBOL:
            return QVariant::fromValue( getFirstSymbol( video->getTitle() ) );

        default:
            return {};
    }
}

QHash<int, QByteArray> MLVideoModel::roleNames() const
{
    return {
        { VIDEO_ID, "id" },
        { VIDEO_IS_NEW, "isNew" },
        { VIDEO_FILENAME, "fileName" },
        { VIDEO_TITLE, "title" },
        { VIDEO_THUMBNAIL, "thumbnail" },
        { VIDEO_DURATION, "duration" },
        { VIDEO_PROGRESS, "progress" },
        { VIDEO_PLAYCOUNT, "playcount" },
        { VIDEO_RESOLUTION, "resolution_name" },
        { VIDEO_CHANNEL, "channel" },
        { VIDEO_MRL, "mrl" },
        { VIDEO_DISPLAY_MRL, "display_mrl" },
        { VIDEO_AUDIO_TRACK, "audioDesc" },
        { VIDEO_VIDEO_TRACK, "videoDesc" },
        { VIDEO_TITLE_FIRST_SYMBOL, "title_first_symbol"},
    };
}

vlc_ml_sorting_criteria_t MLVideoModel::roleToCriteria(int role) const
{
    switch(role)
    {
        case VIDEO_TITLE:
            return VLC_ML_SORTING_ALPHA;
        case VIDEO_DURATION:
            return VLC_ML_SORTING_DURATION;
        case VIDEO_PLAYCOUNT:
            return VLC_ML_SORTING_PLAYCOUNT;
        default:
            return VLC_ML_SORTING_DEFAULT;
    }
}

vlc_ml_sorting_criteria_t MLVideoModel::nameToCriteria(QByteArray name) const
{
    return M_names_to_criteria.value(name, VLC_ML_SORTING_DEFAULT);
}

QByteArray MLVideoModel::criteriaToName(vlc_ml_sorting_criteria_t criteria) const
{
    return M_names_to_criteria.key(criteria, "");
}

void MLVideoModel::onVlcMlEvent(const MLEvent &event)
{
    switch (event.i_type)
    {
        case VLC_ML_EVENT_MEDIA_ADDED:
        case VLC_ML_EVENT_MEDIA_UPDATED:
        case VLC_ML_EVENT_MEDIA_DELETED:
            m_need_reset = true;
            break;
        default:
            break;
    }
    MLBaseModel::onVlcMlEvent( event );
}

void MLVideoModel::thumbnailUpdated(int idx)
{
    emit dataChanged(index(idx), index(idx), {VIDEO_THUMBNAIL});
}

ListCacheLoader<std::unique_ptr<MLItem>> *
MLVideoModel::createLoader() const
{
    return new Loader(*this);
}

size_t MLVideoModel::Loader::count() const /* override */
{
    vlc_ml_query_params_t params = getParams().toCQueryParams();

    int64_t id = m_parent.id;

    if (id <= 0)
        return vlc_ml_count_video_media(m_ml, &params);
    else
        return vlc_ml_count_media_of(m_ml, &params, m_parent.type, id);
}

std::vector<std::unique_ptr<MLItem>>
MLVideoModel::Loader::load(size_t index, size_t count) const /* override */
{
    vlc_ml_query_params_t params = getParams(index, count).toCQueryParams();

    ml_unique_ptr<vlc_ml_media_list_t> list;

    int64_t id = m_parent.id;

    if (id <= 0)
        list.reset(vlc_ml_list_video_media(m_ml, &params));
    else
        list.reset(vlc_ml_list_media_of(m_ml, &params, m_parent.type, id));

    if (list == nullptr)
        return {};

    std::vector<std::unique_ptr<MLItem>> result;

    for (const vlc_ml_media_t & media : ml_range_iterate<vlc_ml_media_t>(list))
    {
        result.emplace_back(std::make_unique<MLVideo>(m_ml, &media));
    }

    return result;
}
