// ignore_for_file: empty_catches

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:formica/src/stack_trace.dart';

import 'src/none.dart' // Stub implementation
    if (dart.library.io) 'src/platform_history_io.dart' // dart:io implementation
    if (dart.library.html) 'src/platform_history_web.dart';

/// Route transition animation.
/// It must return a ([Future], [Widget]) \n
/// where [Future] completes when the animation finishes \n
/// and [Widget] is the child wrapped with the animation such [AnimatedWidget].
typedef RouteTransition = (Future<void> onComplete, Widget animation) Function(
    BuildContext context, Widget child);

class Formica extends StatefulWidget {
  /// Breaks down routes into single route [Formica] instance for each route. \
  /// It's a helper when using in a [List]<[Widget]> like a [Column]
  ///
  /// ```
  /// Column(
  ///   children: Formica.list(
  ///     routes: [
  ///       FormicaRoute(...),
  ///       FormicaRoute(...),
  ///     ]
  ///   )
  /// )
  /// ```
  static List<Formica> list({
    required List<FormicaRoute> routes,
    RouteTransition? defaultAnimateIn,
    RouteTransition? defaultAnimateOut,
  }) {
    return routes
        .map((r) => Formica(
              routes: [r],
              defaultAnimateIn: defaultAnimateIn,
              defaultAnimateOut: defaultAnimateOut,
            ))
        .toList();
  }

  final List<FormicaRoute> routes;

  /// Default animation in transition;
  final RouteTransition? defaultAnimateIn;

  /// Default animation out transition;
  final RouteTransition? defaultAnimateOut;

  const Formica({
    super.key,
    required this.routes,
    this.defaultAnimateIn,
    this.defaultAnimateOut,
  });

  @override
  State<Formica> createState() => _FormicaState();
}

class _FormicaState extends State<Formica> {
  bool _isRoot = false;
  ValueNotifier<String> routeNotifier = ValueNotifier<String>('');
  FormicaRoute? parentRoute;

  FormicaPath path = FormicaPath(
    '',
    '/',
    '/',
    {},
  );
  FormicaRoute? currentRoute;

  @override
  void initState() {
    super.initState();
    if (context.findAncestorStateOfType<_FormicaState>() == null) {
      _isRoot = true;
    } else {
      _FormicaRouteBuilder? builder =
          context.findAncestorWidgetOfExactType<_FormicaRouteBuilder>();
      if (builder != null) {
        parentRoute = builder.route;
        for (var r in widget.routes) {
          r._parent = parentRoute;
        }
      }
      context
          .findAncestorStateOfType<_FormicaState>()
          ?.routeNotifier
          .addListener(_routeChangeNotified);
    }
    _checkRoutes();
  }

  @override
  didUpdateWidget(covariant Formica oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkRoutes();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    routeNotifier.dispose();
  }

  _routeChangeNotified() {
    if (_checkRoutes()) {
      setState(() {});
    }
  }

  _onRouteChange(String route) {
    if (_checkRoutes(route)) {
      setState(() {});
    }
  }

  bool _checkRoutes([String? requestPath]) {
    if (!mounted) return false;
    _FormicaState? parentState =
        context.findAncestorStateOfType<_FormicaState>();
    if (requestPath == null && parentState != null) {
      requestPath = parentState.path.remainingPath;
    }
    requestPath ??= '/';
    requestPath = normalizePath(requestPath);

    if (requestPath == path.requestPath) {
      path = FormicaPath(parentState?.path.requestPath ?? requestPath,
          path.rawPath, requestPath, {}, '', parentState?.path);
      routeNotifier.value = requestPath;
      return false;
    }

    FormicaRoute? matchedRoute;
    String? matchedPath;
    Map<String, String>? params;
    String? remaining;
    int score = -1;
    int maxScore = 999999;
    for (FormicaRoute route in widget.routes) {
      for (FormicaRoutePattern p in route.routes) {
        if (p.raw == requestPath) {
          matchedRoute = route;
          matchedPath = requestPath;
          params = {};
          remaining = '';
          score = maxScore;
          break;
        }

        FormicaRouteMatch? m = p.match(requestPath);
        if (m != null) {
          if (p.score > score) {
            matchedRoute = route;
            matchedPath = m.matched;
            params = m.params;
            remaining = m.remaining;
            score = p.score;
          }
        }
      }
      if (score == maxScore) break;
    }

    path = FormicaPath(
        parentState?.path.requestPath ?? requestPath,
        matchedPath ?? '',
        matchedPath ?? '',
        params ?? {},
        remaining ?? '',
        parentState?.path);

    if (matchedRoute == currentRoute) {
      routeNotifier.value = requestPath;
    } else {
      currentRoute = matchedRoute;
      routeNotifier.value = requestPath;
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isRoot) {
      return _FormicaNavigator(
        onRouteChange: _onRouteChange,
        child: _FormicaRouteBuilder(route: currentRoute),
      );
    } else {
      return _FormicaRouteBuilder(route: currentRoute);
    }
  }
}

String normalizePath(
  String path, [
  bool leadingSlash = true,
  bool trailingSlash = false,
]) {
  path = path.replaceAll(RegExp(r'/+'), '/');
  path = path.replaceFirstMapped(
    RegExp(r'^/?(.*?)\/?$'),
    (match) =>
        '${leadingSlash ? '/' : ''}${match.group(1)}${trailingSlash ? '/' : ''}',
  );
  return path;
}

class FormicaPath {
  final FormicaPath? parent;
  final String requestPath;
  final String rawPath;
  final String path;
  final String? remainingPath;
  late final Map<String, String> _params;

  FormicaPath(
      this.requestPath, this.rawPath, this.path, Map<String, String> params,
      [this.remainingPath, this.parent]) {
    _params = params;
  }

  Map<String, String> get params {
    return {
      if (parent != null) ...parent!.params,
      ..._params,
    };
  }
}

class FormicaRoute {
  /// Multiple route patterns for route \
  /// If [routes] is set, [route] must be null
  ///
  /// `lalala`
  late final List<FormicaRoutePattern> routes;

  /// Either if it's a widget in the build tree or independent like an [Overlay] or [Dialog]. \
  /// If [true] should not return a Widget on build.
  final bool isOverlay;

  /// Widget Builder
  final FutureOr<Widget?> Function(BuildContext context) builder;

  /// Animate in transition. [onComplete] is a [Future] to notify when animation was finished. \
  /// If null, it'll use the closest parent's [Formica.defaultAnimateIn]
  final RouteTransition? animateIn;

  /// Animate out transition. [onComplete] is a [Future] to notify when animation was finished.
  /// If null, it'll use the closest parent's [Formica.defaultAnimateOut]
  final RouteTransition? animateOut;

  FormicaRoute? _parent;

  FormicaRoute({
    String? route,
    List<String>? routes,
    this.animateIn,
    this.animateOut,
    required this.builder,
    this.isOverlay = false,
  }) : assert((route == null) != (routes == null),
            'Only one of [route] or [routes] must be provided.') {
    routes ??= [route!];
    this.routes =
        routes.map((e) => FormicaRoutePattern(normalizePath(e))).toList();
  }

  List<FormicaRoutePattern> getRoutes({
    bool recursive = false,
  }) {
    if (recursive) {
      Set<String> rawPaths = {};
      List<FormicaRoutePattern> parentRoutes =
          _parent?.getRoutes(recursive: recursive) ??
              [FormicaRoutePattern('/')];
      for (FormicaRoutePattern parentRoute in parentRoutes) {
        for (FormicaRoutePattern route in routes) {
          rawPaths.add(normalizePath('${parentRoute.raw}/${route.raw}'));
        }
      }
      return rawPaths.map((e) => FormicaRoutePattern(e)).toList();
    }
    return List.from(routes);
  }

  bool matches(String path) {
    List<FormicaRoutePattern> routes = getRoutes(recursive: true);

    for (FormicaRoutePattern route in routes) {
      if (route.match(path) != null) return true;
    }
    return false;
  }
}

class FormicaRoutePattern {
  final String raw;
  late final RegExp re;
  late final List<String> paramIndexes;
  late final int score;
  FormicaRoutePattern(this.raw) {
    paramIndexes = [];
    int s = 0;
    String pattern = RegExp(
            r'(?:(?<path>[^<>]+)|(?:\<(?<param>[^\|\s\<]+)(?:\|(?<pattern>.*?))?\>))')
        .allMatches(raw)
        .map((m) {
      String? g;
      if ((g = m.namedGroup('pattern')) != null) {
        paramIndexes.add(m.namedGroup('param') ?? '');
        s += 2;
        return '(?<g${paramIndexes.length - 1}>$g)';
      } else if (m.namedGroup('param') != null) {
        paramIndexes.add(m.namedGroup('param')!);
        s += 1;
        return '(?<g${paramIndexes.length - 1}>[^\\/\\s]*?)';
      } else {
        s += 3;
        return m.group(0);
      }
    }).join('');
    score = s;
    re = RegExp(pattern);
  }

  FormicaRouteMatch? match(String input) {
    RegExpMatch? m = re.firstMatch(input);
    if (m == null) return null;
    Map<String, String> params = {};
    paramIndexes.asMap().forEach(
          (k, v) => params[v] = m.namedGroup('g$k') ?? '',
        );
    String remaining = input.substring(m.end);
    if (remaining.isNotEmpty &&
        !m.group(0)!.endsWith('/') &&
        !remaining.startsWith('/')) return null;
    return FormicaRouteMatch(
        normalizePath(m.group(0)!), params, normalizePath(remaining));
  }
}

class FormicaRouteMatch {
  final String matched;
  final Map<String, String> params;
  final String remaining;
  const FormicaRouteMatch(this.matched, this.params, this.remaining);
}

class _FormicaNavigator extends Navigator {
  final Widget child;
  final void Function(String route)? onRouteChange;
  const _FormicaNavigator({
    required this.child,
    this.onRouteChange,
  });

  @override
  NavigatorState createState() => _FormicaNavigatorState();

  @override
  // TODO: implement onGenerateRoute
  RouteFactory? get onGenerateRoute => (settings) {
        if (onRouteChange != null && settings.name != null) {
          onRouteChange!(settings.name!);
        }

        return PageRoutePlaceholder(
          settings: settings,
          builder: (context) => Container(),
        );
      };
}

class _FormicaNavigatorState extends NavigatorState {
  final List<_FormicaDialogEntry> _dialogRoutes = [];
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();

  final List<String> history = ['/'];
  
  PlatformHistory _platformHistory = PlatformHistory();

  Widget? _child;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _platformHistory.onPop.addListener(_onPlatformPop);
  }

  _onPlatformPop()
  {
    pushNamed(normalizePath(_platformHistory.onPop.value));
  }

  @override
  void pop<T extends Object?>([T? result]) {
    _FormicaNavigator nav = (widget as _FormicaNavigator);

    if (_dialogRoutes.isNotEmpty) {
      _dialogRoutes.last.popped.complete(result);
      _dialogRoutes.last.remove();
      _dialogRoutes.removeLast();
    }

    if (history.isEmpty) throw Exception('Something wrong, history is empty');
    if (history.length > 1) {
      history.removeLast();
    } else {
      history[0] = history[0].replaceFirst(RegExp(r'/[^/]$'), '');
    }

    _clearUnusedOverlays();

    if (nav.onRouteChange != null) nav.onRouteChange!(history.lastOrNull ?? '');
  }

  _clearUnusedOverlays() {
    if (history.isEmpty) return;
    List<_FormicaDialogEntry> toRemove = [];
    for (_FormicaDialogEntry fde in _dialogRoutes) {
      if (fde.route?.matches(history.last) != true) {
        fde.popped.complete(null);
        fde.remove();
        toRemove.add(fde);
      }
    }
    for (var element in toRemove) {
      _dialogRoutes.remove(element);
    }
  }

  @override
  Future<T?> push<T extends Object?>(Route<T> route) {
    if (route is PageRoutePlaceholder) {
      String path = normalizePath(route.settings.name ?? '');
      if (history.isEmpty || history.last != path) {
        history.add(path);
        _platformHistory.push(path);
      }
      _clearUnusedOverlays();

      return Future(() => null);
    }

    if (route is! DialogRoute) {
      throw Exception('Should only push [DialogRoute] instances');
    }

    StackTrace currentStack = StackTrace.current;
    _FormicaDialogEntry<T> entry =
        _FormicaDialogEntry<T>(route as DialogRoute);
    _overlayKey.currentState?.insert(entry);
    _dialogRoutes.add(entry);
    try {
      FormicaRoute formicaRoute = _stackTraceMap.entries
          .firstWhere(
            (e) => e.key.isChild(currentStack),
          )
          .value;
      entry.route = formicaRoute;
    } catch (e) {}

    _clearUnusedOverlays();

    return entry.popped.future;
  }

  @override
  Widget build(BuildContext context) {
    return _child ??= Stack(children: [
      (widget as _FormicaNavigator).child,
      Overlay(
        key: _overlayKey,
      ),
    ]);
  }
}

class PageRoutePlaceholder extends MaterialPageRoute {
  PageRoutePlaceholder({required super.builder, super.settings});
}

class _FormicaRouteBuilder extends StatefulWidget {
  final FormicaRoute? route;
  const _FormicaRouteBuilder({required this.route});

  @override
  State<_FormicaRouteBuilder> createState() => _FormicaRouteBuilderState();
}

class _FormicaRouteBuilderState extends State<_FormicaRouteBuilder> {
  bool _dirty = true;
  Widget? child;
  Widget? animatedChild;

  @override
  void initState() {
    super.initState();
    _buildChild();
  }

  @override
  void didUpdateWidget(covariant _FormicaRouteBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route != oldWidget.route) {
      _dirty = true;
      child = null;
      _buildChild();
    }
  }

  _buildChild() async {
    if (_dirty) {
      if (widget.route?.isOverlay == true) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _stackTraceMap[StackTrace.current] = widget.route!;
          widget.route?.builder(context);
        });
      } else {
        child = (widget.route?.builder != null)
            ? await widget.route?.builder(context)
            : null;
        if(widget.route?.animateIn != null)
        {
          Future<void> onComplete;
          Widget animated;
          (onComplete, animated) = widget.route!.animateIn!(context, child!);
          animatedChild = animated;
          onComplete.then((value) => print("ANIMATION IN COMPLETE"));
        }
        try {
          setState(() {});
        } catch (e) {}
      }
    }
    _dirty = false;
  }

  @override
  Widget build(BuildContext context) {
    return animatedChild ?? child ?? const SizedBox.shrink();
  }
}

class _FormicaDialogEntry<T> extends OverlayEntry {
  static Animation<double> nullAnimation =
      Animation.fromValueListenable(ValueNotifier(0));

  static buildBarrier(DialogRoute route, [void Function()? onDismiss]) {
    return ModalBarrier(
      onDismiss: onDismiss,
      color: route.barrierColor,
      dismissible: route.barrierDismissible,
      semanticsLabel: route.barrierLabel,
    );
  }

  Completer<T> popped = Completer<T>();
  FormicaRoute? route;

  _FormicaDialogEntry(DialogRoute route)
      : super(
            builder: (context) => Stack(
                  children: [
                    buildBarrier(route, () => Navigator.of(context).pop()),
                    route.buildPage(context, nullAnimation, nullAnimation),
                  ],
                ));
}

Map<StackTrace, FormicaRoute> _stackTraceMap = {};
