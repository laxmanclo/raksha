import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/call_service.dart';
import 'services/threat_service.dart';
import 'services/asr_service.dart';
import 'services/microphone_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RakshaApp());
}

class RakshaApp extends StatelessWidget {
  const RakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallService()),
        ChangeNotifierProvider(create: (_) => ThreatService()),
        ChangeNotifierProvider(create: (_) => AsrService()),
        ChangeNotifierProvider(create: (_) => MicrophoneService()),
      ],
      child: MaterialApp(
        title: 'Raksha',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: const Color(0xFF34C759),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF34C759),
            secondary: Color(0xFF30D158),
            surface: Color(0xFF111111),
            error: Color(0xFFFF453A),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF111111),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFF1A1A1A),
            thickness: 0.5,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
