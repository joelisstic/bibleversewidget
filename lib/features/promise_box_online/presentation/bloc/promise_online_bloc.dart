import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entities/bible_verse_online.dart';
import '../../domain/repositories/bible_online_repository.dart';

// Events
abstract class PromiseOnlineEvent extends Equatable {
  const PromiseOnlineEvent();
  @override
  List<Object> get props => [];
}

class LoadOnlineVersesEvent extends PromiseOnlineEvent {}

class GetRandomOnlineVerseEvent extends PromiseOnlineEvent {}

class UpdateOnlineWidgetEvent extends PromiseOnlineEvent {
  final BibleVerseOnline verse;
  const UpdateOnlineWidgetEvent(this.verse);
}

// States
abstract class PromiseOnlineState extends Equatable {
  const PromiseOnlineState();
  @override
  List<Object?> get props => [];
}

class PromiseOnlineInitial extends PromiseOnlineState {}

class PromiseOnlineLoading extends PromiseOnlineState {}

class PromiseOnlineLoaded extends PromiseOnlineState {
  final List<BibleVerseOnline> allVerses;
  final BibleVerseOnline? currentVerse;

  const PromiseOnlineLoaded({required this.allVerses, this.currentVerse});

  @override
  List<Object?> get props => [allVerses, currentVerse];
}

class PromiseOnlineError extends PromiseOnlineState {
  final String message;
  const PromiseOnlineError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class PromiseOnlineBloc extends Bloc<PromiseOnlineEvent, PromiseOnlineState> {
  final BibleOnlineRepository repository;

  PromiseOnlineBloc({required this.repository}) : super(PromiseOnlineInitial()) {
    on<LoadOnlineVersesEvent>((event, emit) async {
      emit(PromiseOnlineLoading());
      try {
        final verses = await repository.getRemoteVerses();
        emit(PromiseOnlineLoaded(allVerses: verses));
      } catch (e) {
        emit(PromiseOnlineError(e.toString()));
      }
    });

    on<GetRandomOnlineVerseEvent>((event, emit) {
      if (state is PromiseOnlineLoaded) {
        final currentState = state as PromiseOnlineLoaded;
        if (currentState.allVerses.isNotEmpty) {
          final randomVerse = currentState.allVerses[Random().nextInt(currentState.allVerses.length)];
          
          add(UpdateOnlineWidgetEvent(randomVerse));

          emit(PromiseOnlineLoaded(
            allVerses: currentState.allVerses,
            currentVerse: randomVerse,
          ));
        }
      }
    });

    on<UpdateOnlineWidgetEvent>((event, emit) async {
      await HomeWidget.saveWidgetData<String>('widget_quote', event.verse.sentence);
      await HomeWidget.saveWidgetData<String>('widget_reference', event.verse.reference);
      await HomeWidget.updateWidget(
        name: 'BibleVerseWidgetProvider',
        androidName: 'BibleVerseWidgetProvider',
      );
    });
  }
}
