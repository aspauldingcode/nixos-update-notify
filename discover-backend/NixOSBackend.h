// SPDX-License-Identifier: MIT
#pragma once

#include <resources/AbstractResourcesBackend.h>
#include <QNetworkAccessManager>

class NixOSResource;
class NixOSUpdater;

class NixOSBackend : public AbstractResourcesBackend
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.kde.muon.AbstractResourcesBackendFactory")
    Q_INTERFACES(AbstractResourcesBackendFactory)

public:
    explicit NixOSBackend(QObject *parent = nullptr);

    QString displayName() const override;
    bool isValid() const override;
    bool hasApplications() const override { return false; }

    ResultsStream *search(const AbstractResourcesBackend::Filters &filter) override;
    AbstractBackendUpdater *backendUpdater() const override;
    AbstractReviewsBackend *reviewsBackend() const override { return nullptr; }

    int updatesCount() const override;
    int fetchingUpdatesProgress() const override;

    Transaction *installApplication(AbstractResource *app) override;
    Transaction *installApplication(AbstractResource *app, const AddonList &addons) override;
    Transaction *removeApplication(AbstractResource *app) override;

    void checkForUpdates() override;

    QString channel() const { return m_channel; }
    QString localRevision() const { return m_localRevision; }
    QString remoteRevision() const { return m_remoteRevision; }

private Q_SLOTS:
    void onNetworkReply(QNetworkReply *reply);

private:
    void fetchLocalRevision();
    void fetchRemoteRevision();

    QNetworkAccessManager *m_network;
    NixOSResource *m_resource = nullptr;
    NixOSUpdater *m_updater = nullptr;

    QString m_channel = QStringLiteral("nixos-unstable");
    QString m_localRevision;
    QString m_remoteRevision;
    bool m_updateAvailable = false;
    int m_fetchProgress = 100;
};
