import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/promise_group_bloc.dart';
import '../../../../common/widgets/nothing_verse_card.dart';
import '../../../promise_box/domain/entities/bible_verse.dart';

class PromiseGroupPage extends StatefulWidget {
  const PromiseGroupPage({super.key});

  // Static method to show the Group Selection Overlay
  static void showSidebarOverlay(BuildContext context, PromiseGroupOverview state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'SHARED SPACES',
                  style: GoogleFonts.ibmPlexMono(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    context.read<PromiseGroupBloc>().add(const SelectGroupEvent(null));
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'ADD NEW',
                      style: GoogleFonts.ibmPlexMono(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: state.groups.isEmpty 
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No active pairs found.',
                      style: GoogleFonts.ibmPlexMono(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = state.groups[index];
                      final isSelected = state.activeGroupId == group.id;
                      final members = group['members'] as List? ?? [];
                      
                      String groupInitials = "";
                      if (members.length >= 2) {
                        final u1 = members[0].toString().split('@')[0][0];
                        final u2 = members[1].toString().split('@')[0][0];
                        groupInitials = "$u1$u2".toUpperCase();
                      } else if (members.isNotEmpty) {
                        groupInitials = members[0].toString()[0].toUpperCase();
                      }
                      
                      final avatarColor = Colors.primaries[group.id.length % Colors.primaries.length];

                      return GestureDetector(
                        onTap: () {
                          context.read<PromiseGroupBloc>().add(SelectGroupEvent(group.id));
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.white10 : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: avatarColor.withValues(alpha: isSelected ? 1.0 : 0.4),
                                child: Text(
                                  groupInitials,
                                  style: GoogleFonts.ibmPlexMono(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pair: $groupInitials",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Shared Promise Feed",
                                    style: GoogleFonts.ibmPlexMono(
                                      color: Colors.white24,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (isSelected) 
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  State<PromiseGroupPage> createState() => _PromiseGroupPageState();
}

class _PromiseGroupPageState extends State<PromiseGroupPage> {
  List<BibleVerse> _localVerses = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadLocalVerses();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<PromiseGroupBloc>().add(
        FetchUserGroupsEvent(authState.user.uid, authState.user.email!)
      );
    }
  }

  Future<void> _loadLocalVerses() async {
    try {
      final String response = await rootBundle.loadString('assets/data/bible_verses.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _localVerses = data.map((json) => BibleVerse(
          book: json['book'] ?? '',
          chapter: json['chapter'] ?? '',
          verse: json['verse'] ?? '',
          sentence: json['sentence'] ?? '',
        )).toList();
      });
    } catch (e) {
      debugPrint('Error loading verses: $e');
    }
  }

  void _shareRandomVerse() {
    if (_localVerses.isEmpty) return;
    final randomVerse = _localVerses[Random().nextInt(_localVerses.length)];
    context.read<PromiseGroupBloc>().add(SendSharedVerseEvent(randomVerse));
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromiseGroupBloc, PromiseGroupState>(
      builder: (context, state) {
        if (state is PromiseGroupLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        } else if (state is PromiseGroupOverview) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: state.activeGroupId == null 
                ? _buildDiscoveryUI(state) 
                : _buildSharedFeed(state),
          );
        } else if (state is PromiseGroupError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDiscoveryUI(PromiseGroupOverview state) {
    final authState = context.read<AuthBloc>().state as Authenticated;
    final users = state.allUsers.where((u) {
      final email = u['email'] as String;
      final name = (u['displayName'] ?? "") as String;
      return email != authState.user.email && 
             (email.toLowerCase().contains(_searchQuery.toLowerCase()) || 
              name.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DISCOVER USERS', style: GoogleFonts.ibmPlexMono(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 24),
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            hintStyle: GoogleFonts.ibmPlexMono(color: Colors.white24, fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: users.isEmpty
            ? Center(child: Text('No users found', style: GoogleFonts.ibmPlexMono(color: Colors.white10, fontSize: 12)))
            : ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final name = user['displayName'] ?? "Anonymous";
                  final email = user['email'] as String;
                  final uid = user['uid'] as String;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: Colors.white10, radius: 18, child: Text(name[0].toUpperCase())),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<PromiseGroupBloc>().add(JoinGroupEvent(
                              authState.user.uid, uid, authState.user.email!, email,
                            ));
                          },
                          child: Text('CONNECT', style: GoogleFonts.ibmPlexMono(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSharedFeed(PromiseGroupOverview state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRIVATE FEED', style: GoogleFonts.ibmPlexMono(color: Colors.white30, fontSize: 10, letterSpacing: 2)),
              GestureDetector(
                onTap: _shareRandomVerse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('+ SHARE', style: GoogleFonts.ibmPlexMono(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (state.verses.isEmpty)
            const Center(child: Text('Share a promise to begin...', style: TextStyle(color: Colors.white10, fontSize: 12)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.verses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final item = state.verses[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.senderName.toUpperCase()} · ${DateFormat('HH:mm').format(item.createdAt)}',
                      style: GoogleFonts.ibmPlexMono(color: Colors.white24, fontSize: 9),
                    ),
                    const SizedBox(height: 8),
                    NothingVerseCard(
                      verse: BibleVerse(book: item.book, chapter: item.chapter, verse: item.verse, sentence: item.sentence),
                      onRefresh: () {},
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
