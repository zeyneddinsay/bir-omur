import 'package:bir_omur/services/feedback_service.dart';
import 'package:bir_omur/services/save_store.dart';

/// Kullanım verisi onayı zaten cevaplanmış bellek kaydı; onay kartı
/// çıkmaz. Onay akışını sınayan testler düz `MemorySaveStore` kullanır.
MemorySaveStore answeredStore() =>
    MemorySaveStore()
      ..saveSettings(const GameSettings(analyticsConsent: false));
