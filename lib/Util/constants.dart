// ignore_for_file: constant_identifier_names

class Routes {
  static const String SIGN_UP = '/signup';
  static const String LOGIN = '/login';
  static const String HOME = '/record';
  static const String MULTI_RECORD = '/record/new';
  static const String HISTORY = '/history';
  static const String SYMPTOMTREND = 'symptomtrend';
  static const String USERS = 'profiles';
  static const String SYMPTOMS = 'symptoms';
  static const String SYMPTOMTYPE = 'symptomtype';
  static const String BASELINES = 'baselines';
  static const String BASELINE_ENTRY = 'baseline/:recordPath';
  static const String ADD_PROFILE = 'add-profile';
  static const String RESOURCES = 'resources';
  static const String RESOURCE = ':topic';

  static const String TEST = '/tests';
  static const String ACCOUNT = '/account';
  static const String SETTINGS = '/settings';
}

class RouteName {
  static const String SIGN_UP = 'signup';
  static const String LOGIN = 'login';
  static const String HOME = 'record';
  static const String MULTI_RECORD = 'recordSession';
  static const String HISTORY = 'history';
  static const String SYMPTOMTREND = 'symptomtrend';
  static const String USERS = 'profiles';
  static const String SYMPTOMS = 'symptoms';
  static const String SYMPTOMTYPE = 'symptomtype';
  static const String BASELINES = 'baselines';
  static const String BASELINE_ENTRY = 'baseline_entry';
  static const String ADD_PROFILE = 'add_profile';
  static const String RESOURCES = 'resources';
  static const String RESOURCE = 'resource';

  static const String TEST = 'tests';
  static const String ACCOUNT = 'account';
  static const String SETTINGS = 'settings';
}

enum TabSelectedScreen { record, track }
