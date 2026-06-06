import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/nothing_verse_card.dart';
import '../../../promise_box/domain/entities/bible_verse.dart';
import '../bloc/promise_online_bloc.dart';

class PromiseOnlinePage extends StatefulWidget {
  const PromiseOnlinePage({super.key});

  @override
  State<PromiseOnlinePage> createState() => _PromiseOnlinePageState();
}

class _PromiseOnlinePageState extends State<PromiseOnlinePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
    
    context.read<PromiseOnlineBloc>().add(LoadOnlineVersesEvent());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateNewVerse() {
    context.read<PromiseOnlineBloc>().add(GetRandomOnlineVerseEvent());
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromiseOnlineBloc, PromiseOnlineState>(
      builder: (context, state) {
        if (state is PromiseOnlineLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        } else if (state is PromiseOnlineError) {
          debugPrint("firebase error: ${state.message}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Make sure you have a "verses" collection in Firestore.\n\nError: ${state.message}',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexMono(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          );
        } else if (state is PromiseOnlineLoaded) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.currentVerse != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: NothingVerseCard(
                    verse: BibleVerse(
                      book: state.currentVerse!.book,
                      chapter: state.currentVerse!.chapter,
                      verse: state.currentVerse!.verse,
                      sentence: state.currentVerse!.sentence,
                    ),
                    onRefresh: _generateNewVerse, onAddToHome: () {  },
                                        )

                  ),
                )
              else
                _buildInitialState(),

              const SizedBox(height: 40),

              _buildFooterButton(),
            ],
          );        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.cloud_download_outlined, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Online promises are synced.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton() {
    return Center(
      child: GestureDetector(
        onTap: _generateNewVerse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'REVEAL ONLINE PROMISE',
            style: GoogleFonts.ibmPlexMono(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
