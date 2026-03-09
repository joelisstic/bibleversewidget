import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/promise_bloc.dart';
import '../widgets/nothing_verse_card.dart';

class PromiseBoxPage extends StatefulWidget {
  const PromiseBoxPage({super.key});

  @override
  State<PromiseBoxPage> createState() => _PromiseBoxPageState();
}

class _PromiseBoxPageState extends State<PromiseBoxPage> with SingleTickerProviderStateMixin {
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
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateNewVerse() {
    context.read<PromiseBloc>().add(GetRandomVerseEvent());
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background noise/texture simulation
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/stardust.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocBuilder<PromiseBloc, PromiseState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const Spacer(),
                      if (state is PromiseLoaded && state.currentVerse != null)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: NothingVerseCard(
                              verse: state.currentVerse!,
                              onRefresh: _generateNewVerse,
                            ),
                          ),
                        )
                      else if (state is PromiseLoaded && state.currentVerse == null)
                        _buildInitialState()
                      else if (state is PromiseLoading)
                        const Center(child: CircularProgressIndicator(color: Colors.white)),
                      const Spacer(flex: 2),
                      _buildFooterButton(),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROMISE',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'God Bless You',
          style: GoogleFonts.inter(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
      ],
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
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Your daily promise is ready.',
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
            'REVEAL PROMISE',
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
