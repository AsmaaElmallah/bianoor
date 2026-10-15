import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 3D icon set (Microsoft Fluent Emoji 3D, MIT) + custom pieces in the same
/// style. Keep new art in this family so the app stays visually consistent.
class AppArt {
  AppArt._();

  static const _d = 'assets/icons3d';

  static const quran = '$_d/quran_3d.png';
  static const abacus = '$_d/abacus_3d.png';
  static const heart = '$_d/red_heart_3d.png';
  static const eye = '$_d/eye_3d.png';
  static const books = '$_d/books_3d.png';
  static const openBook = '$_d/open_book_3d.png';
  static const graduationCap = '$_d/graduation_cap_3d.png';
  static const ball = '$_d/soccer_ball_3d.png';
  static const lightBulb = '$_d/light_bulb_3d.png';
  static const stethoscope = '$_d/stethoscope_3d.png';
  static const clipboard = '$_d/clipboard_3d.png';
  static const brain = '$_d/brain_3d.png';
  static const checkMark = '$_d/check_mark_button_3d.png';
  static const palette = '$_d/artist_palette_3d.png';
  static const star = '$_d/star_3d.png';
  static const puzzle = '$_d/puzzle_piece_3d.png';
  static const tools = '$_d/hammer_and_wrench_3d.png';
  static const headphone = '$_d/headphone_3d.png';
  static const gem = '$_d/gem_stone_3d.png';
  static const thinking = '$_d/thinking_face_3d.png';
  static const teddyBear = '$_d/teddy_bear_3d.png';
  static const tree = '$_d/deciduous_tree_3d.png';
  static const musicNotes = '$_d/musical_notes_3d.png';
  static const moon = '$_d/crescent_moon_3d.png';
  static const people = '$_d/busts_in_silhouette_3d.png';
  static const question = '$_d/red_question_mark_3d.png';
  static const megaphone = '$_d/megaphone_3d.png';
  static const memo = '$_d/memo_3d.png';
  static const bell = '$_d/bell_3d.png';
  static const gear = '$_d/gear_3d.png';
  static const sparkles = '$_d/sparkles_3d.png';
  static const speech = '$_d/speech_balloon_3d.png';
  static const babyBottle = '$_d/baby_bottle_3d.png';
  static const calendar = '$_d/spiral_calendar_3d.png';
  static const house = '$_d/house_3d.png';

  static const baby = '$_d/baby_3d.png';
  static const child = '$_d/child_3d.png';
  static const running = '$_d/person_running_3d.png';
  static const walking = '$_d/person_walking_3d.png';
  static const cartwheel = '$_d/person_cartwheeling_3d.png';
  static const crayon = '$_d/crayon_3d.png';
  static const plate = '$_d/fork_and_knife_with_plate_3d.png';
  static const pensive = '$_d/pensive_face_3d.png';
  static const phone = '$_d/mobile_phone_3d.png';
  static const muted = '$_d/muted_speaker_3d.png';
  static const lockKey = '$_d/locked_with_key_3d.png';
  static const antenna = '$_d/satellite_antenna_3d.png';
  static const herb = '$_d/herb_3d.png';
  static const smiling = '$_d/smiling_face_with_smiling_eyes_3d.png';
  static const bookmark = '$_d/bookmark_3d.png';
  static const package = '$_d/package_3d.png';
  static const bellSlash = '$_d/bell_with_slash_3d.png';
  static const party = '$_d/party_popper_3d.png';
  static const trophy = '$_d/trophy_3d.png';
  static const kite = '$_d/kite_3d.png';
  static const search = '$_d/magnifying_glass_tilted_left_3d.png';
  static const cloud = '$_d/cloud_3d.png';

  /// Keys the admin picks for a club group (must match the dashboard's `groupIcons`).
  static String forKey(String key) => _byKey[key] ?? people;

  static const Map<String, String> _byKey = {
    'graduationCap': graduationCap,
    'people': people,
    'books': books,
    'calendar': calendar,
    'megaphone': megaphone,
    'heart': heart,
    'star': star,
    'lightBulb': lightBulb,
    'babyBottle': babyBottle,
    'teddyBear': teddyBear,
    'quran': quran,
    'abacus': abacus,
  };

  /// 3D stand-ins for content/category symbols (not for control buttons).
  static String? forIcon(IconData icon) => _byIcon[icon];

  static final Map<IconData, String> _byIcon = {
    Symbols.child_care: baby,
    Symbols.baby_changing_station: babyBottle,
    Symbols.toys: teddyBear,
    Symbols.palette: palette,
    Symbols.brush: crayon,
    Symbols.extension: puzzle,
    Symbols.sports_esports: kite,
    Symbols.directions_run: running,
    Symbols.directions_walk: walking,
    Symbols.sports_gymnastics: cartwheel,
    Symbols.sports_soccer: ball,
    Symbols.fitness_center: running,
    Symbols.help: question,
    Symbols.volume_off: muted,
    Symbols.wifi_off: antenna,
    Symbols.lock_reset: lockKey,
    Symbols.bedtime: moon,
    Symbols.restaurant: plate,
    Symbols.sentiment_dissatisfied: pensive,
    Symbols.sentiment_satisfied: smiling,
    Symbols.groups: people,
    Symbols.phone_android: phone,
    Symbols.spa: herb,
    Symbols.favorite: heart,
    Symbols.menu_book: books,
    Symbols.auto_stories: openBook,
    Symbols.support_agent: headphone,
    Symbols.psychology: brain,
    Symbols.lightbulb: lightBulb,
    Symbols.quiz: question,
    Symbols.notifications: bell,
    Symbols.notifications_off: bellSlash,
    Symbols.celebration: party,
    Symbols.emoji_events: trophy,
    Symbols.school: graduationCap,
    Symbols.music_note: musicNotes,
    Symbols.park: tree,
    Symbols.health_and_safety: stethoscope,
    Symbols.payments: gem,
    Symbols.workspace_premium: gem,
    Symbols.calendar_month: calendar,
    Symbols.event: calendar,
    Symbols.star: star,
    Symbols.fact_check: checkMark,
    Symbols.interests: star,
    Symbols.assignment: clipboard,
    Symbols.calculate: abacus,
    Symbols.visibility: eye,
    Symbols.gavel: memo,
    Symbols.copyright: lockKey,
    Symbols.edit: memo,
  };
}
