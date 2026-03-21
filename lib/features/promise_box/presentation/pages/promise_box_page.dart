import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/nothing_verse_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../promise_box_group/presentation/bloc/promise_group_bloc.dart';
import '../../../promise_box_group/presentation/pages/promise_group_page.dart';
import '../bloc/promise_bloc.dart';

class PromiseBoxPage extends StatefulWidget {
  const PromiseBoxPage({super.key});

  @override
  State<PromiseBoxPage> createState() => _PromiseBoxPageState();
}

class _PromiseBoxPageState extends State<PromiseBoxPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedTab = 0; // 0: Offline, 1: Group

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
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOutBack),
    ));
    
    context.read<PromiseBloc>().add(LoadVersesEvent());
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return _buildMainContent();
        } else if (authState is AuthLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        } else {
          return _buildSignInUI();
        }
      },
    );
  }

  Widget _buildSignInUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PROMISE BOX',
              style: GoogleFonts.ibmPlexMono(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () => context.read<AuthBloc>().add(SignInRequested()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.login, color: Colors.black),
                    const SizedBox(width: 12),
                    Text(
                      'SIGN IN WITH GOOGLE',
                      style: GoogleFonts.ibmPlexMono(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildTabBarRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildOfflineContent(),
                      ),
                      const PromiseGroupPage(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedTab == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildFooterButton(),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineContent() {
    return BlocBuilder<PromiseBloc, PromiseState>(
      builder: (context, state) {
        if (state is PromiseLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        } else if (state is PromiseError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.white)));
        } else if (state is PromiseLoaded) {
          if (state.currentVerse != null) {
            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: NothingVerseCard(
                    verse: state.currentVerse!,
                    onRefresh: _generateNewVerse,
                  ),
                ),
              ),
            );
          }
          return _buildInitialState();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTabBarRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabItem(0, 'OFFLINE'),
              _buildTabItem(1, 'GROUP'),
            ],
          ),
        ),
        if (_selectedTab == 1) ...[
          const SizedBox(width: 12),
          _buildGroupTriggerButton(),
        ],
      ],
    );
  }

  Widget _buildGroupTriggerButton() {
    return BlocBuilder<PromiseGroupBloc, PromiseGroupState>(
      builder: (context, state) {
        if (state is PromiseGroupOverview) {
          Widget iconContent;
          if (state.activeGroupId != null) {
            final group = state.groups.firstWhere((g) => g.id == state.activeGroupId);
            final members = group['members'] as List? ?? [];
            String groupInitials = "";
            if (members.length >= 2) {
              final name1 = members[0].toString().split('@')[0];
              final name2 = members[1].toString().split('@')[0];
              groupInitials = "${name1[0]}${name2[0]}".toUpperCase();
            } else if (members.isNotEmpty) {
              groupInitials = members[0].toString()[0].toUpperCase();
            }
            iconContent = Text(
              groupInitials,
              style: GoogleFonts.ibmPlexMono(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            );
          } else {
            iconContent = const Icon(Icons.person_add_alt_1_outlined, color: Colors.black, size: 20);
          }

          return GestureDetector(
            onTap: () => PromiseGroupPage.showSidebarOverlay(context, state),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(child: iconContent),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTab == index) return;
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROMISE',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 4,
              ),
            ),
            GestureDetector(
              onTap: () => context.read<AuthBloc>().add(SignOutRequested()),
              child: const Icon(Icons.logout, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Daily Manna',
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
        mainAxisAlignment: MainAxisAlignment.center,
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
