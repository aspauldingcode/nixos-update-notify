// SPDX-License-Identifier: MIT
#include "NixOSUpdater.h"
#include "NixOSBackend.h"

NixOSUpdater::NixOSUpdater(NixOSBackend *backend)
    : AbstractBackendUpdater(backend)
    , m_backend(backend)
{
}

bool NixOSUpdater::hasUpdates() const
{
    return m_backend->updatesCount() > 0;
}

void NixOSUpdater::start()
{
    // Notify-only mode: we don't actually perform updates
    // User must run nixos-rebuild manually
    m_progressing = true;
    m_progress = 0;
    Q_EMIT progressingChanged(m_progressing);

    // Immediately complete since we're notify-only
    m_progress = 100;
    m_progressing = false;
    Q_EMIT progressingChanged(m_progressing);
}

bool NixOSUpdater::isMarked(AbstractResource *resource) const
{
    Q_UNUSED(resource)
    return hasUpdates();
}

void NixOSUpdater::proceed()
{
    // Notify-only: nothing to do
    // The user will run nixos-rebuild switch manually
}
