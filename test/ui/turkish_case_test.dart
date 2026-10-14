import 'package:bir_omur/ui/l10n_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Türkçe büyük harf', () {
    expect('Bir Ömür'.toUpperTr(), 'BİR ÖMÜR');
    expect('Hayatın sayıları'.toUpperTr(), 'HAYATIN SAYILARI');
    expect('En büyük an'.toUpperTr(), 'EN BÜYÜK AN');
    expect('çiğdem şükrü'.toUpperTr(), 'ÇİĞDEM ŞÜKRÜ');
  });
}
