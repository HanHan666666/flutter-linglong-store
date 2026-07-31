import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';

void main() {
  group('normalizeSelfUpdateArch', () {
    test('normalizes known architecture aliases', () {
      expect(normalizeSelfUpdateArch('x86_64'), 'amd64');
      expect(normalizeSelfUpdateArch('amd64'), 'amd64');
      expect(normalizeSelfUpdateArch('aarch64'), 'arm64');
      expect(normalizeSelfUpdateArch('arm64'), 'arm64');
      expect(normalizeSelfUpdateArch('loongarch64'), 'loong64');
      expect(normalizeSelfUpdateArch('loong64'), 'loong64');
    });

    test('rejects unknown or empty architecture', () {
      expect(normalizeSelfUpdateArch('riscv64'), isNull);
      expect(normalizeSelfUpdateArch(''), isNull);
      expect(normalizeSelfUpdateArch(null), isNull);
    });
  });

  group('resolveAssetForPackage', () {
    const assets = <ReleaseAsset>[
      ReleaseAsset(
        name: 'linglong-store_3.5.0_amd64.deb',
        browserDownloadUrl: 'https://example.com/linglong-store_3.5.0_amd64.deb',
      ),
      ReleaseAsset(
        name: 'linglong-store_3.5.0_arm64.deb',
        browserDownloadUrl: 'https://example.com/linglong-store_3.5.0_arm64.deb',
      ),
      ReleaseAsset(
        name: 'linglong-store_3.5.0_loong64.deb',
        browserDownloadUrl: 'https://example.com/linglong-store_3.5.0_loong64.deb',
      ),
      ReleaseAsset(
        name: 'linglong-store-3.5.0-1.x86_64.rpm',
        browserDownloadUrl: 'https://example.com/linglong-store-3.5.0-1.x86_64.rpm',
      ),
      ReleaseAsset(
        name: 'linglong-store-3.5.0-1.aarch64.rpm',
        browserDownloadUrl: 'https://example.com/linglong-store-3.5.0-1.aarch64.rpm',
      ),
      ReleaseAsset(
        name: 'linglong-store-3.5.0-amd64.AppImage',
        browserDownloadUrl: 'https://example.com/linglong-store-3.5.0-amd64.AppImage',
      ),
      ReleaseAsset(
        name: 'linglong-store-3.5.0-arm64.AppImage',
        browserDownloadUrl: 'https://example.com/linglong-store-3.5.0-arm64.AppImage',
      ),
      ReleaseAsset(
        name: 'hashes.sha256',
        browserDownloadUrl: 'https://example.com/hashes.sha256',
      ),
    ];

    test('selects dpkg package by architecture', () {
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'x86_64',
          kind: AppInstallationKind.packageManagerDpkg,
        )?.name,
        'linglong-store_3.5.0_amd64.deb',
      );
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'arm64',
          kind: AppInstallationKind.packageManagerDpkg,
        )?.name,
        'linglong-store_3.5.0_arm64.deb',
      );
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'loong64',
          kind: AppInstallationKind.packageManagerDpkg,
        )?.name,
        'linglong-store_3.5.0_loong64.deb',
      );
    });

    test('selects rpm package by architecture', () {
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'amd64',
          kind: AppInstallationKind.packageManagerRpm,
        )?.name,
        'linglong-store-3.5.0-1.x86_64.rpm',
      );
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'aarch64',
          kind: AppInstallationKind.packageManagerRpm,
        )?.name,
        'linglong-store-3.5.0-1.aarch64.rpm',
      );
    });

    test('returns null for rpm on loong64 (no asset exists)', () {
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'loong64',
          kind: AppInstallationKind.packageManagerRpm,
        ),
        isNull,
      );
    });

    test('selects AppImage by architecture', () {
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'x86_64',
          kind: AppInstallationKind.appImage,
        )?.name,
        'linglong-store-3.5.0-amd64.AppImage',
      );
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'arm64',
          kind: AppInstallationKind.appImage,
        )?.name,
        'linglong-store-3.5.0-arm64.AppImage',
      );
    });

    test('returns null for AppImage on loong64 (no asset exists)', () {
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'loong64',
          kind: AppInstallationKind.appImage,
        ),
        isNull,
      );
    });

    test('returns null for manual installation', () {
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'amd64',
          kind: AppInstallationKind.manual,
        ),
        isNull,
      );
    });

    test('returns null for unknown architecture', () {
      expect(
        resolveAssetForPackage(
          assets: assets,
          arch: 'riscv64',
          kind: AppInstallationKind.packageManagerDpkg,
        ),
        isNull,
      );
    });

    test('returns null when no asset matches', () {
      const unrelated = <ReleaseAsset>[
        ReleaseAsset(
          name: 'linglong-store-3.5.0-linux-amd64.tar.gz',
          browserDownloadUrl: 'https://example.com/x.tar.gz',
        ),
      ];
      expect(
        resolveAssetForPackage(
          assets: unrelated,
          arch: 'amd64',
          kind: AppInstallationKind.packageManagerDpkg,
        ),
        isNull,
      );
    });
  });
}
