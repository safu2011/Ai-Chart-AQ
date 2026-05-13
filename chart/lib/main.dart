import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not found — API key must be set via Settings
  }

  // Lock to portrait (optional — remove for tablet/landscape support)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: AiChartAnalyzerApp()));
}

class AiChartAnalyzerApp extends ConsumerStatefulWidget {
  const AiChartAnalyzerApp({super.key});

  @override
  ConsumerState<AiChartAnalyzerApp> createState() =>
      _AiChartAnalyzerAppState();
}

class _AiChartAnalyzerAppState extends ConsumerState<AiChartAnalyzerApp> {
  bool _disclaimerShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disclaimerShown) {
        _disclaimerShown = true;
        _showStartupDisclaimer();
      }
    });
  }

  void _showStartupDisclaimer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldSoft]),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: const Icon(Icons.candlestick_chart_rounded,
                  color: AppColors.bg, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Important Notice',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Insets.sm + 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.07),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: const Text(
                AppConstants.startupDisclaimer,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This app uses OpenAI Vision to analyze chart images. '
              'All analyses are for educational purposes only and should '
              'never be treated as financial advice.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'I Understand',
                  style: TextStyle(
                      color: AppColors.bg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
