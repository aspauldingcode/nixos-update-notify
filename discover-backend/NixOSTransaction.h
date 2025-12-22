// SPDX-License-Identifier: MIT
#pragma once

#include <Transaction/Transaction.h>

class NixOSResource;

class NixOSTransaction : public Transaction
{
    Q_OBJECT

public:
    NixOSTransaction(NixOSResource *resource, Role role);

    void cancel() override;
    void proceed() override;

private:
    NixOSResource *m_resource;
};
