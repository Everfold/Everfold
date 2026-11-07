import 'package:file_selector/file_selector.dart';

/// 仅返回用户通过系统对话框选择的目录, 不扫描或读取目录内容
Future<String?> selectWorkspaceDirectory() => getDirectoryPath();
