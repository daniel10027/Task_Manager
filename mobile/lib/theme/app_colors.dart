import 'package:flutter/material.dart';

/// Hand-picked palette for the Task Manager app: an indigo/violet seed for
/// a "productive but lively" feel, plus semantic colors for the online /
/// offline status pill and task-status chips.
class AppColors {
  AppColors._();

  static const seed = Color(0xFF5B5BF5);

  static const online = Color(0xFF10B981);
  static const onlineBg = Color(0xFFE6F9F1);
  static const offline = Color(0xFFB45309);
  static const offlineBg = Color(0xFFFEF3E2);

  static const statusTodo = Color(0xFF64748B);
  static const statusTodoBg = Color(0xFFF1F5F9);
  static const statusInProgress = Color(0xFF2563EB);
  static const statusInProgressBg = Color(0xFFE9EEFE);
  static const statusDone = Color(0xFF16A34A);
  static const statusDoneBg = Color(0xFFE7F8ED);
}
