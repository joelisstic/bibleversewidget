import 'dart:convert';
import 'dart:math';
import 'package:bible_verse_widget/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'features/promise_box/presentation/bloc/promise_bloc.dart';
import 'features/promise_box_online/presentation/bloc/promise_online_bloc.dart';
import 'features/promise_box_group/presentation/bloc/promise_group_bloc.dart';
import 'features/promise_box/presentation/pages/promise_box_page.dart';
import 'features/promise_box/data/models/bible_verse_model.dart';
import 'injection_container.dart' as di;
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> updateWidgetVerse() async {
  try {
    final String response = await rootBundle.loadString('assets/data/bible_verses.json');
    final List<dynamic> data = json.decode(response);
    final verses = data.map((json) => BibleVerseModel.fromJson(json)).toList();
    
    if (verses.isNotEmpty) {
      final randomVerse = verses[Random().nextInt(verses.length)];
      
      await HomeWidget.saveWidgetData<String>('widget_quote', randomVerse.sentence);
      await HomeWidget.saveWidgetData<String>('widget_reference', randomVerse.reference);
      await HomeWidget.updateWidget(
        name: 'BibleVerseWidgetProvider',
        androidName: 'BibleVerseWidgetProvider',
      );
    }
  } catch (e) {
    debugPrint('Widget update error: $e');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await updateWidgetVerse();
    return Future.value(true);
  });
}

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'update_verse') {
    await updateWidgetVerse();
  }
}

void main() async {
  // 1. Initialize Widgets Binding FIRST
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase SECOND
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // 3. Initialize Dependency Injection
  await di.init();
  
  // 4. Initialize Background Tasks
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      "daily_verse_update",
      "update_widget_task",
      frequency: const Duration(hours: 24),
    );
  } catch (e) {
    debugPrint('Workmanager error: $e');
  }

  // 5. Register Widget Interactivity
  try {
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  } catch (e) {
    debugPrint('HomeWidget error: $e');
  }

  runApp(const PromiseBoxApp());
}

class PromiseBoxApp extends StatelessWidget {
  const PromiseBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),

        BlocProvider(create: (_) => di.sl<PromiseBloc>()..add(LoadVersesEvent())),
        BlocProvider(create: (_) => di.sl<PromiseOnlineBloc>()),
        BlocProvider(create: (_) => di.sl<PromiseGroupBloc>()),
      ],
      child: MaterialApp(
        title: 'Promise Box',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const PromiseBoxPage(),
      ),
    );
  }
}
