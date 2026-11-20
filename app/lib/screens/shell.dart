import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'album.dart';
import 'benefits.dart';
import 'home.dart';
import 'map.dart';
import 'profile.dart';
import 'scan.dart';

enum Section { home, profile, badges, items, benefits }

/// ヘッダーとタブバーのある、いつもの画面
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Section _section = Section.home;

  void _go(Section section) => setState(() => _section = section);

  void _openScan() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ScanScreen()));
  }

  void _openMap() {
    Navigator.of(context).push(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const MapScreen(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final Widget body = switch (_section) {
      Section.home => HomePage(onGo: _go, onScan: _openScan),
      Section.profile => ProfilePage(onGo: _go),
      Section.badges => const AlbumPage(badges: true),
      Section.items => const AlbumPage(badges: false),
      Section.benefits => const BenefitsPage(),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: PopScope(
        // Android の戻る操作：ホーム以外ならホームへ戻す
        canPop: _section == Section.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _go(Section.home);
        },
        child: Scaffold(
          backgroundColor: C.bg,
          body: Stack(
            children: [
              Column(
                children: [
                  _Header(
                    profileActive: _section == Section.profile,
                    onHome: () => _go(Section.home),
                    onProfile: () => _go(Section.profile),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(_section),
                      padding: _section == Section.home
                          ? EdgeInsets.only(bottom: 100 + bottom)
                          : EdgeInsets.fromLTRB(16, 20, 16, 100 + bottom),
                      child: body,
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TabBar(current: _section, onGo: _go, onMap: _openMap, onScan: _openScan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profileActive, required this.onHome, required this.onProfile});
  final bool profileActive;
  final VoidCallback onHome;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      constraints: BoxConstraints(minHeight: 60 + top),
      padding: EdgeInsets.fromLTRB(12, top + 6, 10, 6),
      decoration: const BoxDecoration(
        color: Color(0xF0FBF6EC),
        border: Border(bottom: BorderSide(color: C.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                onTap: onHome,
                semanticLabel: 'ホーム',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: C.sky, borderRadius: BorderRadius.circular(12)),
                      child: SvgPicture.string(kBrandMarkSvg, width: 34, height: 34),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('青森県 新郷村',
                            style: ts(10, weight: FontWeight.w700, color: C.leafDark, ls: 0.12, height: 1.2)),
                        Text(kAppName, style: ts(16, weight: FontWeight.w900, ls: 0.04, height: 1.2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Pressable(
            onTap: onProfile,
            semanticLabel: 'マイページ',
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: profileActive ? C.leaf : C.card,
                boxShadow: const [BoxShadow(color: Color(0x1F5C4628), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: AppIcon(Ic.profile, size: 22, color: profileActive ? Colors.white : C.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onGo, required this.onMap, required this.onScan});
  final Section current;
  final ValueChanged<Section> onGo;
  final VoidCallback onMap;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    const raise = 22.0;
    return SizedBox(
      height: 66 + bottom + raise,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 66 + bottom,
            child: Container(
              padding: EdgeInsets.fromLTRB(6, 0, 6, bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x1A5C4628), blurRadius: 20, offset: Offset(0, -4))],
              ),
              child: Row(
                children: [
                  _TabItem(label: 'マップ', icon: Ic.map, active: false, onTap: onMap),
                  _TabItem(
                      label: 'バッジ',
                      icon: Ic.badge,
                      active: current == Section.badges,
                      onTap: () => onGo(Section.badges)),
                  const SizedBox(width: 84),
                  _TabItem(
                      label: 'アイテム',
                      icon: Ic.item,
                      active: current == Section.items,
                      onTap: () => onGo(Section.items)),
                  _TabItem(
                      label: '特典',
                      icon: Ic.benefit,
                      active: current == Section.benefits,
                      onTap: () => onGo(Section.benefits)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Pressable(
                onTap: onScan,
                scale: 0.95,
                semanticLabel: 'QRを読み込む',
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF06A43), C.torii],
                    ),
                    boxShadow: const [BoxShadow(color: Color(0x73E2563B), blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: const AppIcon(Ic.qr, size: 28, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.icon, required this.active, required this.onTap});
  final String label;
  final String icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? C.leafDark : const Color(0xFFA39684);
    return Expanded(
      child: Semantics(
        selected: active,
        child: Pressable(
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? C.leafSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: AppIcon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 2),
                Text(label, style: ts(10, weight: FontWeight.w700, color: color, ls: 0.04, height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
