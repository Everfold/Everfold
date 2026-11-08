// Web 构建不导入原生 FFI, 平台检测不能替代编译期隔离
export 'unsupported_desktop_window.dart'
    if (dart.library.io) 'native_desktop_window.dart'
    show createDesktopWindow;
