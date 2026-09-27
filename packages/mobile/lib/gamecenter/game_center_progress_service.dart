/// Achievement/leaderboard/cloud-save IDs. These have to match records
/// created in App Store Connect's Game Center configuration exactly — see
/// docs/STORE_SETUP.md for the manual setup this list drives.
class GameCenterIds {
  const GameCenterIds._();

  static const leaderboardTotalScore = 'intercept_echo_total_score';

  static const achievementFirstTransmission =
      'intercept_echo_first_transmission';
  static const achievementCampaignComplete =
      'intercept_echo_campaign_complete';
  static const achievementUsedRotate = 'intercept_echo_used_rotate';
  static const achievementHardDifficulty = 'intercept_echo_hard_difficulty';
  static const achievementPerfectShift = 'intercept_echo_perfect_shift';

  /// The saved-game slot name for cloud-synced campaign progress (Game
  /// Center's iCloud-backed saved games, via SaveGame.saveGame/loadGame).
  static const cloudSaveName = 'intercept_echo_progress';
}

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
