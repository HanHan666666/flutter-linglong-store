import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/running_process_provider.dart';
import '../../widgets/linglong_process_panel.dart';

/// 独立进程管理页
///
/// 当前主入口已经迁移到“我的应用”双 Tab，这个页面保留为兼容入口。
class ProcessPage extends ConsumerStatefulWidget {
  const ProcessPage({super.key});

  @override
  ConsumerState<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends ConsumerState<ProcessPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(runningProcessProvider.notifier).setPageVisible(true);
      ref.read(runningProcessProvider.notifier).setProcessTabActive(true);
    });
  }

  @override
  void dispose() {
    ref.read(runningProcessProvider.notifier).setProcessTabActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const LinglongProcessPanel();
  }
}
