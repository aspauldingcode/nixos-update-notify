// SPDX-License-Identifier: MIT
#pragma once

#include <resources/AbstractResource.h>

class NixOSBackend;

class NixOSResource : public AbstractResource
{
    Q_OBJECT

public:
    explicit NixOSResource(NixOSBackend *backend);

    QString packageName() const override { return QStringLiteral("nixos-system"); }
    QString name() const override { return QStringLiteral("NixOS System"); }
    QString comment() override { return tr("NixOS operating system update"); }
    QVariant icon() const override;
    bool canExecute() const override { return false; }
    void invokeApplication() const override {}

    State state() override;
    AbstractResource::Type type() const override { return System; }

    quint64 size() override { return 0; }
    QString installedVersion() const override;
    QString availableVersion() const override;
    QString longDescription() override;
    QString origin() const override;
    QString section() override { return QStringLiteral("system"); }
    QString author() const override { return QStringLiteral("NixOS Contributors"); }
    QString license() override { return QStringLiteral("MIT"); }
    QDate releaseDate() const override { return QDate(); }

    QList<PackageState> addonsInformation() override { return {}; }
    void fetchChangelog() override {}
    void fetchScreenshots() override {}
    QString sourceIcon() const override { return QStringLiteral("nix-snowflake"); }
    QStringList categories() override { return {QStringLiteral("System")}; }

    AbstractResourcesBackend *backend() const override;

    void updateState();

private:
    NixOSBackend *m_backend;
    State m_state = None;
};
