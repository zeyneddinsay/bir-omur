import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/families.dart';
import '../helpers/people.dart';
import '../helpers/test_character.dart';

void main() {
  final content = loadRealContent();
  final book = content.careers;
  final factory = PersonFactory(SeededRandom(9), realFamilies());

  Character graduate(String department, {int age = 23}) =>
      testCharacter(age: age).copyWith(
        education: Education(
          highSchool: HighSchool.duz,
          department: department,
          uniStartAge: age - 4,
          uniYears: 4,
          graduatedAt: age,
        ),
      );

  JobListing listing(String careerId, {int tier = 1, String? company}) =>
      JobListing(
        careerId: careerId,
        tier: tier,
        company: company ?? book.require(careerId).listing!.companies.first,
        ad: 'ilan',
        interview: 0,
      );

  ListingBlocked? blocked(Character c, JobListing l) =>
      JobMarket.blocked(c, l, book, timeLeft: 3, applied: const {});

  group('meslekler', () {
    test('ilk sürümün yedi ilanlı mesleği ve aile fabrikası var; esnaf yok', () {
      expect(book.all.map((c) => c.id).toSet(), {
        'aile_fabrikasi',
        'memur',
        'hemsire',
        'yazilimci',
        'plaza',
        'oto_tamircisi',
        'garson',
        'emlakci',
      });
      for (final career in book.all) {
        // Aile fabrikasına ilanla değil, babanın teklifiyle girilir.
        if (career.id == 'aile_fabrikasi') {
          expect(career.listing, isNull);
          continue;
        }
        expect(career.listing, isNotNull, reason: career.id);
        expect(career.interviews, isNotEmpty, reason: career.id);
        for (final occupation in career.occupations) {
          expect(
            content.families.occupations,
            contains(occupation),
            reason: '${career.id} $occupation',
          );
        }
      }
    });
  });

  group('giriş şartları', () {
    test('hemşire diplomasıyla; yazılımcı diploma ya da kursla', () {
      expect(blocked(graduate('hemsirelik'), listing('hemsire')), isNull);
      expect(
        blocked(graduate('isletme'), listing('hemsire')),
        ListingBlocked.sart,
      );
      expect(
        blocked(graduate('isletme'), listing('yazilimci')),
        ListingBlocked.sart,
      );
      expect(
        blocked(
          graduate('isletme').copyWith(flags: {JobMarket.codingFlag}),
          listing('yazilimci'),
        ),
        isNull,
      );
    });

    test('memur KPSS ister; garson ve emlakçı şartsız', () {
      expect(blocked(graduate('tarih'), listing('memur')), ListingBlocked.sart);
      expect(
        blocked(
          graduate('tarih').copyWith(flags: {JobMarket.kpssFlag}),
          listing('memur'),
        ),
        isNull,
      );
      expect(blocked(testCharacter(age: 19), listing('garson')), isNull);
      expect(
        blocked(testCharacter(age: 19), listing('emlakci')),
        ListingBlocked.yas,
      );
      expect(blocked(testCharacter(age: 22), listing('emlakci')), isNull);
    });

    test('oto tamircisi meslek lisesi ya da çıraklıkla', () {
      final vocational = testCharacter(age: 19)
          .copyWith(education: const Education(highSchool: HighSchool.meslek));
      expect(blocked(vocational, listing('oto_tamircisi')), isNull);
      expect(
        blocked(testCharacter(age: 19), listing('oto_tamircisi')),
        ListingBlocked.sart,
      );
    });

    test('öğrenci tam zamanlı giremez; üst pozisyon deneyim ister', () {
      final student = testCharacter(age: 20, flags: {ActionCatalog.studentFlag})
          .copyWith(
            education: const Education(department: 'isletme', uniStartAge: 18),
          );
      expect(blocked(student, listing('garson')), ListingBlocked.ogrenci);
      expect(
        blocked(testCharacter(age: 25), listing('garson', tier: 2)),
        ListingBlocked.deneyim,
      );
      final waiter = testCharacter(
        age: 25,
        job: const Job(careerId: 'garson', tier: 1, yearsInTier: 3),
      );
      expect(blocked(waiter, listing('garson', tier: 2)), isNull);
    });
  });

  group('ilanlar', () {
    test('şehir türüne göre sayı; yazılımcı küçük şehirde yok', () {
      for (var s = 0; s < 50; s++) {
        final small = JobMarket.listingsFor(
          testCharacter(age: 25).copyWith(city: 'Rize'),
          book,
          SeededRandom(s),
        );
        expect(small.length, lessThanOrEqualTo(3));
        expect(small.any((l) => l.careerId == 'yazilimci'), isFalse);
        expect(small.any((l) => l.careerId == 'plaza'), isFalse);
      }
      final big = JobMarket.listingsFor(
        testCharacter(age: 25).copyWith(city: 'İstanbul'),
        book,
        SeededRandom(1),
      );
      expect(big.length, inInclusiveRange(4, 6));
      expect(
        JobMarket.listingsFor(testCharacter(age: 16), book, SeededRandom(1)),
        isEmpty,
      );
    });
  });

  group('işe giriş', () {
    test('patron ve üç iş arkadaşı gelir; eski işin rolleri biter', () {
      final first = JobMarket.hire(
        testCharacter(age: 25),
        listing('garson'),
        book,
        factory,
      );
      expect(first.job!.company, listing('garson').company);
      final work = first.people.all.where((p) => p.origin == Origin.isYeri);
      expect(work.where((p) => p.hasRole(RoleKind.patron)), hasLength(1));
      expect(work.where((p) => p.hasRole(RoleKind.isArkadasi)), hasLength(3));

      final second = JobMarket.hire(
        first,
        listing('garson', company: 'Taşfırın Pide Salonu'),
        book,
        factory,
      );
      final active = second.people.all.where(
        (p) => p.hasRole(RoleKind.isArkadasi) || p.hasRole(RoleKind.patron),
      );
      expect(active, hasLength(4), reason: 'yalnızca yeni iş yeri');
    });

    test('yakın tanıdık aracı olursa doğrudan alınır, itibar düşer', () {
      final friend = testPerson('x', base: 70).copyWith(occupation: 'garson');
      final c = withPeople(testCharacter(age: 25), [friend]);
      final ref = c.people.all.single;
      expect(JobMarket.references(c, listing('garson'), book), [ref]);
      final result = JobMarket.interview(
        c,
        listing('garson'),
        book,
        const InterviewAnswer(label: '', stat: RollStat.luck),
        SeededRandom(1),
        reference: ref,
      );
      expect(result, InterviewResult.torpilleAlindi);
      final hired = JobMarket.hire(
        c,
        listing('garson'),
        book,
        factory,
        reference: ref,
      );
      expect(hired.stats.reputation, c.stats.reputation - 3);
      expect(hired.people[ref.id]!.memories.single.kind, 'ise_aracilik');
    });

    test('mülakat: değer yüksekse çoğunlukla alınır', () {
      int hires(int knowledge) {
        var n = 0;
        for (var s = 0; s < 400; s++) {
          final r = JobMarket.interview(
            testCharacter(age: 25, knowledge: knowledge),
            listing('hemsire'),
            book,
            const InterviewAnswer(label: '', stat: RollStat.knowledge),
            SeededRandom(s),
          );
          if (r == InterviewResult.alindi) n++;
        }
        return n;
      }

      expect(hires(80), greaterThan(hires(20)));
      expect(hires(80), greaterThan(300));
    });
  });

  group('işteyken', () {
    Character worker({int performance = 70, int years = 5, int tier = 1}) =>
        testCharacter(
          age: 30,
          knowledge: 70,
          reputation: 60,
          job: Job(
            careerId: 'memur',
            tier: tier,
            yearsInTier: years,
            performance: performance,
            company: 'Vergi Dairesi',
          ),
        );

    test(
      'terfi: süre ve performans yoksa zamanı değil; olursa kademe atlar',
      () {
        final (_, early) = JobMarket.requestPromotion(
          worker(years: 1),
          book,
          SeededRandom(1),
        );
        expect(early, RequestResult.zamaniDegil);
        final (_, low) = JobMarket.requestPromotion(
          worker(performance: 30),
          book,
          SeededRandom(1),
        );
        expect(low, RequestResult.zamaniDegil);
        var promoted = 0;
        for (var s = 0; s < 200; s++) {
          final (c, r) = JobMarket.requestPromotion(
            worker(),
            book,
            SeededRandom(s),
          );
          expect(c.job!.promotionAskedAt, 30);
          if (r == RequestResult.evet) {
            promoted++;
            expect(c.job!.tier, 2);
            expect(c.job!.yearsInTier, 0);
            expect(c.counters.promotions, 1);
          }
        }
        expect(promoted, inInclusiveRange(60, 180));
      },
    );

    test('zam: performans 60+ ve en fazla %30', () {
      final (_, low) = JobMarket.requestRaise(
        worker(performance: 50),
        SeededRandom(1),
      );
      expect(low, RequestResult.zamaniDegil);
      var c = worker(performance: 100);
      for (var i = 0; i < 10; i++) {
        (c, _) = JobMarket.requestRaise(c, SeededRandom(i));
      }
      expect(c.job!.raise, lessThanOrEqualTo(JobMarket.maxRaise + 1e-9));
    });

    test('performans dibe vurursa kovulur; roller biter', () {
      var c = JobMarket.hire(
        testCharacter(age: 30),
        listing('garson'),
        book,
        factory,
      );
      c = c.copyWith(
        job: c.job!.copyWith(
          performance: 5,
          yearsInTier: 2,
          tempo: Tempo.rahat,
        ),
      );
      final (fired, report) = CareerTick(SeededRandom(1), book).apply(c);
      expect(report.fired, isTrue);
      expect(fired.job, isNull);
      expect(
        fired.people.all.where(
          (p) => p.hasRole(RoleKind.patron) || p.hasRole(RoleKind.isArkadasi),
        ),
        isEmpty,
      );
    });

    test('yüklenmek vakti 1 azaltır, performansı artırır', () {
      final busy = worker().copyWith(
        job: worker().job!.copyWith(tempo: Tempo.yukle),
      );
      expect(ActionCatalog.timeFor(worker()), 3);
      expect(ActionCatalog.timeFor(busy), 2);
      final (after, _) = CareerTick(SeededRandom(1), book).apply(busy);
      expect(after.job!.performance, greaterThan(70));
      expect(after.stats.health, busy.stats.health - 2);
    });

    test('maaş kademe, zam ve şehirle', () {
      final career = book.require('memur');
      final job = worker().job!.copyWith(raise: 0.1);
      final konya = Careers.salaryFor(worker(), job, career);
      final istanbul = Careers.salaryFor(
        worker().copyWith(city: 'İstanbul'),
        job,
        career,
      );
      expect(konya, (600000 * 1.1).round());
      expect(istanbul, konya, reason: 'memur maaşı her şehirde aynı');
      final plaza = book.require('plaza');
      final plazaJob = Job(careerId: 'plaza', tier: 1, raise: 0.1);
      expect(
        Careers.salaryFor(worker().copyWith(city: 'İstanbul'), plazaJob, plaza),
        (plaza.tier(1).salary * 1.1 * 1.15).round(),
      );
    });
  });

  group('motor', () {
    test('ilanlar her yıl yenilenir ve kayda girer; başvuru vakit harcar', () {
      LifeEngine? engine;
      for (var seed = 0; engine == null && seed < 100; seed++) {
        final e = LifeEngine(
          deck: EventDeck(const []),
          seed: seed,
          careers: book,
          families: realFamilies(),
        )..startLife();
        while (e.state.character.age < 19) {
          e.advanceYear();
        }
        if (e.listingOptions().any((o) => o.$2 == null)) engine = e;
      }
      expect(engine, isNotNull);
      final e = engine!;
      final open = e.listingOptions().firstWhere((o) => o.$2 == null).$1;
      final before = e.state.timeLeft;
      final restored = LifeEngine.restore(
        deck: EventDeck(const []),
        careers: book,
        families: realFamilies(),
        snapshot: e.toSnapshot(),
      );
      expect(restored.state.listings, e.state.listings);
      final state = e.applyFor(open, ChoiceSide.left);
      // İşe girerse vakit hakkı 3'e iner; harcanan 1 düşülür.
      expect(state.timeSpent, 1);
      expect(
        state.timeLeft,
        state.character.job == null
            ? before - 1
            : ActionCatalog.timeFor(state.character) - 1,
      );
      expect(state.applied, contains(JobMarket.key(open)));
      expect(
        state.notes.last.kind,
        anyOf(NoteKind.isBuldun, NoteKind.mulakatOlmadi),
      );
      expect(
        () => e.applyFor(open, ChoiceSide.left),
        throwsStateError,
        reason: 'aynı ilana bir yılda bir kez',
      );
    });
  });
}
