// ignore_for_file: constant_identifier_names

const String PASSWORD = 'pass';

const double SMALL_LAYOUT = 600 * 1.5;

class Routes {
  static const String LANDING = '/';
  static const String SIGN_UP = '/signup';
  static const String LOGIN = '/login';
  static const String HOME = '/record';
  static const String HISTORY = '/history';
  static const String USERS = '/patients';
  static const String BM = 'bowelmovement';
  static const String PAIN = 'pain';
  static const String REFLUX = 'reflux';
  static const String NB = 'neurobehavior';
  static const String TEST = 'test';

  static const String PAGE_ID_PARAM = 'pid';

  static const List<String> noauth = [LANDING, SIGN_UP, LOGIN];
}

enum TabSelectedScreen { record, track }
