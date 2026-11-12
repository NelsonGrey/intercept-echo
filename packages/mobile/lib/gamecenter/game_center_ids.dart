/// Achievement/leaderboard/cloud-save IDs. These have to match records
/// created in App Store Connect's Game Center configuration exactly — see
/// docs/GAME_CENTER_SETUP.md for the manual setup (names, descriptions and
/// point values) this list drives.
class GameCenterIds {
  const GameCenterIds._();

  static const leaderboardTotalScore = 'intercept_echo_total_score';

  static const achievementFirstTransmission =
      'intercept_echo_first_transmission';
  static const achievementCampaignComplete = 'intercept_echo_campaign_complete';
  static const achievementUsedRotate = 'intercept_echo_used_rotate';
  static const achievementHardDifficulty = 'intercept_echo_hard_difficulty';
  static const achievementPerfectShift = 'intercept_echo_perfect_shift';

  /// The saved-game slot name for cloud-synced campaign progress (Game
  /// Center's iCloud-backed saved games, via SaveGame.saveGame/loadGame).
  static const cloudSaveName = 'intercept_echo_progress';
}
