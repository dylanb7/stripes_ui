import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Services/shared_service.dart';

final sharedSeviceProvider = Provider<SharedService>((ref) => SharedService());
