
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import 'package:settings/settings.dart';
import 'package:app_manager/app_manager.dart' as am;
import 'app/controller/controller.dart';
import 'app/modules/log_page.dart';
import 'app/routes/app_pages.dart';
import 'config/config.dart';
import 'config/settings.dart';
import 'generated/l10n.dart';
import 'global/instance/global.dart';
import 'themes/app_colors.dart';
import 'package:nativeshell/nativeshell.dart' as nativeshell;

Future<void> initSetting() async {
  await initSettingStore(RuntimeEnvir.configPath);
  if (Settings.serverPath.get == null) {
    Settings.serverPath.set = Config.adbLocalPath;
  }
}

// App 的顶级widget
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({
    Key key,
    this.isNativeShell = false,
  }) : super(key: key);
  final bool isNativeShell;

  @override
  _AppEntryPointState createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint>
    with WidgetsBindingObserver {
  ConfigController config = Get.put(ConfigController());

  DevicesController controller = Get.find();
  @override
  void initState() {
    super.initState();
    _lastSize = WidgetsBinding.instance.window.physicalSize;

    controller.init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Size _lastSize;

  @override
  void didChangeMetrics() {
    _lastSize = WidgetsBinding.instance.window.physicalSize;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Log.w('_lastSize -> $_lastSize');
    if (Platform.isAndroid && _lastSize == null) {
      return Material(
        child: Center(
          child: SpinKitDualRing(
            color: AppColors.accent,
            size: 20.w,
            lineWidth: 2.w,
          ),
        ),
      );
    }
    // desktop初始会是 2,2
    if (_lastSize != null && _lastSize.width > 100) {
      final double screenWidth = _lastSize.width / window.devicePixelRatio;
      final double screenHeight = _lastSize.height / window.devicePixelRatio;
      Global().initTerminalSize(
        Size(screenWidth, screenHeight),
      );
    }
    final ThemeData theme = config.theme;
    Widget materialApp = GetMaterialApp(
      showPerformanceOverlay: config.showPerformanceOverlay,
      showSemanticsDebugger: config.showSemanticsDebugger,
      debugShowMaterialGrid: config.debugShowMaterialGrid,
      checkerboardRasterCacheImages: config.checkerboardRasterCacheImages,
      debugShowCheckedModeBanner: false,
      title: 'ADB工具箱',
      navigatorKey: Global.instance.navigatorKey,
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: config.locale,
      supportedLocales: S.delegate.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      defaultTransition: Transition.fadeIn,
      initialRoute: AdbPages.initial,
      getPages: AdbPages.routes + am.AppPages.routes,
      builder: (BuildContext context, Widget navigator) {
        Size size = MediaQuery.of(context).size;
        if (size.width > size.height) {
          context.init(896);
        } else {
          context.init(414);
        }
        // config中的Dimens获取不到ScreenUtil，因为ScreenUtil中用到的MediaQuery只有在
        // WidgetApp或者很长MaterialApp中才能获取到，所以在build方法中处理主题
        /// NativeShell
        if (widget.isNativeShell) {
          return nativeshell.WindowLayoutProbe(
            child: SizedBox(
              width: 800,
              height: 600,
              child: Theme(
                data: theme,
                child: navigator,
              ),
            ),
          );
        }

        ///
        ///
        ///
        /// Default Mode
        ///

        return Responsive(builder: (context, _) {
          return Theme(
            data: theme,
            child: navigator,
          );
        });
      },
    );
    Widget toastApp = ToastApp(child: materialApp);
    // Widget fpsWrapper = FPSPage(child: materialApp);
    return ToastApp(
      child: Stack(
        children: [
          GetBuilder<ConfigController>(builder: (_) {
            if (config.backgroundStyle == BackgroundStyle.normal) {
              return Container(
                color: theme.colorScheme.background,
              );
            }
            if (config.backgroundStyle == BackgroundStyle.image) {
              return SizedBox(
                height: double.infinity,
                child: Image.asset(
                  'assets/background1.jpg',
                  fit: BoxFit.cover,
                ),
              );
            } else {
              return const SizedBox();
            }
          }),
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 24.0,
              sigmaY: 24.0,
            ),
            child: Container(
              color: theme.colorScheme.background.withOpacity(0.6),
              child: GetBuilder<ConfigController>(builder: (context) {
                return GetMaterialApp(
                  showPerformanceOverlay: config.showPerformanceOverlay,
                  showSemanticsDebugger: config.showSemanticsDebugger,
                  debugShowMaterialGrid: config.debugShowMaterialGrid,
                  checkerboardRasterCacheImages:
                      config.checkerboardRasterCacheImages,
                  debugShowCheckedModeBanner: false,
                  title: 'ADB工具箱',
                  navigatorKey: Global.instance.navigatorKey,
                  themeMode: ThemeMode.light,
                  localizationsDelegates: const [
                    S.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  locale: config.locale,
                  supportedLocales: S.delegate.supportedLocales,
                  theme: ThemeData(
                    primarySwatch: Colors.blue,
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                  ),
                  defaultTransition: Transition.fadeIn,
                  initialRoute: AdbPages.initial,
                  getPages: AdbPages.routes + am.AppPages.routes,
                  builder: (BuildContext context, Widget navigator) {
                    Size size = MediaQuery.of(context).size;
                    if (size.width > size.height) {
                      context.init(896);
                    } else {
                      context.init(414);
                    }
                    // config中的Dimens获取不到ScreenUtil，因为ScreenUtil中用到的MediaQuery只有在
                    // WidgetApp或者很长MaterialApp中才能获取到，所以在build方法中处理主题
                    /// NativeShell
                    if (widget.isNativeShell) {
                      return nativeshell.WindowLayoutProbe(
                        child: SizedBox(
                          width: 800,
                          height: 600,
                          child: Theme(
                            data: theme,
                            child: navigator,
                          ),
                        ),
                      );
                    }

                    ///
                    ///
                    ///
                    /// Default Mode
                    ///

                    return Responsive(builder: (context, _) {
                      return Theme(
                        data: theme,
                        child: navigator,
                      );
                    });
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class NativeShellWrapper extends StatelessWidget {
  const NativeShellWrapper({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: nativeshell.WindowWidget(
        onCreateState: (initData) {
          nativeshell.WindowState state;

          state ??= OtherWindowState.fromInitData(initData);
          // possibly no init data, this is main window
          state ??= MainWindowState();
          return state;
        },
      ),
    );
  }
}

class MainWindowState extends nativeshell.WindowState {
  @override
  nativeshell.WindowSizingMode get windowSizingMode =>
      nativeshell.WindowSizingMode.atLeastIntrinsicSize;

  @override
  Future<void> windowCloseRequested() async {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return const AppEntryPoint(
      isNativeShell: true,
    );
  }
}

class OtherWindowState extends nativeshell.WindowState {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Responsive(
        builder: (_, __) {
          return const LogPage();
        },
      ),
    );
  }

  // This can be anything that fromInitData recognizes
  static dynamic toInitData() => {
        'class': 'OtherWindow',
      };

  static OtherWindowState fromInitData(dynamic initData) {
    if (initData is Map && initData['class'] == 'OtherWindow') {
      return OtherWindowState();
    }
    return null;
  }

  @override
  nativeshell.WindowSizingMode get windowSizingMode =>
      nativeshell.WindowSizingMode.atLeastIntrinsicSize;
}
