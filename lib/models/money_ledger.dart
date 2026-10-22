/// Paranın nereden gelip nereye gittiği. Varlıklar sekmesi bu kaynaklarla
/// "bu yıl ve geçen yıl" dökümünü gösterir.
enum MoneySource {
  /// Maaş.
  maas,

  /// Kovulunca kıdem tazminatı.
  tazminat,
  emekliAyligi,

  /// Çalışmamış ya da yeterince çalışmamış yaşlıya devletin 65 yaş aylığı.
  yasliAyligi,

  /// Ailenin verdiği harçlık (lise ve üniversite).
  harclik,

  /// İşsizken ara işler, yevmiyeler.
  araIs,
  burs,

  /// Yarı zamanlı iş (öğrenciyken).
  yarimZamanli,

  /// 18 yaşında ailenin başlangıç desteği.
  aileDestegi,
  kira,

  /// Ev dışında yaşamanın yıllık gideri (yurt, kira evi, kendi evin).
  yasamGideri,
  kredi,

  /// Arabanın yıllık masrafı.
  araba,

  /// Enflasyonun nakitten erittiği.
  enflasyon,

  /// Terfi için yapılan yatırım (dükkân, ortaklık payı).
  terfi,

  /// Bir olay kartındaki seçim; [MoneyEntry.ref] `kart:taraf`.
  olay,

  /// Bir aksiyon; [MoneyEntry.ref] aksiyon kimliği.
  aksiyon,

  /// Bir kişiyle etkileşim; [MoneyEntry.ref] etkileşim adı.
  etkilesim,

  /// İş ilanı, mülakat, istifa gibi iş hareketleri; [MoneyEntry.ref] açıklama.
  is_,

  /// Başka şehre taşınma; [MoneyEntry.ref] yeni şehir.
  tasinma,

  /// İşletme: kâr, zarar, kuruluş, reklam, şube, satış; [MoneyEntry.ref]
  /// `tür:ne`.
  isletme,

  /// Ev, araba, taşınma gibi varlık hareketleri.
  varlik,
}

/// Bir para hareketi: hangi yaşta, nereden, ne kadar.
class MoneyEntry {
  const MoneyEntry({
    required this.age,
    required this.source,
    required this.amount,
    this.ref,
  });

  final int age;
  final MoneySource source;

  /// Artı gelir, eksi gider.
  final int amount;

  /// Kaynağa göre ek bilgi (kart, aksiyon ya da etkileşim kimliği).
  final String? ref;

  Map<String, Object> toJson() => {
    'age': age,
    'source': source.name,
    'amount': amount,
    'ref': ?ref,
  };

  factory MoneyEntry.fromJson(Map<String, dynamic> json) => MoneyEntry(
    age: json['age'] as int,
    source: MoneySource.values.byName(json['source'] as String),
    amount: json['amount'] as int,
    ref: json['ref'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is MoneyEntry &&
      other.age == age &&
      other.source == source &&
      other.amount == amount &&
      other.ref == ref;

  @override
  int get hashCode => Object.hash(age, source, amount, ref);

  @override
  String toString() => 'MoneyEntry($age, ${source.name}, $amount, $ref)';
}
