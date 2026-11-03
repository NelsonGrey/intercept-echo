/// Game Center integration beyond sign-in: achievements, the leaderboard,
/// and cloud-saved campaign progress.
///
/// Every method is best-effort: a failure (not signed in, offline,
/// simulator without a Game Center account, Android with no Play Games
/// project yet) is swallowed inside the implementation, never thrown — so
/// callers never need to guard these calls, the same contract
/// [PlatformGameAuthService.signIn] already has in `AppServices.initialize`.
abstract class GameCenterProgressService {
  Future<void> unlockAchievement(String id);
  Future<void> submitScore(int score);
  Future<void> showLeaderboard();
  Future<void> showAchievements();

  /// Pushes [data] (a small, opaque JSON string) to the platform's cloud
  /// save slot ([GameCenterIds.cloudSaveName]).
  Future<void> saveCloudProgress(String data);

  /// The last cloud-saved data, or null if there is none yet or the load
  /// failed.
  Future<String?> loadCloudProgress();
}
