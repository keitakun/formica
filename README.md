> [!WARNING]  
> **THIS IS A PROOF-OF-CONCEPT PACKAGE**  
> The use in production is highly discouraged

# Formica

Formica is a multi nested reactive router for Flutter.

> [!NOTE]
> This is a POC project. It's not optimized for performance nor using Flutter's best practices.  
> It uses the Flutter's Navigator, but it's not fully implemented to handle all Navigator's methods.

## Motivation
Flutter's routing/navigation system can be a bit tricky for nested routing.  
Creating a custom router or a catch-all route will rebuild the widget causing a "navigation".

Having a re-usable route in diferent nested routes. 

Example:  
`/products/detail/some_id`  
`/category/something/detail/some_id`  
`/cart/detail/some_id`  

In all these cases `/detail/some_id` could be a separate Widget having it's own route rule such `/detail/<id>` nested in each parent.

```
ProductWidget [route='/products/']
  DetailWidget [route='/detail/<id>']
CategoryWidget [route='/category/<category>/']
  DetailWidget [route='/detail/<id>']
CartWidget [route='/cart/']
  DetailWidget [route='/detail/<id>']
```

Having route reactive widgets.

## Features
- Multi-plataform (desktop, mobile, web)
- [Nested routes](#nested-routes)
- Uses Flutters native Navigator.of(context).pushNamed('') for navigation
- No rebuild on parent
- Route reactive widgets, so you can have multiple route aware widgets in same context
- Simple syntax
- Relative routes
- Route parameters with Regex patterns
- Routed Dialogs

## Getting Started
After adding Formica into the project, the base MaterialApp should use the `builder` to build the content with the Formica inside it.

```dart
MaterialApp(
  builder: (context, child) => Scaffold(
    body: Formica(
      routes: [
        FormicaRoute(
          route: '/',
          builder: (context) => Text('Hello world', ),
        ),
      ],
    ),
  ),
);
```

### Route patterns
Each FormicaRoute's route pattern should have only the relative path's pattern.

```
/literal/path/<param_name>/<anotehr_param_name|regex>
```

Literal path parts are case sensitive matched with the requested route.

Use `<param_name>` for parameters.  
It matches anything `(.*?)` until next expression.  
OR you may use a regex pattern after parameter name separated by `|` `<param_name|regex>`

`param_name` will be mapped in a `Map<String,String>` with requested value.

Examples:
```dart
FormicaRoute(
  route: '/dashboard/',
  ...
)

FormicaRoute(
  route: '/product/<id>',
  ...
)

FormicaRoute(
  route: '/product/<id|\d+>',
  ...
)

FormicaRoute(
  route: '/product/<id|pid_\d+>',
  ...
)

```

FormicaRoute also accepts multiple route patterns using the `routes` instead of `route`

```
FormicaRoute(
  routes: ['/product', '/product/something],
)
```


### Nested routes

You can place any number of Formica instances inside the MaterialApp's Formica instance.


```dart
MaterialApp(
  builder: (context, child) => Scaffold(
    body: Formica(
      routes: [
        FormicaRoute(
          route: '/',
          builder: (context) => Column(
            children: [
              Formica(
                routes: [
                  FormicaRoute(
                    route: '/',
                    builder: (context) => Text('Top'),
                  ),
                  FormicaRoute(
                    route: '/page1',
                    builder: (context) => Formica(
                      routes: [
                        FormicaRoute(
                          route: '/',
                          builder: (context) => Text('Page 1'),
                        ),
                        FormicaRoute(
                          route: '/inner',
                          builder: (context) => Text('Inside Page 1'),
                        ),
                      ],
                    ),
                  ),
                  FormicaRoute(
                    route: '/page2',
                    builder: (context) => Text('Page 2'),
                  ),
                ],
              ),
            ],

            // Another formica instance so it's independent from above
            Formica(
              routes: [
                FormicaRoute(
                  route: '/page1',
                  builder: (context) => Text('Independent 1'),
                ),
              ]
            )

            // Helper class to generate Formica instances for each FormicaRoute.
            Formica.list(
              routes: [
                FormicaRoute(
                  route: '/',
                  builder: (context) => Text('Independent list 1'),
                ),
                FormicaRoute(
                  route: '/page1',
                  builder: (context) => Text('Independent list 2'),
                ),
                FormicaRoute(
                  route: '/page2',
                  builder: (context) => Text('Independent list 3'),
                ),
              ]
            )
          ),
        ),
      ],
    ),
  ),
);
```

In above example:

Navigating to `/` will render:
```
Top
Independent list 1
```

Navigating to `/page1` will render:
```
Page 1
Independent 1
Independent list 1
Independent list 2
```

Navigating to `/page1/inner` will render:
```
Inside Page 1
Independent 1
Independent list 1
Independent list 2
```

Navigating to `/page1` will render:
```
Page 2
Independent list 1
Independent list 3
```


### Route reactive
As in the [Nested routes](#nested-routes) example, each Formica instance are independent and will render accordingly.

This way it's possible to have only parts of the screen being re-built reacting to route changes.

### Navigating
You can use Flutter's Navigator to navigate between routes.

```dart
Navigator.of(context).pushNamed('/some/route');

/// Will go back one fragment of the route (/page/nested/route -> /page/nested ) or remove the top-most dialog 
Navigator.of(context).pop();

```


### Dialogs
Having routed dialogs can be helpful when you want to show some content on top of another such a privacy policy dialog in a user registration.

```dart
FormicaRoute(
  route: '<_>/privacy',
  isOverlay: true,
  builder: (context) async {
    var result = await showDialog(
      ...
    );
    return null;
  }
)
```

The route above if placed inside the top-most Formica, will render at any route ending with `/privacy` placing the Dialog on top.

