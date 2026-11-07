import 'package:flutter/widget_previews.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/everfold_app.dart';

/// 提供不加载原生服务的首页预览
@Preview(name: 'Material · Mobile', size: Size(390, 844))
@Preview(name: 'Material · Desktop', size: Size(1280, 900))
Widget materialHomePreview() => const ProviderScope(child: EverfoldApp());
