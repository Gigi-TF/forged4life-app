/// Carries the signup answers from the type chooser, through the form, to the
/// code screen — where they are posted alongside the OTP in one request.
///
/// Nothing is written to the server until the code is verified, so an abandoned
/// signup leaves no half-made member behind.
class SignupDraft {
  SignupDraft({required this.memberType});

  final String memberType;   // day | member | silver | community

  String name = '';
  String email = '';
  String phone = '';
  String ageGroup = '25-39';
  String company = '';
  String transitionStage = '';
  List<String> interests = [];

  // Day pass only — these describe a visit, not a person, so the backend
  // files them against day_visits rather than the member record.
  String programme = '';
  String cohort = '';
  String trainingRoom = '';
  String vehicleReg = '';

  bool get isDay => memberType == 'day';
  bool get isSilver => memberType == 'silver';
  bool get isCommunity => memberType == 'community';

  static const labels = {
    'day': 'Day pass',
    'member': 'Full membership',
    'silver': 'FORGE Silver',
    'community': 'Community',
  };

  String get label => labels[memberType] ?? 'Membership';
}
