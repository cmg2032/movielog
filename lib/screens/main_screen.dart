import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

/// 홈·영화·마이 탭을 모두 감싸는 화면
/// 탭을 바꿔도 유지되므로 initState는 로그인 세션마다 한 번만 실행됩니다.
/// (로그아웃 → /login으로 나가면 사라지고, 다시 로그인하면 새로 만들어짐)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // 첫 build 도중 notifyListeners()가 실행되지 않도록 첫 프레임 뒤에 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 어느 탭으로 진입하든 내 정보를 한 번 불러와 AuthViewModel.member에 보관합니다.
      if (mounted) context.read<AuthViewModel>().loadMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // 탭 전환: 각 탭의 마지막 화면·스크롤·필터 상태가 그대로 유지됨
          navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: '영화',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
