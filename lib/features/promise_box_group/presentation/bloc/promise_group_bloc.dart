import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:workmanager/workmanager.dart';
import '../../../../common/services/notification_service.dart';
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
}

class FetchAllUsersEvent extends PromiseGroupEvent {}

class JoinGroupEvent extends PromiseGroupEvent {
  final String myUid;
  final String partnerUid;
  final String myEmail;
  final String partnerEmail;
  const JoinGroupEvent(this.myUid, this.partnerUid, this.myEmail, this.partnerEmail);
}

class SelectGroupEvent extends PromiseGroupEvent {
  final String? groupId;
  const SelectGroupEvent(this.groupId);
}

class SendSharedVerseEvent extends PromiseGroupEvent {
  final BibleVerse verse;
  const SendSharedVerseEvent(this.verse);
}

class _UpdateGroupsEvent extends PromiseGroupEvent {
  final List<DocumentSnapshot> groupDocs;
  const _UpdateGroupsEvent(this.groupDocs);
}

class _UpdateUsersEvent extends PromiseGroupEvent {
  final List<DocumentSnapshot> userDocs;
  const _UpdateUsersEvent(this.userDocs);
}

class _UpdateVersesEvent extends PromiseGroupEvent {
  final List<SharedVerseModel> verses;
  const _UpdateVersesEvent(this.verses);
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
  final bool canShareToday;
  final int mannaScore;
  final bool isMannaExpiring;

  const PromiseGroupOverview({
    required this.myEmail,
    required this.myUid,
    required this.groups,
    required this.allUsers,
    this.activeGroupId,
    this.verses = const [],
    this.canShareToday = true,
    this.mannaScore = 0,
    this.isMannaExpiring = false,
  });

  @override
  List<Object?> get props => [myEmail, myUid, groups, allUsers, activeGroupId, verses, canShareToday, mannaScore, isMannaExpiring];
}

class PromiseGroupError extends PromiseGroupState {
  final String message;
  const PromiseGroupError(this.message);
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
      _cachedMyEmail = event.userEmail;
      _cachedMyUid = event.userUid;

      emit(PromiseGroupOverview(
        myEmail: _cachedMyEmail,
        myUid: _cachedMyUid,
        groups: const [],
        allUsers: const [],
        activeGroupId: null,
        verses: const [],
      ));

      _groupsSubscription?.cancel();
      _groupsSubscription = _firestore
          .collection('groups_sharing')
          .where('memberUids', arrayContains: event.userUid)
          .snapshots()
          .listen((snapshot) {
        add(_UpdateGroupsEvent(snapshot.docs));
      });

      add(FetchAllUsersEvent());
    });

    on<FetchAllUsersEvent>((event, emit) async {
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        add(_UpdateUsersEvent(usersSnapshot.docs));
      } catch (e) {
        debugPrint('PromiseGroupBloc: Users fetch failed: $e');
      }
    });

    on<_UpdateGroupsEvent>((event, emit) {
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        
        int manna = 0;
        bool expiring = false;
        if (currentState.activeGroupId != null) {
          try {
            final activeGroupDoc = event.groupDocs.firstWhere((doc) => doc.id == currentState.activeGroupId);
            final data = activeGroupDoc.data() as Map<String, dynamic>?;
            if (data != null) {
              manna = data['manna_score'] ?? 0;
              final lastShared = data['last_shared_at'] as Timestamp?;
              if (lastShared != null) {
                final diff = DateTime.now().difference(lastShared.toDate());
                // DEBUG: Reset streak if 1 minute has passed
                if (diff.inMinutes >= 1) {
                  manna = 0;
                } else if (diff.inSeconds >= 30) {
                  expiring = true;
                }
              }
            }
          } catch (_) {}
        }

        emit(PromiseGroupOverview(
          myEmail: currentState.myEmail,
          myUid: currentState.myUid,
          groups: event.groupDocs,
          allUsers: currentState.allUsers,
          activeGroupId: currentState.activeGroupId,
          verses: currentState.verses,
          canShareToday: currentState.canShareToday,
          mannaScore: manna,
          isMannaExpiring: expiring,
        ));
      }
    });

    on<_UpdateUsersEvent>((event, emit) {
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        emit(PromiseGroupOverview(
          myEmail: currentState.myEmail,
          myUid: currentState.myUid,
          groups: currentState.groups,
          allUsers: event.userDocs,
          activeGroupId: currentState.activeGroupId,
          verses: currentState.verses,
          canShareToday: currentState.canShareToday,
          mannaScore: currentState.mannaScore,
          isMannaExpiring: currentState.isMannaExpiring,
        ));
      }
    });

    on<JoinGroupEvent>((event, emit) async {
      final uids = [event.myUid, event.partnerUid]..sort();
      final emails = [event.myEmail, event.partnerEmail]..sort();
      final groupId = "${uids[0]}%and%${uids[1]}";
      
      try {
        await _firestore.collection('groups_sharing').doc(groupId).set({
          'members': emails,
          'memberUids': uids,
          'last_updated': FieldValue.serverTimestamp(),
          'manna_score': 0,
          'shared_today_uids': [],
        }, SetOptions(merge: true));
        
        add(SelectGroupEvent(groupId));
      } catch (e) {
        emit(PromiseGroupError(e.toString()));
      }
    });

    on<SelectGroupEvent>((event, emit) {
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        _versesSubscription?.cancel();
        
        int manna = 0;
        bool expiring = false;
        if (event.groupId != null && event.groupId!.isNotEmpty) {
          _versesSubscription = _firestore
              .collection('groups_sharing')
              .doc(event.groupId!)
              .collection('verses')
              .orderBy('CREATED_AT', descending: true)
              .snapshots()
              .listen((snapshot) {
            final verses = snapshot.docs
                .map((doc) => SharedVerseModel.fromJson(doc.data()))
                .toList();
            add(_UpdateVersesEvent(verses));
          });

          try {
            final groupDoc = currentState.groups.firstWhere((doc) => doc.id == event.groupId);
            final data = groupDoc.data() as Map<String, dynamic>?;
            if (data != null) {
              manna = data['manna_score'] ?? 0;
              final lastShared = data['last_shared_at'] as Timestamp?;
              if (lastShared != null) {
                final diff = DateTime.now().difference(lastShared.toDate());
                if (diff.inMinutes >= 1) manna = 0;
                else if (diff.inSeconds >= 30) expiring = true;
              }
            }
          } catch (_) {}
        }

        emit(PromiseGroupOverview(
          myEmail: currentState.myEmail,
          myUid: currentState.myUid,
          groups: currentState.groups,
          allUsers: currentState.allUsers,
          activeGroupId: event.groupId,
          verses: const [],
          canShareToday: true,
          mannaScore: manna,
          isMannaExpiring: expiring,
        ));
      }
    });

    on<_UpdateVersesEvent>((event, emit) {
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        
        final senderName = currentState.myEmail.split('@')[0];
        final now = DateTime.now();
        
        // DEBUG: Changed daily limit to 1 minute
        final alreadySharedRecently = event.verses.any((v) {
          return v.senderName == senderName &&
              now.difference(v.createdAt).inSeconds < 60;
        });

        emit(PromiseGroupOverview(
          myEmail: currentState.myEmail,
          myUid: currentState.myUid,
          groups: currentState.groups,
          allUsers: currentState.allUsers,
          activeGroupId: currentState.activeGroupId,
          verses: event.verses,
          canShareToday: !alreadySharedRecently,
          mannaScore: currentState.mannaScore,
          isMannaExpiring: currentState.isMannaExpiring,
        ));
      }
    });

    on<SendSharedVerseEvent>((event, emit) async {
      if (state is PromiseGroupOverview) {
        final currentState = state as PromiseGroupOverview;
        if (currentState.activeGroupId == null || currentState.activeGroupId!.isEmpty) return;

        if (!currentState.canShareToday) {
          emit(const PromiseGroupError("DAILY_LIMIT_REACHED"));
          return;
        }

        final groupId = currentState.activeGroupId!;
        final groupRef = _firestore.collection('groups_sharing').doc(groupId);
        final myName = currentState.myEmail.split('@')[0];
        final verseRef = "${event.verse.book} ${event.verse.chapter}:${event.verse.verse}";
        
        await _firestore.runTransaction((transaction) async {
          final groupSnapshot = await transaction.get(groupRef);
          if (!groupSnapshot.exists) return;

          final groupData = groupSnapshot.data() as Map<String, dynamic>;
          int currentManna = groupData['manna_score'] ?? 0;
          List sharedToday = List.from(groupData['shared_today_uids'] ?? []);
          final lastStreakUpdate = groupData['streak_last_updated_at'] as Timestamp?;
          final lastSharedAt = groupData['last_shared_at'] as Timestamp?;

          final now = DateTime.now();
          
          // DEBUG: 1 minute reset logic
          if (lastSharedAt != null) {
            if (now.difference(lastSharedAt.toDate()).inMinutes >= 1) {
              currentManna = 0;
              sharedToday = [];
            }
          }

          // DEBUG: Reset sharedToday list if 1 minute has passed since last streak update
          if (lastStreakUpdate != null) {
            final lastDate = lastStreakUpdate.toDate();
            if (now.difference(lastDate).inMinutes >= 1) {
              sharedToday = [];
            }
          }

          if (!sharedToday.contains(_cachedMyUid)) {
            sharedToday.add(_cachedMyUid);
          }

          bool incremented = false;
          if (sharedToday.length >= 2) {
            if (lastStreakUpdate == null || 
                now.difference(lastStreakUpdate.toDate()).inMinutes >= 1) {
              currentManna += 1;
              incremented = true;
            }
          }

          final sharedVerse = SharedVerseModel(
            book: event.verse.book,
            chapter: event.verse.chapter,
            verse: event.verse.verse,
            sentence: event.verse.sentence,
            senderName: myName,
            createdAt: now,
          );

          transaction.set(groupRef.collection('verses').doc(), {
            ...sharedVerse.toJson(),
            'CREATED_AT': FieldValue.serverTimestamp(),
          });

          transaction.update(groupRef, {
            'manna_score': currentManna,
            'last_shared_at': FieldValue.serverTimestamp(),
            'shared_today_uids': sharedToday,
            if (incremented) 'streak_last_updated_at': FieldValue.serverTimestamp(),
          });
        });

        // Trigger push notification to partner
        NotificationService.sendNotificationToPartner(
          groupId: groupId,
          senderName: myName,
          verseText: verseRef,
        );

        // DEBUG: Schedule a reminder notification to fire in 1 minute
        Workmanager().registerOneOffTask(
          "debug_streak_reminder_${DateTime.now().millisecond}",
          "manna_streak_check",
          initialDelay: const Duration(minutes: 1),
          constraints: Constraints(networkType: NetworkType.connected),
        );
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
