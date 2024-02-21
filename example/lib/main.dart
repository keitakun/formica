import 'dart:async';

import 'package:flutter/material.dart';
import 'package:formica/formica.dart';

void main() {
  runApp(const MyApp());
}

const List<String> URIs = [
  '/',
  '/test',
  '/test1',
  '/a/a/overlay',
  '/test1/overlay'
];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(builder: (context, child) {
      return Scaffold(
        body: Formica(
          routes: [
            FormicaRoute(
              route: '/',
              builder: (context) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Fornica Router example'),
                  ),
                  body: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Wrap(children: [
                          ...URIs.map(
                            (e) => TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(e),
                                child: Text(e)),
                          ),
                        ]),
                        ...Formica.list(
                          routes: [
                            FormicaRoute(
                                routes: ['/', '/test2'],
                                builder: (context) {
                                  print("BUILDING 1");
                                  return ElevatedButton(
                                    onPressed: () => Navigator.of(context)
                                        .pushNamed('/test1'),
                                    child: Text('Hello 1'),
                                  );
                                }),
                            FormicaRoute(
                                route: '/test1',
                                builder: (context) {
                                  print("BUILDING 2");
                                  return ElevatedButton(
                                    onPressed: () => Navigator.of(context)
                                        .pushNamed('/test2'),
                                    child: Text('Hello 4'),
                                  );
                                }),
                            FormicaRoute(
                              route: '<prefix>/overlay',
                              isOverlay: true,
                              builder: (context) async {
                                var r = await showDialog(
                                    context: context,
                                    barrierColor: Colors.red.withOpacity(0.2),
                                    barrierDismissible: true,
                                    builder: (context) {
                                      print(Navigator.of(context));
                                      return AlertDialog(
                                        content: Text('hello'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pushNamed('/'),
                                              child: Text('HELLO'))
                                        ],
                                      );
                                    });
                                print('POPED: $r');
                                return null;
                              },
                            ),
                          ],
                        ),
                      ]
                      // children: [
                      //   ElevatedButton(
                      //       onPressed: () => Navigator.of(context).pushNamed('/test'),
                      //       child: Text('PRESS ME')),
                      //   Text('HOME!'),
                      // ],
                      ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
