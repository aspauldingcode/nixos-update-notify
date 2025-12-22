// SPDX-License-Identifier: MIT
#pragma once

#include <resources/AbstractBackendUpdater.h>

class NixOSBackend;

class NixOSUpdater : public AbstractBackendUpdater
{
    Q_OBJECT

public:
    explicit NixOSUpdater(NixOSBackend *backend);

    void prepare() override {}
    bool hasUpdates() const override;
    qreal progress() const override { return m_progress; }
    void start() override;
    bool isCancelable() const override { return false; }
    bool isProgressing() const override { return m_progressing; }
    bool isMarked(AbstractResource *resource) const override;
    void fetchChangelog() const override {}
    double updateSize() const override { return 0; }
    quint64 downloadSpeed() const override { return 0; }
    void cancel() override {}
    void proceed() override;
    bool needsReboot() const override { return true; }

private:
    NixOSBackend *m_backend;
    qreal m_progress = 0;
    bool m_progressing = false;
};
