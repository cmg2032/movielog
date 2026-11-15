import 'package:flutter/foundation.dart';

/// 학습용 회원 세션 (메모리에만 보관 → 앱을 끄면 사라짐)
class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
