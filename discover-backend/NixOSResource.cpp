// SPDX-License-Identifier: MIT
#include "NixOSResource.h"
#include "NixOSBackend.h"

#include <QIcon>

NixOSResource::NixOSResource(NixOSBackend *backend)
    : AbstractResource(backend)
    , m_backend(backend)
{
}

QVariant NixOSResource::icon() const
{
    return QVariant::fromValue(QIcon::fromTheme(QStringLiteral("nix-snowflake"),
                                                 QIcon::fromTheme(QStringLiteral("system-software-update"))));
}

AbstractResource::State NixOSResource::state()
{
    return m_state;
}

QString NixOSResource::installedVersion() const
{
    const QString rev = m_backend->localRevision();
    return rev.isEmpty() ? tr("Unknown") : rev.left(8);
}

QString NixOSResource::availableVersion() const
{
    const QString rev = m_backend->remoteRevision();
    return rev.isEmpty() ? tr("Unknown") : rev.left(8);
}

QString NixOSResource::longDescription()
{
    return tr("A NixOS system update is available.\n\n"
              "Channel: %1\n"
              "Current revision: %2\n"
              "Available revision: %3\n\n"
              "Run 'sudo nixos-rebuild switch' to update.")
        .arg(m_backend->channel(),
             m_backend->localRevision().left(8),
             m_backend->remoteRevision().left(8));
}

QString NixOSResource::origin() const
{
    return m_backend->channel();
}

AbstractResourcesBackend *NixOSResource::backend() const
{
    return m_backend;
}

void NixOSResource::updateState()
{
    const State oldState = m_state;

    if (m_backend->updatesCount() > 0) {
        m_state = Upgradeable;
    } else {
        m_state = Installed;
    }

    if (oldState != m_state) {
        Q_EMIT stateChanged();
    }
}
