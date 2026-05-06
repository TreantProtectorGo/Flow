import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_timer_plan.dart';

export '../models/task_timer_plan.dart';

class TaskTimerSystemPayload {
  final TaskTimerPayloadType type;
  final String taskId;
  final String? nextTaskId;
  final String? sectionId;
  final int phaseIndex;

  const TaskTimerSystemPayload({
    required this.type,
    required this.taskId,
    required this.nextTaskId,
    required this.sectionId,
    required this.phaseIndex,
  });

  factory TaskTimerSystemPayload.fromMap(Map<Object?, Object?> map) {
    final String typeName = map['type'] as String? ?? 'phaseEnd';
    return TaskTimerSystemPayload(
      type: TaskTimerPayloadType.values.firstWhere(
        (TaskTimerPayloadType type) => type.name == typeName,
        orElse: () => TaskTimerPayloadType.phaseEnd,
      ),
      taskId: map['taskId'] as String? ?? '',
      nextTaskId: map['nextTaskId'] as String?,
      sectionId: map['sectionId'] as String?,
      phaseIndex: (map['phaseIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class TaskTimerSystemControlEvent {
  final String action;
  final String taskId;
  final String alarmId;
  final int? remainingSeconds;
  final DateTime occurredAt;

  const TaskTimerSystemControlEvent({
    required this.action,
    required this.taskId,
    required this.alarmId,
    required this.remainingSeconds,
    required this.occurredAt,
  });

  factory TaskTimerSystemControlEvent.fromMap(Map<Object?, Object?> map) {
    final double occurredAtMillis =
        (map['occurredAt'] as num?)?.toDouble() ??
        DateTime.now().millisecondsSinceEpoch.toDouble();
    return TaskTimerSystemControlEvent(
      action: map['action'] as String? ?? '',
      taskId: map['taskId'] as String? ?? '',
      alarmId: map['alarmId'] as String? ?? '',
      remainingSeconds: (map['remainingSeconds'] as num?)?.toInt(),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(occurredAtMillis.round()),
    );
  }
}

abstract class TaskTimerSystemScheduler {
  Future<void> initialize();

  Future<void> scheduleTaskTimeline(TaskTimerPlan plan);

  Future<void> cancelTaskTimeline(String taskId);

  Future<void> rescheduleTaskTimeline(TaskTimerPlan plan);
}

final Provider<TaskTimerSystemScheduler> taskTimerSystemSchedulerProvider =
    Provider<TaskTimerSystemScheduler>((Ref ref) {
      return PlatformTaskTimerSystemScheduler.instance;
    });

final StreamProvider<TaskTimerSystemPayload> taskTimerSystemPayloadProvider =
    StreamProvider<TaskTimerSystemPayload>((Ref ref) {
      return PlatformTaskTimerSystemScheduler.instance.payloads;
    });

final StreamProvider<TaskTimerSystemControlEvent>
taskTimerSystemControlEventProvider =
    StreamProvider<TaskTimerSystemControlEvent>((Ref ref) {
      return PlatformTaskTimerSystemScheduler.instance.controlEvents;
    });

class PlatformTaskTimerSystemScheduler implements TaskTimerSystemScheduler {
  static const MethodChannel _channel = MethodChannel(
    'focus/task_timer_system',
  );

  static final PlatformTaskTimerSystemScheduler instance =
      PlatformTaskTimerSystemScheduler._();

  final StreamController<TaskTimerSystemPayload> _payloadController =
      StreamController<TaskTimerSystemPayload>.broadcast();
  final StreamController<TaskTimerSystemControlEvent> _controlEventController =
      StreamController<TaskTimerSystemControlEvent>.broadcast();
  bool _initialized = false;

  PlatformTaskTimerSystemScheduler._();

  Stream<TaskTimerSystemPayload> get payloads => _payloadController.stream;
  Stream<TaskTimerSystemControlEvent> get controlEvents =>
      _controlEventController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;
  }

  @override
  Future<void> scheduleTaskTimeline(TaskTimerPlan plan) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await initialize();
    try {
      await _channel.invokeMethod<void>('scheduleTaskTimeline', plan.toJson());
    } on MissingPluginException catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Missing platform plugin: $e');
    } catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Failed to schedule timeline: $e');
    }
  }

  @override
  Future<void> cancelTaskTimeline(String taskId) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await initialize();
    try {
      await _channel.invokeMethod<void>('cancelTaskTimeline', <String, Object?>{
        'taskId': taskId,
      });
    } on MissingPluginException catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Missing platform plugin: $e');
    } catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Failed to cancel timeline: $e');
    }
  }

  @override
  Future<void> rescheduleTaskTimeline(TaskTimerPlan plan) async {
    await cancelTaskTimeline(plan.taskId);
    await scheduleTaskTimeline(plan);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    final Object? arguments = call.arguments;
    switch (call.method) {
      case 'taskTimerPayload':
        if (arguments is Map<Object?, Object?>) {
          _payloadController.add(TaskTimerSystemPayload.fromMap(arguments));
        }
      case 'taskTimerControlEvents':
        if (arguments is List<Object?>) {
          for (final Object? event in arguments) {
            if (event is Map<Object?, Object?>) {
              _controlEventController.add(
                TaskTimerSystemControlEvent.fromMap(event),
              );
            }
          }
        }
    }
  }
}
