import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/linux_renderer_service.dart';

final linuxRendererServiceProvider = Provider<LinuxRendererService>(
  (ref) => LinuxRendererService(),
);

final linuxRendererRuntimeProvider = FutureProvider<LinuxRendererRuntimeState>(
  (ref) async => ref.read(linuxRendererServiceProvider).getRuntimeState(),
);
