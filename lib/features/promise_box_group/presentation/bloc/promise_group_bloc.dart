import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../promise_box/domain/entities/bible_verse.dart';
import '../../data/models/shared_verse_model.dart';

// Events
abstract class PromiseGroupEvent extends Equatable {
  const PromiseGroupEvent();
  @override
  List<Object?> get props => [];
}

class FetchUserGroupsEvent extends PromiseGroupEvent {
  final String userUid;
  final String userEmail;
  const FetchUserGroupsEvent(this.userUid, this.userEmail);
  @override
  List<Object?> get props => [userUid, userEmail];
}

class FetchAllUsersEvent extends PromiseGroupEvent {}

class JoinGroupEvent extends PromiseGroupEvent {
  final String myUid;
  final String partnerUid;
  final String myEmail;
  final String partnerEmail;
  const JoinGroupEvent(this.myUid, this.partnerUid, this.myEmail, this.partnerEmail);
  @override
  List<Object?> get props => [myUid, partnerUid, myEmail, partnerEmail];
}

class SelectGroupEvent extends PromiseGroupEvent {
  final String? groupId;
  const SelectGroupEvent(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class SendSharedVerseEvent extends PromiseGroupEvent {
  final BibleVerse verse;
  const SendSharedVerseEvent(this.verse);
  @override
  List<Object?> get props => [verse];
}

class _UpdateGroupsEvent extends PromiseGroupEvent {
  final List<DocumentSnapshot> groupDocs;
  const _UpdateGroupsEvent(this.groupDocs);
  @override
  List<Object?> get props => [groupDocs];
}

class _UpdateUsersEvent extends PromiseGroupEvent {
  final List<DocumentSnapshot> userDocs;
  const _UpdateUsersEvent(this.userDocs);
  @override
  List<Object?> get props => [userDocs];
}

class _UpdateVersesEvent extends PromiseGroupEvent {
  final List<SharedVerseModel> verses;
  const _UpdateVersesEvent(this.verses);
  @override
  List<Object?> get props => [verses];
}

// States
abstract class PromiseGroupState extends Equatable {
  const PromiseGroupState();
  @override
  List<Object?> get props => [];
}

class PromiseGroupInitial extends PromiseGroupState {}

class PromiseGroupLoading extends PromiseGroupState {}

class PromiseGroupOverview extends PromiseGroupState {
  final String myEmail;
  final String myUid;
  final List<DocumentSnapshot> groups;
  final List<DocumentSnapshot> allUsers;
  final String? activeGroupId;
  final List<SharedVerseModel> verses;

  const PromiseGroupOverview({
    required this.myEmail,
    required this.myUid,
    required this.groups,
    required this.allUsers,
    this.activeGroupId,
    this.verses = const [],
  });

  @override
  List<Object?> get props => [myEmail, myUid, groups, allUsers, activeGroupId, verses];
}

class PromiseGroupError extends PromiseGroupState {
  final String message;
  const PromiseGroupError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PromiseGroupBloc extends Bloc<PromiseGroupEvent, PromiseGroupState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _groupsSubscription;
  StreamSubscription? _versesSubscription;
  String _cachedMyEmail = "";
  String _cachedMyUid = "";

  PromiseGroupBloc() : super(PromiseGroupInitial()) {
    on<FetchUserGroupsEvent>((event, emit) {
      debugPrint('PromiseGroupBloc: FetchUserGroupsEvent for ${event.userEmail}');
      emit(PromiseGroupLoading());
      _cachedMyEmail = event.userEmail;
      _cachedMyUid = event.userUid;
      _groupsSubscription?.cancel();
      _groupsSubscription = _firestore
          .collection('groups_sharing')
          .where('memberUids', arrayContains: event.userUid)
          .snapshots()
          .listen((snapshot) {
        debugPrint('PromiseGroupBloc: Received ${snapshot.docs.length} groups from Firestore');
        add(_UpdateGroupsEvent(snapshot.docs));
      });
      add(FetchAllUsersEvent());
    });

    on<FetchAllUsersEvent>((event, emit) async {
      debugPrint('PromiseGroupBloc: FetchAllUsersEvent started');
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        debugPrint('PromiseGroupBloc: Fetched ${usersSnapshot.docs.length} total users from Firestore');
        add(_UpdateUsersEvent(usersSnapshot.docs));
      } catch (e) {
        debugPrint('PromiseGroupBloc: Error fetching users: $e');
      }
    });

    on<_UpdateGroupsEvent>((event, emit) {
      final currentAllUsers = state is PromiseGroupOverview ? (state as PromiseGroupOverview).allUsers : <DocumentSnapshot>[];
      final currentActiveId = state is PromiseGroupOverview ? (state as PromiseGroupOverview).activeGroupId : null;
      final currentVerses = state is PromiseGroupOverview ? (state as PromiseGroupOverview).verses : <SharedVerseModel>[];

      emit(PromiseGroupOverview(
        myEmail: _cachedMyEmail,
        myUid: _cachedMyUid,
        groups: event.groupDocs,
        allUsers: currentAllUsers,
        activeGroupId: currentActiveId,
        verses: currentVerses,
      ));
    });

    on<_UpdateUsersEvent>((event, emit) {
      debugPrint('PromiseGroupBloc: _UpdateUsersEvent with ${event.userDocs.length} users');
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        emit(PromiseGroupOverview(
          myEmail: currentState.myEmail,
          myUid: currentState.myUid,
          groups: currentState.groups,
          allUsers: event.userDocs,
          activeGroupId: currentState.activeGroupId,
          verses: currentState.verses,
        ));
      } else {
        // Handle case where state is still Loading or Initial
        emit(PromiseGroupOverview(
          myEmail: _cachedMyEmail,
          myUid: _cachedMyUid,
          groups: const [],
          allUsers: event.userDocs,
          activeGroupId: null,
          verses: const [],
        ));
      }
    });

    on<JoinGroupEvent>((event, emit) async {
      debugPrint('PromiseGroupBloc: JoinGroupEvent with partner ${event.partnerEmail}');
      final uids = [event.myUid, event.partnerUid]..sort();
      final emails = [event.myEmail, event.partnerEmail]..sort();
      final groupId = "${uids[0]}%and%${uids[1]}";
      
      try {
        await _firestore.collection('groups_sharing').doc(groupId).set({
          'members': emails,
          'memberUids': uids,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        add(SelectGroupEvent(groupId));
      } catch (e) {
        debugPrint('PromiseGroupBloc: Error joining group: $e');
        emit(PromiseGroupError(e.toString()));
      }
    });

    on<SelectGroupEvent>((event, emit) {
      debugPrint('PromiseGroupBloc: SelectGroupEvent for ${event.groupId}');
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        _versesSubscription?.cancel();
        
        if (event.groupId != null && event.groupId!.isNotEmpty) {
          _versesSubscription = _firestore
              .collection('groups_sharing')
              .doc(event.groupId)
              .collection('verses')
              .orderBy('CREATED_AT', descending: true)
              .snapshots()
              .listen((snapshot) {
            final verses = snapshot.docs
                .map((doc) => SharedVerseModel.fromJson(doc.data()))
                .toList();
            add(_UpdateVersesEvent(verses));
          });
        }

        emit(PromiseGroupOverview(
          myEmail: currentState.myEmail,
          myUid: currentState.myUid,
          groups: currentState.groups,
          allUsers: currentState.allUsers,
          activeGroupId: event.groupId,
          verses: [],
        ));
      }
    });

    on<_UpdateVersesEvent>((event, emit) {
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        emit(PromiseGroupOverview(
          myEmail: currentState.myEmail,
          myUid: currentState.myUid,
          groups: currentState.groups,
          allUsers: currentState.allUsers,
          activeGroupId: currentState.activeGroupId,
          verses: event.verses,
        ));
      }
    });

    on<SendSharedVerseEvent>((event, emit) async {
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        if (currentState.activeGroupId == null || currentState.activeGroupId!.isEmpty) return;

        final sharedVerse = SharedVerseModel(
          book: event.verse.book,
          chapter: event.verse.chapter,
          verse: event.verse.verse,
          sentence: event.verse.sentence,
          senderName: currentState.myEmail.split('@')[0],
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('groups_sharing')
            .doc(currentState.activeGroupId!)
            .collection('verses')
            .add(sharedVerse.toJson());
      }
    });
  }

  @override
  Future<void> close() {
    _groupsSubscription?.cancel();
    _versesSubscription?.cancel();
    return super.close();
  }
}
