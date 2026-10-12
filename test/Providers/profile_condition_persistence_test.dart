import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Services/shared_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('condition survives reopening and preserves Other details', () async {
    const condition = ProfileCondition('Other', details: 'Example condition');
    await SharedService().setProfileCondition(
      accountId: 'account',
      profileId: 'profile',
      condition: condition,
    );
    expect(
      await SharedService().getProfileCondition(
        accountId: 'account',
        profileId: 'profile',
      ),
      condition,
    );
    expect(condition.label, 'Other: Example condition');
  });

  test('storage is isolated by account and profile', () async {
    final service = SharedService();
    await service.setProfileCondition(
      accountId: 'first',
      profileId: 'same',
      condition: const ProfileCondition('Not Sure'),
    );
    expect(
      await service.getProfileCondition(accountId: 'second', profileId: 'same'),
      isNull,
    );
    expect(
      await service.getProfileCondition(accountId: 'first', profileId: 'other'),
      isNull,
    );
    expect(
      await service.getProfileCondition(accountId: 'first', profileId: 'same'),
      const ProfileCondition('Not Sure'),
    );
  });

  test('removing one condition leaves other profiles intact', () async {
    final service = SharedService();
    for (final profile in ['first', 'second']) {
      await service.setProfileCondition(
        accountId: 'account',
        profileId: profile,
        condition: const ProfileCondition('GRIN2B gene disorder'),
      );
    }
    await service.setProfileCondition(
      accountId: 'account',
      profileId: 'first',
      condition: null,
    );
    expect(
      await service.getProfileCondition(
        accountId: 'account',
        profileId: 'first',
      ),
      isNull,
    );
    expect(
      await service.getProfileCondition(
        accountId: 'account',
        profileId: 'second',
      ),
      const ProfileCondition('GRIN2B gene disorder'),
    );
  });
}
