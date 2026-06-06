import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/promise_group_bloc.dart';
import '../../../../common/widgets/nothing_verse_card.dart';
import '../../../promise_box/domain/entities/bible_verse.dart';

class PromiseGroupPage extends StatefulWidget {
  const PromiseGroupPage({super.key});

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
                    child: Center(
                      child: Text(
                        'No active pairs found.',
                        style: GoogleFonts.ibmPlexMono(color: Colors.white24, fontSize: 12),
                      ),
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
                      final mannaScore = group['manna_score'] ?? 0;

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
                                    "Private Pair: $groupInitials",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.white24,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$mannaScore MANNA",
                                        style: GoogleFonts.ibmPlexMono(
                                          color: Colors.white24,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
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
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
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
    final currentState = context.read<PromiseGroupBloc>().state;
    if (currentState is PromiseGroupOverview && !currentState.canShareToday) {
      _showLimitReachedPopup();
      return;
    }

    if (_localVerses.isEmpty) return;
    final randomVerse = _localVerses[Random().nextInt(_localVerses.length)];
    context.read<PromiseGroupBloc>().add(SendSharedVerseEvent(randomVerse));
    HapticFeedback.heavyImpact();
  }

  void _showLimitReachedPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        title: Text(
          'DAILY LIMIT REACHED',
          style: GoogleFonts.ibmPlexMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        content: Text(
          'Your daily limit for your connection has reached its limit. Share your verse tomorrow.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OKAY', style: GoogleFonts.ibmPlexMono(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddCustomVerseDialog() {
    final currentState = context.read<PromiseGroupBloc>().state;
    if (currentState is PromiseGroupOverview && !currentState.canShareToday) {
      _showLimitReachedPopup();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BibleVersePickerOverlay(),
    );
  }

  Future<void> _addToHome(BibleVerse verse) async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_quote', verse.sentence);
      await HomeWidget.saveWidgetData<String>('widget_reference', verse.reference);
      await HomeWidget.updateWidget(
        name: 'BibleVerseWidgetProvider',
        androidName: 'BibleVerseWidgetProvider',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Home Screen', style: GoogleFonts.ibmPlexMono()),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving to home widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is Authenticated) {
          context.read<PromiseGroupBloc>().add(
            FetchUserGroupsEvent(authState.user.uid, authState.user.email!)
          );
        }
      },
      child: BlocBuilder<PromiseGroupBloc, PromiseGroupState>(
        builder: (context, state) {
          if (state is PromiseGroupOverview) {
            return SizedBox.expand(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: state.activeGroupId == null 
                        ? _buildDiscoveryUI(state, key: const ValueKey('discovery')) 
                        : _buildSharedFeed(state, key: const ValueKey('feed')),
                  ),
                ),
              ),
            );
          } else if (state is PromiseGroupError) {
            if (state.message == "DAILY_LIMIT_REACHED") {
              final prevState = (context.read<PromiseGroupBloc>().state as PromiseGroupOverview);
              return _buildSharedFeed(prevState, key: const ValueKey('feed'));
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(state.message, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)
                ),
              ),
            );
          }
          
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
      ),
    );
  }

  Widget _buildDiscoveryUI(PromiseGroupOverview state, {required Key key}) {
    final authState = context.read<AuthBloc>().state as Authenticated;
    final users = state.allUsers.where((u) {
      final email = u['email'] as String;
      final name = (u['displayName'] ?? "") as String;
      return email != authState.user.email && 
             (email.toLowerCase().contains(_searchQuery.toLowerCase()) || 
              name.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DISCOVER USERS', style: GoogleFonts.ibmPlexMono(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 24),
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search partner...',
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
            ? Center(child: Text('Search for a partner above...', style: GoogleFonts.ibmPlexMono(color: Colors.white30, fontSize: 12)))
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
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
                      border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: Colors.white10, radius: 18, child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12))),
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

  Widget _buildSharedFeed(PromiseGroupOverview state, {required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIVATE FEED', style: GoogleFonts.ibmPlexMono(color: Colors.white30, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 4),
                _buildMannaCounter(state),
              ],
            ),
            Row(
              children: [
                _buildSmallActionBtn(
                  icon: Icons.menu_book_rounded,
                  label: 'SELECT',
                  onTap: _showAddCustomVerseDialog,
                ),
                const SizedBox(width: 12),
                _buildSmallActionBtn(
                  icon: Icons.auto_awesome_rounded,
                  label: 'RANDOM',
                  onTap: _shareRandomVerse,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: state.verses.isEmpty
            ? Center(
                child: Text(
                  'Select a group from the overlay \nor connect with a user to begin...', 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexMono(color: Colors.white30, fontSize: 12)
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: state.verses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final item = state.verses[index];
                  final verse = BibleVerse(book: item.book, chapter: item.chapter, verse: item.verse, sentence: item.sentence);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '${item.senderName.toUpperCase()} · ${DateFormat('HH:mm · MMM d').format(item.createdAt)}',
                          style: GoogleFonts.ibmPlexMono(color: Colors.white24, fontSize: 9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      NothingVerseCard(
                        verse: verse,
                        onRefresh: () {}, 
                        onAddToHome: () => _addToHome(verse),
                      ),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildMannaCounter(PromiseGroupOverview state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: state.isMannaExpiring ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          '${state.mannaScore} MANNA',
          style: GoogleFonts.ibmPlexMono(
            color: state.isMannaExpiring ? Colors.white30 : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BibleVersePickerOverlay extends StatefulWidget {
  const BibleVersePickerOverlay({super.key});

  @override
  State<BibleVersePickerOverlay> createState() => _BibleVersePickerOverlayState();
}

class _BibleVersePickerOverlayState extends State<BibleVersePickerOverlay> {
  String? selectedBook;
  String? selectedChapter;
  String? selectedVerse;
  String? verseText;

  List<String> books = [];
  List<String> chapters = [];
  List<String> verses = [];

  bool isLoading = false;

  // Static list for Biblical Order (canonical sequence)
  static const List<String> bibleOrder = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth", 
    "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra", 
    "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon", 
    "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos", 
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", 
    "Malachi", "Matthew", "Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians", 
    "2 Corinthians", "Galatians", "Ephesians", "Philippians", "Colossians", "1 Thessalonians", 
    "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James", 
    "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"
  ];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('ALL_BIBLE_VERSES').get();
      final fetchedBooks = snapshot.docs.map((doc) => doc.id).toList();
      
      // Sort the fetched books based on the standard Bible order
      fetchedBooks.sort((a, b) {
        final indexA = bibleOrder.indexOf(a);
        final indexB = bibleOrder.indexOf(b);
        // Handle cases where a book might not be in our static list (fallback to alphabetical)
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

      setState(() {
        books = fetchedBooks;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching books: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchChapters(String book) async {
    setState(() {
      isLoading = true;
      chapters = [];
      selectedChapter = null;
      selectedVerse = null;
      verseText = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ALL_BIBLE_VERSES')
          .doc(book)
          .collection('chapters')
          .get();
      setState(() {
        chapters = snapshot.docs.map((doc) => doc.id).toList();
        // Numeric sort for strings
        chapters.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching chapters: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchVerses(String book, String chapter) async {
    setState(() {
      isLoading = true;
      verses = [];
      selectedVerse = null;
      verseText = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ALL_BIBLE_VERSES')
          .doc(book)
          .collection('chapters')
          .doc(chapter)
          .collection('verses')
          .get();
      setState(() {
        verses = snapshot.docs.map((doc) => doc.id).toList();
        verses.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching verses: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchVerseText(String book, String chapter, String verse) async {
    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ALL_BIBLE_VERSES')
          .doc(book)
          .collection('chapters')
          .doc(chapter)
          .collection('verses')
          .doc(verse)
          .get();
      setState(() {
        verseText = doc.data()?['sentence'] ?? "Text not found";
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching verse text: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SELECT PROMISE',
                style: GoogleFonts.ibmPlexMono(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30),
                ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Book Dropdown
          _buildDropdown<String>(
            label: "BOOK",
            value: selectedBook,
            items: books,
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedBook = val);
                _fetchChapters(val);
              }
            },
          ),
          const SizedBox(height: 16),

          // Chapter Dropdown
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  label: "CHAPTER",
                  value: selectedChapter,
                  items: chapters,
                  onChanged: selectedBook == null ? null : (val) {
                    if (val != null) {
                      setState(() => selectedChapter = val);
                      _fetchVerses(selectedBook!, val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Verse Dropdown
              Expanded(
                child: _buildDropdown<String>(
                  label: "VERSE #",
                  value: selectedVerse,
                  items: verses,
                  onChanged: selectedChapter == null ? null : (val) {
                    if (val != null) {
                      setState(() => selectedVerse = val);
                      _fetchVerseText(selectedBook!, selectedChapter!, val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Fetched Text Display
          if (verseText != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Text(
                verseText!,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ),

          const SizedBox(height: 32),

          GestureDetector(
            onTap: () {
              if (selectedBook != null && selectedChapter != null && selectedVerse != null && verseText != null) {
                final customVerse = BibleVerse(
                  book: selectedBook!,
                  chapter: selectedChapter!,
                  verse: selectedVerse!,
                  sentence: verseText!,
                );
                
                context.read<PromiseGroupBloc>().add(SendSharedVerseEvent(customVerse));
                Navigator.pop(context);
                HapticFeedback.heavyImpact();
              }
            },
            child: Opacity(
              opacity: (selectedVerse != null && verseText != null) ? 1.0 : 0.3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    'SHARE TO GROUP',
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((i) => DropdownMenuItem<T>(
        value: i,
        child: Text(i.toString(), style: const TextStyle(fontSize: 14)),
      )).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.ibmPlexMono(color: Colors.white24, fontSize: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
      ),
    );
  }
}
