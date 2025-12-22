// SPDX-License-Identifier: MIT
#include "NixOSBackend.h"
#include "NixOSResource.h"
#include "NixOSUpdater.h"
#include "NixOSTransaction.h"

#include <resources/StandardBackendUpdater.h>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QProcess>

NixOSBackend::NixOSBackend(QObject *parent)
    : AbstractResourcesBackend(parent)
    , m_network(new QNetworkAccessManager(this))
{
    m_resource = new NixOSResource(this);
    m_updater = new NixOSUpdater(this);

    connect(m_network, &QNetworkAccessManager::finished,
            this, &NixOSBackend::onNetworkReply);

    // Get local revision on startup
    fetchLocalRevision();
}

QString NixOSBackend::displayName() const
{
    return QStringLiteral("NixOS");
}

bool NixOSBackend::isValid() const
{
    return !m_localRevision.isEmpty();
}

ResultsStream *NixOSBackend::search(const AbstractResourcesBackend::Filters &filter)
{
    QVector<StreamResult> results;

    // Only show resource if we're looking for updates and there is one
    if (m_updateAvailable && filter.state == AbstractResource::Upgradeable) {
        results << StreamResult{m_resource, 0};
    }

    return new ResultsStream(QStringLiteral("NixOS"), results);
}

AbstractBackendUpdater *NixOSBackend::backendUpdater() const
{
    return m_updater;
}

int NixOSBackend::updatesCount() const
{
    return m_updateAvailable ? 1 : 0;
}

int NixOSBackend::fetchingUpdatesProgress() const
{
    return m_fetchProgress;
}

Transaction *NixOSBackend::installApplication(AbstractResource *app)
{
    return new NixOSTransaction(qobject_cast<NixOSResource *>(app), Transaction::InstallRole);
}

Transaction *NixOSBackend::installApplication(AbstractResource *app, const AddonList &)
{
    return installApplication(app);
}

Transaction *NixOSBackend::removeApplication(AbstractResource *app)
{
    // NixOS system cannot be "removed"
    return new NixOSTransaction(qobject_cast<NixOSResource *>(app), Transaction::RemoveRole);
}

void NixOSBackend::checkForUpdates()
{
    m_fetchProgress = 0;
    Q_EMIT fetchingUpdatesProgressChanged();

    fetchLocalRevision();
    fetchRemoteRevision();
}

void NixOSBackend::fetchLocalRevision()
{
    QProcess process;
    process.start(QStringLiteral("/run/current-system/sw/bin/nixos-version"),
                  {QStringLiteral("--revision")});
    process.waitForFinished();

    if (process.exitCode() == 0) {
        m_localRevision = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
    }
}

void NixOSBackend::fetchRemoteRevision()
{
    const QUrl url(QStringLiteral("https://prometheus.nixos.org/api/v1/query?query=channel_revision"));
    QNetworkRequest request(url);
    m_network->get(request);
}

void NixOSBackend::onNetworkReply(QNetworkReply *reply)
{
    reply->deleteLater();

    m_fetchProgress = 100;
    Q_EMIT fetchingUpdatesProgressChanged();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "NixOS backend: network error:" << reply->errorString();
        return;
    }

    const QByteArray data = reply->readAll();
    const QJsonDocument doc = QJsonDocument::fromJson(data);
    const QJsonObject root = doc.object();
    const QJsonArray results = root[QStringLiteral("data")]
                                   .toObject()[QStringLiteral("result")]
                                   .toArray();

    for (const QJsonValue &val : results) {
        const QJsonObject metric = val.toObject()[QStringLiteral("metric")].toObject();
        const QString channel = metric[QStringLiteral("channel")].toString();

        if (channel == m_channel) {
            m_remoteRevision = metric[QStringLiteral("revision")].toString();
            break;
        }
    }

    const bool wasAvailable = m_updateAvailable;
    m_updateAvailable = !m_remoteRevision.isEmpty()
                        && !m_localRevision.isEmpty()
                        && m_remoteRevision != m_localRevision;

    m_resource->updateState();

    if (wasAvailable != m_updateAvailable) {
        Q_EMIT updatesCountChanged();
    }
}
