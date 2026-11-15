import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:tripytravy_core/tripytravy_core.dart';

const tripId = 'tt_00000000000000000000000000000001';
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

Future<List<Map<String, int>>> measureBundles(
  MobileTripManagerService manager,
  String passphrase,
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
        userPin: passphrase,
      );
      final decoded = await manager.importTripUseCase.execute(
        containerBytes: bundle,
        userPin: passphrase,
      );
      requireThat(
        decoded.authenticatedTransfer,
        'Expected authenticated import',
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

Future<void> main() async {
  final dir = await Directory.systemTemp.createTemp('tripytravy_paper_');
  try {
    final manager = MobileTripManagerService.fromDirectory(dir);
    final random = Random.secure();
    final passphrase = base64Url.encode(
      List.generate(24, (_) => random.nextInt(256)),
    );
    final bundles = await measureBundles(manager, passphrase);
    print(
      const JsonEncoder.withIndent('  ').convert({'deduplication': bundles}),
    );
  } finally {
    await dir.delete(recursive: true);
  }
}
