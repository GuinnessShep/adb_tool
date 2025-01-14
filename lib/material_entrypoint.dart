import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:screenshot/screenshot.dart';
import 'package:settings/settings.dart';
import 'package:app_manager/app_manager.dart' as am;
import 'package:window_manager/window_manager.dart';
import 'app/controller/controller.dart';
import 'app/routes/app_pages.dart';
import 'config/config.dart';
import 'config/settings.dart';
import 'generated/l10n.dart';
import 'global/instance/global.dart';

Future<void> initSetting() async {
  await initSettingStore(RuntimeEnvir.configPath);
  if (Settings.serverPath.get == null) {
    Settings.serverPath.set = Config.adbLocalPath;
  }
}

class MaterialAppWrapper extends StatefulWidget {
  const MaterialAppWrapper({
    Key key,
    this.isNativeShell = false,
  }) : super(key: key);
  final bool isNativeShell;

  @override
  State createState() => _MaterialAppWrapperState();
}

class _MaterialAppWrapperState extends State<MaterialAppWrapper>
    with WidgetsBindingObserver {
  ConfigController config = Get.put(ConfigController());
  bool isFull = false;

  @override
  void initState() {
    super.initState();
    _lastSize = WidgetsBinding.instance.window.physicalSize;
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

  ScreenshotController screenshotController = ScreenshotController();
  @override
  Widget build(BuildContext context) {
    return ToastApp(
      child: Stack(
        children: [
          background(),
          app(),
        ],
      ),
    );
  }

  BackdropFilter app() {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 24.0,
        sigmaY: 24.0,
      ),
      child: GetBuilder<ConfigController>(
        builder: (config) {
          return Screenshot(
            controller: screenshotController,
            child: RawKeyboardListener(
              autofocus: true,
              focusNode: FocusNode(),
              onKey: ((value) {
                Log.w(value);
                // if (value is RawKeyDownEvent) {
                //   screenshotController.captureAndSave('./screenshot');
                // }
              }),
              child: GetMaterialApp(
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
                  return ResponsiveWrapper.builder(
                    Builder(
                      builder: (context) {
                        if (ResponsiveWrapper.of(context).isDesktop ||
                            ResponsiveWrapper.of(context).isTablet) {
                          Log.i('isDesktop');
                          ScreenAdapter.init(896);
                        } else {
                          Log.i('is not Desktop');
                          ScreenAdapter.init(414);
                        }
                        return Theme(
                          data: config.theme,
                          child: Column(
                            children: [
                              if (GetPlatform.isDesktop)
                                Container(
                                  color: config.theme.colorScheme.background,
                                  width: double.infinity,
                                  height: 24,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: DragToMoveArea(
                                          child: Container(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                      WindowCaptionButton.minimize(
                                        onPressed: () {
                                          windowManager.minimize();
                                        },
                                        brightness:
                                            Theme.of(context).brightness,
                                      ),
                                      isFull
                                          ? WindowCaptionButton.unmaximize(
                                              onPressed: () {
                                                isFull = false;
                                                setState(() {});
                                                windowManager.unmaximize();
                                              },
                                              brightness:
                                                  Theme.of(context).brightness,
                                            )
                                          : WindowCaptionButton.maximize(
                                              onPressed: () {
                                                isFull = true;
                                                setState(() {});
                                                windowManager.maximize();
                                              },
                                              brightness:
                                                  Theme.of(context).brightness,
                                            ),
                                      WindowCaptionButton.close(
                                        onPressed: () {
                                          windowManager.close();
                                        },
                                        brightness:
                                            Theme.of(context).brightness,
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(child: navigator),
                            ],
                          ),
                        );
                      },
                    ),
                    // maxWidth: 1200,
                    minWidth: 300,
                    defaultScale: false,
                    defaultName: PHONE,
                    breakpoints: const [
                      ResponsiveBreakpoint.resize(300, name: PHONE),
                      ResponsiveBreakpoint.resize(600, name: TABLET),
                      ResponsiveBreakpoint.resize(800, name: DESKTOP),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  GetBuilder<ConfigController> background() {
    return GetBuilder<ConfigController>(builder: (config) {
      if (config.backgroundStyle == BackgroundStyle.normal) {
        return Container(
          color: config.theme.colorScheme.background,
        );
      }
      if (config.backgroundStyle == BackgroundStyle.image) {
        return SizedBox(
          height: double.infinity,
          child: Image.asset(
            'assets/b.png',
            fit: BoxFit.cover,
          ),
        );
      } else {
        return const SizedBox();
      }
    });
  }
}
