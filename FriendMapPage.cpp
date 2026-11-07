/*!
 * @file FriendMapPage.cpp
 * @author RetroShare Team
 * 
 * Copyright (C) 2014 - RetroShare Team
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 * 
 */

#include "FriendMapPage.h"
#include "ui_FriendMapPage.h"
#include <QMessageBox>

//!
//! \brief FriendMapPage::FriendMapPage
//! \param peers
//!
FriendMapPage::FriendMapPage(RsPeers* peers, RsDisc* disc) :
    ui(new Ui::FriendMapPage)
{
    ui->setupUi(this);
    //this->setWindowTitle(QString("FriendMap"));
    ui->MarbleWidget->setShowCompass(false);
    ui->MarbleWidget->setShowCrosshairs(false);
    this->peers = peers;
    this->mDisc = disc;
    this->layer = NULL;

    mTimer.setInterval(5000);
    mTimer.start(1000);
}

//!
//! \brief FriendMapPage::~FriendMapPage
//! Destructor which destroys the user interace
//!
FriendMapPage::~FriendMapPage()
{
    if(layer){
        ui->MarbleWidget->removeLayer(layer);
        delete layer;
    }
    delete ui;
}

//!
//! \brief FriendMapPage::setConfig
//! \param settings
//!
void FriendMapPage::setConfig(const FriendMapSettings* settings){
    // Settings are applied on every checkbox click, so only touch what changed:
    // reloading the map theme or recalculating sun shading is expensive.
    Marble::MarbleWidget* w = ui->MarbleWidget;
    const QString theme = QString::fromStdString(settings->getMapThemeId());
    if(w->mapThemeId() != theme)                               w->setMapThemeId(theme);
    if(w->projection() != settings->getProjection())           w->setProjection(settings->getProjection());
    if(w->showGrid() != settings->getShowGrid())               w->setShowGrid(settings->getShowGrid());
    if(w->showBorders() != settings->getShowBorders())         w->setShowBorders(settings->getShowBorders());
    if(w->showCities() != settings->getShowCities())           w->setShowCities(settings->getShowCities());
    if(w->showIceLayer() != settings->getShowIceLayer())       w->setShowIceLayer(settings->getShowIceLayer());
    if(w->showClouds() != settings->getShowClouds())           w->setShowClouds(settings->getShowClouds());
    if(w->showCityLights() != settings->getShowCityLights())   w->setShowCityLights(settings->getShowCityLights());
    if(w->showSunShading() != settings->getShowSunShading())   w->setShowSunShading(settings->getShowSunShading());

    if(settings->validPaths()){
        // the friend layer only depends on the GeoIP file, links and avatars
        if(layer != NULL
           && mLayerGeoIpPath == settings->getGeoIpDataPath()
           && mLayerShowLinks == settings->getShowLinks()
           && mLayerShowAvatars == settings->getShowAvatars()){
            w->update();
            return;
        }
        mLayerGeoIpPath = settings->getGeoIpDataPath();
        mLayerShowLinks = settings->getShowLinks();
        mLayerShowAvatars = settings->getShowAvatars();

        if(layer != NULL){
            ui->MarbleWidget->removeLayer(layer);
            delete layer;
        }
        layer = new PaintLayer(peers, mDisc, settings);
        connect(&mTimer, SIGNAL(timeout()), layer, SLOT(genPeerCache()));
        //connect(ui->MarbleWidget, SIGNAL(mouseClickGeoPosition(qreal,qreal,GeoDataCoordinates::Unit)), layer, SLOT(genPeerCache());//enable to update cache on click
        ui->MarbleWidget->addLayer(layer);
    } else {
        QMessageBox::information(this,
                                 tr("FriendMap"),
                                 QString(tr("GeoIP Data not found!")));
    }
}

// eof   
