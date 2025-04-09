import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/pages/login_register.dart';
import 'package:flutterilk/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lxdxswcfjyxbiyofvwkt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4ZHhzd2Nmanl4Yml5b2Z2d2t0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3Nzc1MjksImV4cCI6MjA1NzM1MzUyOX0.xMDumCcc9QssCQPR77PThnMFPltLbroiav7NNv9OsZA',                      // ← replace with your Supabase anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlazeSense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Supabase.instance.client.auth.currentSession != null
          ? const MainPage()  // User is logged in
          : const LoginRegisterPage(), // User is not logged in
    );
  }
}

