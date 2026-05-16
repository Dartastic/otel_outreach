// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_outreach_suppression.dart';

const _tracerName = 'dartastic_otel_libs_outreach';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class OutreachResult {
  const OutreachResult({
    this.orgId,
    this.entityKind,
    this.entityId,
    this.prospectId,
    this.accountId,
    this.sequenceId,
    this.sequenceState,
    this.sequenceStateState,
    this.mailingId,
    this.mailingState,
    this.taskId,
    this.taskAction,
    this.callId,
    this.callDirection,
    this.mailboxId,
    this.optedOut,
    this.bouncedAt,
    this.rateLimitRemaining,
    this.statusCode,
  });

  /// Outreach organization (multi-tenant scope).
  final String? orgId;

  /// `prospect` / `account` / `sequence` / `sequence_state` /
  /// `mailing` / `task` / `call` / `email` / `template` / `snippet` /
  /// `user` / `opportunity` / `mailbox`.
  final String? entityKind;

  final String? entityId;

  final String? prospectId;
  final String? accountId;

  final String? sequenceId;

  /// `sequence_state` is the per-prospect membership in a sequence.
  final String? sequenceState;

  /// `active` / `paused` / `finished` / `replied` / `failed` /
  /// `bounced` / `pending` / `unsubscribed`.
  final String? sequenceStateState;

  final String? mailingId;

  /// `draft` / `scheduled` / `sending` / `sent` / `pending_send` /
  /// `failed` / `bounced` / `replied` / `opened` / `clicked`.
  final String? mailingState;

  final String? taskId;

  /// `email` / `call` / `general` / `linkedin_send_message` /
  /// `linkedin_view_profile`.
  final String? taskAction;

  final String? callId;

  /// `inbound` / `outbound`.
  final String? callDirection;

  /// Mailbox the send went through (rate limits are per-mailbox).
  final String? mailboxId;

  /// `true` if the prospect is opted-out of further sending.
  final bool? optedOut;

  /// Unix sec when the email bounced (if any).
  final int? bouncedAt;

  /// Per-token rate-limit headroom (`x-ratelimit-remaining`).
  final int? rateLimitRemaining;

  final int? statusCode;
}

class OutreachCallResult<T> {
  const OutreachCallResult({required this.value, this.result});
  final T value;
  final OutreachResult? result;
}

/// Wraps an Outreach API call in a CLIENT span. [operation] is one of
/// `prospects.list`, `prospects.create`, `accounts.create`,
/// `sequences.list`, `sequence_states.create`, `sequence_states.pause`,
/// `sequence_states.resume`, `mailings.create`, `tasks.create`,
/// `calls.create`, `opportunities.create`, `mailboxes.list`,
/// `templates.list`.
Future<T> tracedOutreach<T>({
  required String operation,
  required Future<OutreachCallResult<T>> Function() invoke,
}) async {
  if (outreachInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'outreach',
    'rpc.method': operation,
    'outreach.operation': operation,
  };

  final span = _tracer().startSpan(
    'outreach $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.orgId != null) {
        extras.add(OTel.attributeString(
          'outreach.org.id',
          r.result!.orgId!,
        ));
      }
      if (r.result!.entityKind != null) {
        extras.add(OTel.attributeString(
          'outreach.entity.kind',
          r.result!.entityKind!,
        ));
      }
      if (r.result!.entityId != null) {
        extras.add(OTel.attributeString(
          'outreach.entity.id',
          r.result!.entityId!,
        ));
      }
      if (r.result!.prospectId != null) {
        extras.add(OTel.attributeString(
          'outreach.prospect.id',
          r.result!.prospectId!,
        ));
      }
      if (r.result!.accountId != null) {
        extras.add(OTel.attributeString(
          'outreach.account.id',
          r.result!.accountId!,
        ));
      }
      if (r.result!.sequenceId != null) {
        extras.add(OTel.attributeString(
          'outreach.sequence.id',
          r.result!.sequenceId!,
        ));
      }
      if (r.result!.sequenceState != null) {
        extras.add(OTel.attributeString(
          'outreach.sequence_state.id',
          r.result!.sequenceState!,
        ));
      }
      if (r.result!.sequenceStateState != null) {
        extras.add(OTel.attributeString(
          'outreach.sequence_state.state',
          r.result!.sequenceStateState!,
        ));
        if (r.result!.sequenceStateState == 'failed') {
          span.setStatus(
            SpanStatusCode.Error,
            'Outreach sequence_state failed',
          );
        }
      }
      if (r.result!.mailingId != null) {
        extras.add(OTel.attributeString(
          'outreach.mailing.id',
          r.result!.mailingId!,
        ));
      }
      if (r.result!.mailingState != null) {
        extras.add(OTel.attributeString(
          'outreach.mailing.state',
          r.result!.mailingState!,
        ));
        if (r.result!.mailingState == 'failed' ||
            r.result!.mailingState == 'bounced') {
          span.setStatus(
            SpanStatusCode.Error,
            'Outreach mailing ${r.result!.mailingState}',
          );
        }
      }
      if (r.result!.taskId != null) {
        extras.add(OTel.attributeString(
          'outreach.task.id',
          r.result!.taskId!,
        ));
      }
      if (r.result!.taskAction != null) {
        extras.add(OTel.attributeString(
          'outreach.task.action',
          r.result!.taskAction!,
        ));
      }
      if (r.result!.callId != null) {
        extras.add(OTel.attributeString(
          'outreach.call.id',
          r.result!.callId!,
        ));
      }
      if (r.result!.callDirection != null) {
        extras.add(OTel.attributeString(
          'outreach.call.direction',
          r.result!.callDirection!,
        ));
      }
      if (r.result!.mailboxId != null) {
        extras.add(OTel.attributeString(
          'outreach.mailbox.id',
          r.result!.mailboxId!,
        ));
      }
      if (r.result!.optedOut != null) {
        extras.add(OTel.attributeBool(
          'outreach.prospect.opted_out',
          r.result!.optedOut!,
        ));
      }
      if (r.result!.bouncedAt != null) {
        extras.add(OTel.attributeInt(
          'outreach.mailing.bounced_at',
          r.result!.bouncedAt!,
        ));
      }
      if (r.result!.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'outreach.rate_limit.remaining',
          r.result!.rateLimitRemaining!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Outreach HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
