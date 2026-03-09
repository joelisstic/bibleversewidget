import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'features/promise_box/presentation/bloc/promise_bloc.dart';
import 'features/promise_box/presentation/pages/promise_box_page.dart';
import 'features/promise_box/data/models/bible_verse_model.dart';
import 'injection_container.dart' as di;

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
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  
  // Register Workmanager for periodic daily updates
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    "daily_verse_update",
    "update_widget_task",
    frequency: const Duration(hours: 24),
  );

  // Register background callback for widget taps
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  runApp(const PromiseBoxApp());
}

class PromiseBoxApp extends StatelessWidget {
  const PromiseBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: BlocProvider(
        create: (_) => di.sl<PromiseBloc>()..add(LoadVersesEvent()),
        child: const PromiseBoxPage(),
      ),
    );
  }
}
