import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/router.dart';
import 'app/providers.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env
  await dotenv.load(fileName: '.env');

  // Init Hive
  await Hive.initFlutter();

  // Lock portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: KarmaApp()));
}

class KarmaApp extends ConsumerStatefulWidget {
  const KarmaApp({super.key});

  @override
  ConsumerState<KarmaApp> createState() => _KarmaAppState();
}

class _KarmaAppState extends ConsumerState<KarmaApp> {
  @override
  void initState() {
    super.initState();
    // Check if already logged in
    Future.microtask(() => ref.read(authProvider).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Karma',
      debugShowCheckedModeBanner: false,
      theme: KarmaTheme.darkTheme,
      routerConfig: router,
    );
  }
}
