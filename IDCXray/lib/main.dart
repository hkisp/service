import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: IdcColors.bg,
    ),
  );
  runApp(const IdcXrayApp());
}

class IdcXrayApp extends StatelessWidget {
  const IdcXrayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDCXray',
      debugShowCheckedModeBanner: false,
      theme: buildIdcTheme(brightness: Brightness.light),
      darkTheme: buildIdcTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
