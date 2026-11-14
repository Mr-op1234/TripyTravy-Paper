import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tripytravy_core/tripytravy_core.dart';

const tripId = 'tt_38324e5e32a42036166a1e86e5473bc2';
const bytesPerAttachment = 1024 * 1024;

void requireThat(bool condition, String description) {
  if (!condition) throw StateError(description);
}

TripPackage sample() {
  return const TripPackage(
    tripId: tripId,
    revision: 1,
    title: 'Fixture',
    startDateIso8601: '2026-11-20',
    endDateIso8601: '2026-11-20',
    primaryTimezoneIana: 'Asia/Kolkata',
  );
}

Future<void> checkAcceptedPayloadChange() async {
  const cipher = TtrvContainerCipherAdapter();
  final bytes = await cipher.packContainer(
    protobufBytes: utf8.encode('{"title":"Trip A"}'),
    concatenatedAssets: [],
  );
  final changed = bytes.toList();
  changed[44 + '{"title":"Trip '.length] ^=
      'A'.codeUnitAt(0) ^ 'B'.codeUnitAt(0);
  final decoded = await cipher.unpackContainer(containerBytes: changed);
  requireThat(
    utf8.decode(decoded.protobufBytes) == '{"title":"Trip B"}',
    'Expected metadata change to pass the legacy wrapper check',
  );
}

Future<List<Map<String, int>>> measureBundles(
  MobileTripManagerService manager,
) async {
  final report = <Map<String, int>>[];
  for (final count in [2, 4, 8]) {
    final measured = <String, int>{'references': count};
    for (final duplicate in [true, false]) {
      final docs = <TripDocumentRecord>[];
      for (var i = 0; i < count; i++) {
        final payload = Uint8List(bytesPerAttachment)..[0] = duplicate ? 0 : i;
        docs.add(
          TripDocumentRecord(
            id: 'doc_$i',
            title: 'Attachment $i',
            fileName: 'attachment_$i.bin',
            base64Data: base64Encode(payload),
          ),
        );
      }
      final bundle = await manager.exportTripUseCase.execute(
        trip: sample().copyWith(documents: docs),
      );
      final decoded = await manager.importTripUseCase.execute(
        containerBytes: bundle,
      );
      requireThat(
        decoded.documents.length == count,
        'Expected every document reference',
      );
      requireThat(
        decoded.allAssets.length == (duplicate ? 1 : count),
        'Unexpected number of unique assets',
      );
      requireThat(
        decoded.allAssets.every(
          (asset) => asset.byteSize == bytesPerAttachment,
        ),
        'Unexpected blob size',
      );
      measured[duplicate ? 'shared_bytes' : 'distinct_bytes'] = bundle.length;
    }
    report.add(measured);
  }
  return report;
}

Future<Map<String, Object>> checkLegacyUpgrade(
  MobileTripManagerService manager,
  File fixture,
) async {
  final legacy = await manager.importTripFromFile(fixture);
  requireThat(
    legacy.revision == 0 && legacy.days.any((day) => day.events.isNotEmpty),
    'Expected a legacy file with existing events',
  );
  await manager.toggleChecklistItem(legacy.tripId, 'chk_passport', true);
  final revision = legacy.copyWith(
    tripId: tripId,
    legacyTripId: legacy.tripId,
    revision: 1,
    title: 'Kashmir (revised)',
  );
  final bytes = await manager.exportTripUseCase.execute(trip: revision);
  final updated = await manager.importTripFromContainer(bytes);
  requireThat(
    updated.tripId == tripId && updated.title == revision.title,
    'Expected updated content and permanent ID',
  );
  requireThat(
    (await manager.listAllTrips()).single.tripId == tripId,
    'Expected exactly one trip after upgrade',
  );
  requireThat(
    (await manager.getChecklist(tripId)).completedCount == 1,
    'Expected checklist state to carry over',
  );
  await manager.importTripFromFile(fixture);
  requireThat(
    (await manager.listAllTrips()).single.revision == 1,
    'Expected older file to leave the revision unchanged',
  );
  return {
    'fixture_bytes': await fixture.length(),
    'saved_trips': 1,
    'saved_revision_after_replay': 1,
    'checklist_items_preserved': 1,
  };
}

Future<void> main(List<String> args) async {
  final dir = await Directory.systemTemp.createTemp('tripytravy_paper_');
  try {
    final manager = MobileTripManagerService.fromDirectory(dir);
    await checkAcceptedPayloadChange();
    final bundles = await measureBundles(manager);
    final report = <String, Object>{
      'legacy_wrapper_accepts_modified_metadata': true,
      'deduplication': bundles,
    };
    if (args.isNotEmpty) {
      report['kashmir'] = await checkLegacyUpgrade(manager, File(args.single));
    }
    print(const JsonEncoder.withIndent('  ').convert(report));
  } finally {
    await dir.delete(recursive: true);
  }
}
