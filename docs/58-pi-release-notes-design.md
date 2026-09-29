# Pi 发版说明设计

## 目标与范围

正式版与月度 Nightly 共用 `generate-changelog.sh` 作为变更范围入口。正式版默认从当前第一父提交链上的最近稳定 tag 写到源码 HEAD，允许显式起点覆盖；Nightly 固定从最近稳定 tag 累计写到本次源码提交。Nightly 月内覆盖 Release body 时，说明始终包含该稳定版之后的全部变化。

## 生成链路

`generate-changelog.sh` 解析并校验起点，交给 `pi-release-changelog.sh`。后者在目标源码目录运行 Pi 0.99.1，指定 DeepSeek 服务的 `deepseek-flash` 模型，读取 `DEEPSEEK_API_KEY`。Pi 使用自己的默认 `read`、`bash`、`edit`、`write` 工具，并可查看变更范围中的提交、代码与文档；提示词只说明读者、范围与写作方向，不限定 JSON、条目数或列表编号。

Pi 返回的 Markdown 正文放在 `## Release Notes` 下。正式版与 Nightly 的下载链接、运行要求、构建标识和最终资产 SHA256 仍由发布脚本追加，以免模型生成的文字与实际发布资产不一致。UOS 商店说明取该正文到 `## Download` 之前的内容，允许段落与小标题。

## 失败与配置

两条发布工作流使用 `actions/setup-node@v4` 的 Node 22 通道，安装固定版本的 Pi。仓库必须配置 GitHub Actions Secret `DEEPSEEK_API_KEY`。Secret 缺失、Pi 退出失败或输出空白时，说明生成步骤失败，后续发布不执行；不再回退到确定性提交列表。测试使用假 Pi 验证参数、范围、格式和失败传播，不消耗真实模型额度。

现存的日版 Nightly Release 和 tag 不受本次迁移影响。已经发布的历史说明也不重写。
