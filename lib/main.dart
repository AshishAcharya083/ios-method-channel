import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformChannel extends StatefulWidget {
  const PlatformChannel({super.key});

  @override
  State<PlatformChannel> createState() => _PlatformChannelState();
}

class _PlatformChannelState extends State<PlatformChannel> {
  // EventChannel for receiving battery status updates from the native platform.
  static const EventChannel eventChannel =
      EventChannel('samples.flutter.io/charging');

  // MethodChannel for sending a request to the native platform to get a string.
  final MethodChannel getStringMethodChannel =
      const MethodChannel('method.channel.example/getString');

  // MethodChannel for invoking a void method on the native platform.
  final MethodChannel voidMethodChannel =
      const MethodChannel('method.channel.example/voidMethod');

  String _messageFromNative = 'No Native Message Available';
  String _chargingStatus = 'Battery status: unknown.';
  Timer? _timer;
  final ValueNotifier<int> _counterNotifier = ValueNotifier<int>(0);
  bool _isTimerRunning = false;

  // Fetches a string from the native platform using MethodChannel.
  Future<void> _getStringFromNative() async {
    String returnedMessage;
    try {
      // Invoking the method on the native platform and awaiting the response.
      final String? result =
          await getStringMethodChannel.invokeMethod('getStringMethodChannel');
      returnedMessage = '$result';
    } on PlatformException {
      returnedMessage = 'Failed to get String from native';
    }
    setState(() {
      _messageFromNative = returnedMessage;
    });
  }

  // Invokes a void method on the native platform that prints a message.
  Future<void> _printInConsoleNatively() async {
    try {
      await voidMethodChannel.invokeMethod('voidMethodChannel');
    } on PlatformException {
      // Handle exception if the method invocation fails.
    }
  }

  // Toggles the timer that periodically invokes a native method.
  void _startOrStopTimer() {
    if (_isTimerRunning) {
      // If the timer is running, stop it and reset the counter.
      _counterNotifier.value = 0;
      _timer?.cancel();
    } else {
      // If the timer is not running, start it.
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        print("Timer called");
        _counterNotifier.value++;

        // Invoke the native method every 5 seconds.
        await _printInConsoleNatively();
      });
    }
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
  }

  @override
  void initState() {
    super.initState();
    // Listen for battery status updates from the native platform via EventChannel.
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to prevent memory leaks.
    _timer?.cancel();
    super.dispose();
  }

  // Handles battery status updates from the native platform.
  void _onEvent(Object? event) {
    setState(() {
      _chargingStatus =
          "Battery status: ${event == 'charging' ? '' : 'dis'}charging.";
    });
  }

  // Handles errors when listening for battery status updates.
  void _onError(Object error) {
    setState(() {
      _chargingStatus = 'Battery status: unknown.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(_messageFromNative, key: const Key('msg')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _getStringFromNative,
                  child: const Text('Get String from Native'),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _printInConsoleNatively,
                  child: const Text('Print in Console Natively'),
                ),
              ),
              const Divider(),
              const SizedBox(
                height: 20,
              ),
              // Display how many times the method has been called.
              ValueListenableBuilder<int>(
                valueListenable: _counterNotifier,
                builder: (BuildContext context, int value, Widget? child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Method called '),
                      Text('$value ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          )),
                      const Text('times'),
                    ],
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _startOrStopTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTimerRunning
                        ? Colors.red
                        : null, // Button color changes based on timer state.
                  ),
                  child: Text(
                      _isTimerRunning ? 'Stop' : 'Call method every 5 seconds'),
                ),
              ),
              const Divider(),
              const SizedBox(
                height: 40,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Instead of calling method every 5 seconds, you can listen to event channel like:",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(_chargingStatus,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: PlatformChannel()));
}
