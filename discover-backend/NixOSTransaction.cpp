// SPDX-License-Identifier: MIT
#include "NixOSTransaction.h"
#include "NixOSResource.h"

NixOSTransaction::NixOSTransaction(NixOSResource *resource, Role role)
    : Transaction(resource->backend(), resource, role)
    , m_resource(resource)
{
    setCancellable(false);

    // Notify-only mode: immediately complete with a message
    setStatus(DoneStatus);
    Q_EMIT passiveMessage(tr("Run 'sudo nixos-rebuild switch' to apply the update."));
}

void NixOSTransaction::cancel()
{
    setStatus(CancelledStatus);
}

void NixOSTransaction::proceed()
{
    // Notify-only: we don't perform the actual update
    setStatus(DoneStatus);
}
