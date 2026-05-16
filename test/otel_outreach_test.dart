// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_outreach/otel_outreach.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_outreach-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('sequence_states.create records prospect + sequence state', () async {
    await tracedOutreach<String>(
      operation: 'sequence_states.create',
      invoke: () async => const OutreachCallResult(
        value: 'ok',
        result: OutreachResult(
          orgId: 'org_1',
          entityKind: 'sequence_state',
          prospectId: 'p_1',
          sequenceId: 'seq_1',
          sequenceState: 'ss_1',
          sequenceStateState: 'active',
          mailboxId: 'mb_1',
          optedOut: false,
          rateLimitRemaining: 9750,
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('outreach sequence_states.create')!);
    expect(a['outreach.sequence.id'], 'seq_1');
    expect(a['outreach.sequence_state.state'], 'active');
    expect(a['outreach.prospect.opted_out'], false);
    expect(a['outreach.rate_limit.remaining'], 9750);
  });

  test('bounced mailing sets span error', () async {
    await tracedOutreach<String>(
      operation: 'mailings.create',
      invoke: () async => const OutreachCallResult(
        value: 'ok',
        result: OutreachResult(
          mailingId: 'm_1',
          mailingState: 'bounced',
          bouncedAt: 1731600000,
        ),
      ),
    );
    final s = spans.findSpanByName('outreach mailings.create')!;
    expect(s.status, SpanStatusCode.Error);
    expect(attrsOf(s)['outreach.mailing.bounced_at'], 1731600000);
  });

  test('replied sequence_state does NOT set span error', () async {
    await tracedOutreach<String>(
      operation: 'sequence_states.create',
      invoke: () async => const OutreachCallResult(
        value: 'ok',
        result: OutreachResult(
          sequenceStateState: 'replied',
        ),
      ),
    );
    expect(
      spans.findSpanByName('outreach sequence_states.create')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutOutreachInstrumentationAsync(() async {
      await tracedOutreach<String>(
        operation: 'prospects.list',
        invoke: () async => const OutreachCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('outreach '), isEmpty);
  });
}
