// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformChannel extends StatefulWidget {
  const PlatformChannel({super.key});

  @override
  State<PlatformChannel> createState() => _PlatformChannelState();
}

class _PlatformChannelState extends State<PlatformChannel> {
  static const EventChannel eventChannel =
      EventChannel('samples.flutter.io/charging');

  final MethodChannel getStringMethodChannel =
      const MethodChannel('method.channel.example/getString');
  final MethodChannel voidMethodChannel =
      const MethodChannel('method.channel.example/voidMethod');
  final MethodChannel timerChannel =
      const MethodChannel('method.channel.example/timer');

  String _messageFromNative = 'No Native Message Available';
  String _chargingStatus = 'Battery status: unknown.';

  Future<void> _getStringFromNative() async {
    String returnedMEssage;
    try {
      final String? result =
          await getStringMethodChannel.invokeMethod('getStringMethodChannel');
      returnedMEssage = '$result';
    } on PlatformException {
      returnedMEssage = 'Failed to get String from native';
    }
    setState(() {
      _messageFromNative = returnedMEssage;
    });
  }

  Future<void> _printInConsoleNatively() async {
    String returnedMEssage;
    try {
      await voidMethodChannel.invokeMethod('voidMethodChannel');
    } on PlatformException {
      returnedMEssage = 'Failed to print';
    }
  }

  @override
  void initState() {
    super.initState();
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(Object? event) {
    setState(() {
      _chargingStatus =
          "Battery status: ${event == 'charging' ? '' : 'dis'}charging.";
    });
  }

  void _onError(Object error) {
    setState(() {
      _chargingStatus = 'Battery status: unknown.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_messageFromNative, key: const Key('msg')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _getStringFromNative,
                  child: const Text('Get String from Native'),
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _printInConsoleNatively,
                  child: const Text('Print in Console Natively'),
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _printInConsoleNatively,
                  child: const Text('Call method every 5 seconds'),
                ),
              ),
            ],
          ),
          Text(_chargingStatus),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: PlatformChannel()));
}
