# Gitee 仓库与 Release 同步

## 目标

当前 Flutter 商店仓库的 Gitee 镜像固定为：

- 仓库：`hanplus/flutter-linglong-store`
- GitHub 源：`HanHan666666/flutter-linglong-store`

Git refs 与 Release 同步分成两段：

1. 先推送分支和 tag 到 Gitee
2. 再运行仓库内脚本同步 GitHub Release 与资产

不要跳过第 1 步。Gitee 上没有对应 tag 时，Release 创建一定失败。

## 环境变量

同步脚本默认从 `LINGLONG_RELEASE_ENV_FILE` 指定的文件加载环境变量；未指定时，默认读取：

```bash
/home/han/linglong-repo.sh
```

至少需要：

```bash
export GITHUB_TOKEN=...
export GITEE_TOKEN=...
export GITEE_REPO=hanplus/flutter-linglong-store
```

`GITEE_REPO` 允许以下两种写法，脚本会统一归一成 `owner/repo`：

```bash
export GITEE_REPO=hanplus/flutter-linglong-store
export GITEE_REPO=https://gitee.com/hanplus/flutter-linglong-store.git
```

如果没有显式设置 `GITHUB_REPO`，脚本会优先尝试从当前仓库的 `origin` 自动推导。

## 首次建仓

如果 Gitee 仓库还不存在，可以用 API 创建：

```bash
curl -X POST "https://gitee.com/api/v5/user/repos" \
  -d "access_token=$GITEE_TOKEN" \
  -d "name=flutter-linglong-store" \
  -d "private=false"
```

## 同步 Git refs

第一次配置本地 `gitee` remote：

```bash
git remote add gitee https://gitee.com/hanplus/flutter-linglong-store.git
```

推送默认分支和 tags：

```bash
git push "https://hanplus:${GITEE_TOKEN}@gitee.com/hanplus/flutter-linglong-store.git" master:master
git push "https://hanplus:${GITEE_TOKEN}@gitee.com/hanplus/flutter-linglong-store.git" --tags
```

校验目标 tag 已存在：

```bash
git ls-remote "https://hanplus:${GITEE_TOKEN}@gitee.com/hanplus/flutter-linglong-store.git" HEAD refs/tags/v3.0.2
```

## 同步 Release

统一使用仓库脚本入口：

```bash
bash build/scripts/sync-gitee-release.sh
```

或显式指定目标仓库：

```bash
bash build/scripts/sync-gitee-release.sh \
  --gitee-repo https://gitee.com/hanplus/flutter-linglong-store.git
```

帮助输出：

```bash
bash build/scripts/sync-gitee-release.sh --help
```

## 同步规则

- GitHub 有、Gitee 没有：创建 Release 并上传全部资产
- 正文不同：删除 Gitee 旧 Release 后重建
- 资产名称缺失：删除 Gitee 旧 Release 后重建
- Gitee 自动生成的源码包 `tag.zip` / `tag.tar.gz` 不参与幂等比较
- Gitee API 返回的上传资产不一定带 `size` 字段；当前脚本优先按文件名匹配，若 Gitee 返回了 `size` 才进一步比较大小

## 已知限制

- 单个附件默认超过 `100MB` 会被跳过
- 下载与上传都带 3 次重试，网络抖动时可能耗时较长
- 当前脚本只负责同步 GitHub 已存在的 Release，不负责生成新的发布资产
