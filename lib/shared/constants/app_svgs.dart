/// Paths for icon assets stored under assets/icons/.
///
/// SVG files are referenced by these constants so that
/// [ExperienceMapper] and the rest of the app can be updated
/// to use [SvgPicture.asset] once the files are dropped in place.
abstract final class AppSvgs {
  static const String _base = 'assets/icons';

  // ── Experience company icons ─────────────────────────────────────
  static const String zallpy = '$_base/zallpy.svg';
  static const String bancoPan = '$_base/pan.svg';
  static const String conecthus = '$_base/conecthus.svg';
  static const String oi = '$_base/oi.svg';

  // ── General UI icons ─────────────────────────────────────────────
  static const String about = '$_base/person.svg';
  static const String finder = '$_base/finder.svg'; 
  static const String skills = '$_base/skills.svg';   
  static const String android = '$_base/android.svg';
  static const String terminal = '$_base/terminal.svg'; 
  static const String calculator = '$_base/calculator.svg'; 
  static const String snake = '$_base/game.svg'; 
  static const String contact = '$_base/gmail.svg';
  static const String whitepaper = '$_base/gitbook.svg';
  static const String resume = '$_base/resume.svg'; 
  // static const String shield = '$_base/shield.svg'; // not provided
  
  // ── Newly added missing UI icons ─────────────────────────────────
  static const String flutter = '$_base/flutter.svg';
  static const String dart = '$_base/dart.svg';
  static const String kotlin = '$_base/kotlin.svg';
  static const String api = '$_base/apis.svg';
  static const String firebase = '$_base/firebase.svg';
  static const String github = '$_base/github.svg';
  static const String fastlane = '$_base/fastlane.svg';
  static const String guestbook = '$_base/guestbook.svg';
  static const String projectStats = '$_base/stats.svg';
  static const String linkedin = '$_base/linkedin.svg';
  static const String medium = '$_base/medium.svg';
  static const String at = '$_base/at.svg';
}
