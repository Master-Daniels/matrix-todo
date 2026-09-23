package com.example.flutter_todo

import android.app.Application

/**
 * Plain Application holder.
 *
 * Notification scheduling lives in MainActivity's FlutterEngine channel
 * ("flutter_todo/alarm") plus flutter_local_notifications. No headless
 * Dart engine here: a second engine would run main() twice and its
 * syncAll/cancelAll would wipe the UI isolate's schedules.
 */
class MyApplication : Application()
