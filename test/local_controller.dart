import 'package:daryeel/services/app_controller.dart';

/// Isolated medicine UI fixture. Production routing always requires a real session.
/// Authentication integration is tested separately with the real Supabase client.
class LocalTestController extends AppController {
  LocalTestController(super.repository, super.reminders);
  @override
  bool get canAccessApp => onboarded;
}
