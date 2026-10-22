/// Oyuncunun kendi hayatından yıl günlüğüne düşen bir not ("YKS puanın
/// 312", "Mezun oldun"). Çevreden haberler [PersonNews]'tadır.
enum NoteKind {
  /// Liseye başladı; detay lise türü.
  lise,

  /// YKS sonucu; detay puan.
  yksPuani,

  /// Bir bölüme yerleşti; detay `bölüm:şehir`.
  yerlesti,

  /// Mezuna kaldı.
  mezunaKaldi,

  /// Bir ustanın yanına çırak girdi.
  cirakOldu,

  /// Okumadan çalışmayı seçti.
  calismayiSecti,

  /// Bir ders alttan kaldı; okul bir yıl uzadı.
  dersKaldi,

  /// Üniversiteden mezun oldu; detay bölüm.
  mezunOldu,

  /// Okul bitince ailesinin yanına döndü; detay şehir.
  eveDondu,

  /// Askere gitti ya da askerden döndü.
  askerlik,

  /// İşe girdi; detay `şirket|meslek|kademe`.
  isBuldun,

  /// Mülakattan olumsuz döndü; detay şirket.
  mulakatOlmadi,

  /// Terfi aldı; detay `meslek|kademe`.
  terfi,
  terfiReddi,
  terfiZamaniDegil,
  zam,
  zamReddi,
  zamZamaniDegil,
  kovuldun,
  istifa,
  emekliOldun,
  kpssGecti,
  kpssKaldi,
  yazilimKursu,

  /// İşletme açıldı; detay tür.
  isletmeAcildi,

  /// İşletmenin yılı; detay `tür|kâr`.
  isletmeYili,

  /// Nakit eksiye düştü, işletme battı; detay tür.
  isletmeBatti,
  isletmeSatildi,
  isletmeKapandi,
  subeAcildi,
  isletmeBuyudu,

  /// Ortak alındı; detay `tür|kişi adı`.
  ortakAlindi,

  /// Tanıdığını işe aldı: `tür|ad`.
  iseAldin,

  /// İpliğin kişisi gitti: `kart|yuva=kişi|…`; arayüz kartın kapanış
  /// cümlesini kurar.
  iplikKapandi,

  /// Dünya küçük: bir tanıdık yeni bir rol aldı: `kişi|rol`.
  dunyaKucuk,

  /// Zor gün yılı başladı: `sebep` ya da `vefat|kişi`.
  zorGun,

  /// Evlendi: eşin kimliği.
  evlendin,

  /// Çocuğu oldu: çocuğun kimliği.
  bebek,
}

class LifeNote {
  const LifeNote(this.kind, [this.detail]);

  final NoteKind kind;
  final String? detail;

  Map<String, Object> toJson() => {'kind': kind.name, 'detail': ?detail};

  factory LifeNote.fromJson(Map<String, dynamic> json) => LifeNote(
    NoteKind.values.byName(json['kind'] as String),
    json['detail'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is LifeNote && other.kind == kind && other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, detail);

  @override
  String toString() => 'LifeNote(${kind.name}, $detail)';
}
