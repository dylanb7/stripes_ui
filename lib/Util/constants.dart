// ignore_for_file: constant_identifier_names

class Routes {
  static const String LANDING = '/';
  static const String SIGN_UP = '/signup';
  static const String LOGIN = '/login';
  static const String HOME = '/record';
  static const String HISTORY = '/history';
  static const String TRENDS = '/trends';
  static const String SYMPTOMTREND = 'symptomtrend';
  static const String USERS = 'profiles';
  static const String SYMPTOMS = 'symptoms';
  static const String SYMPTOMTYPE = 'symptomtype';
  static const String BM = 'bowelmovement';
  static const String PAIN = 'pain';
  static const String REFLUX = 'reflux';
  static const String NB = 'neurobehavior';
  static const String TEST = '/tests';
  static const String ACCOUNT = '/account';
  static const String SETTINGS = '/settings';

  static const String PAGE_ID_PARAM = 'pid';

  static const List<String> noauth = [LANDING, SIGN_UP, LOGIN];
}

enum TabSelectedScreen { record, track }
