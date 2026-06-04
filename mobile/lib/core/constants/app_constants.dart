class ApiConstants {
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
}

class AppConstants {
  static const String appName = 'Karma';
  static const String appTagline = 'Grow with intention';

  // Avatar stages
  static const Map<int, String> avatarStageNames = {
    1: 'Seeker',
    2: 'Apprentice',
    3: 'Guardian',
    4: 'Sage',
    5: 'Enlightened',
  };

  static const Map<int, String> avatarStageDescriptions = {
    1: 'Beginning your journey of self-discovery',
    2: 'Developing consistent virtuous habits',
    3: 'Your character shines with inner strength',
    4: 'Wisdom guides your every action',
    5: 'A beacon of light for those around you',
  };
}
