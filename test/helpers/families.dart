import 'dart:io';

import 'package:bir_omur/models/models.dart';

/// Oyunun gerçek aile ve ad dosyaları (assets/families.json, names.json).
FamilyBook realFamilies() => FamilyBook.parse(
  familiesSource: File('assets/families.json').readAsStringSync(),
  namesSource: File('assets/names.json').readAsStringSync(),
);
