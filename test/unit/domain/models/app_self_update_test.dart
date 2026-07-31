import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';

const _sha256 =
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

void main() {
  test('架构别名归一化为发布资产使用的稳定值', () {
    expect(normalizeSelfUpdateArch('x86_64'), 'amd64');
    expect(normalizeSelfUpdateArch('aarch64'), 'arm64');
    expect(normalizeSelfUpdateArch('loongarch64'), 'loong64');
    expect(normalizeSelfUpdateArch('riscv64'), isNull);
  });

  test('按当前安装身份和宽松架构后缀选择 Release 资产', () {
    const assets = <ReleaseAsset>[
      ReleaseAsset(
        name: 'linglong-store-3.5.1-amd64.deb',
        browserDownloadUrl: 'https://example.com/store.deb',
      ),
      ReleaseAsset(
        name: 'linglong-store-3.5.1-1.aarch64.rpm',
        browserDownloadUrl: 'https://example.com/store.rpm',
      ),
      ReleaseAsset(
        name: 'linglong-store-3.5.1-amd64.AppImage',
        browserDownloadUrl: 'https://example.com/store.AppImage',
      ),
    ];

    expect(
      resolveAppUpdatePackageAsset(
        assets: assets,
        installationKind: AppInstallationKind.packageManagerDpkg,
        arch: 'x86_64',
      )?.name,
      'linglong-store-3.5.1-amd64.deb',
    );
    expect(
      resolveAppUpdatePackageAsset(
        assets: assets,
        installationKind: AppInstallationKind.packageManagerRpm,
        arch: 'arm64',
      )?.name,
      'linglong-store-3.5.1-1.aarch64.rpm',
    );
    expect(
      resolveAppUpdatePackageAsset(
        assets: assets,
        installationKind: AppInstallationKind.appImage,
        arch: 'amd64',
      )?.name,
      'linglong-store-3.5.1-amd64.AppImage',
    );
  });

  test('SHA256 清单只接受完整文件名匹配', () {
    const content =
        '''
$_sha256  store-amd64.deb
0000000000000000000000000000000000000000000000000000000000000000  store-arm64.deb
''';

    expect(parseAppUpdateSha256(content, 'store-amd64.deb'), _sha256);
    expect(parseAppUpdateSha256(content, 'store.deb'), isNull);
  });

  test('同一安装目标存在多个候选资产时拒绝随意选择', () {
    const assets = <ReleaseAsset>[
      ReleaseAsset(
        name: 'first-amd64.deb',
        browserDownloadUrl: 'https://example.com/first.deb',
      ),
      ReleaseAsset(
        name: 'second-amd64.deb',
        browserDownloadUrl: 'https://example.com/second.deb',
      ),
    ];

    expect(
      () => resolveAppUpdatePackageAsset(
        assets: assets,
        installationKind: AppInstallationKind.packageManagerDpkg,
        arch: 'amd64',
      ),
      throwsStateError,
    );
  });
}
