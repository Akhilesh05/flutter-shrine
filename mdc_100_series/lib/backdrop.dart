// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'model/product.dart';
import 'login.dart';

const double _kFlingVelocity = 2.0;

enum MenuItem { signOut, settings }

class _FrontLayer extends StatelessWidget {
  const _FrontLayer({
    Key key,
    this.onTap,
    this.child,
  }) : super(key: key);

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16.0,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(46.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              height: 40.0,
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BackdropTitle extends AnimatedWidget {
  final Function onPress;
  final Widget frontTitle;
  final Widget backTitle;

  const _BackdropTitle({
    Key key,
    Listenable listenable,
    this.onPress,
    @required this.frontTitle,
    @required this.backTitle,
  })  : assert(frontTitle != null),
        assert(backTitle != null),
        super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.listenable;

    return DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.title,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: Row(children: <Widget>[
        // branded icon
        SizedBox(
          width: 72.0,
          child: IconButton(
            padding: EdgeInsets.only(right: 8.0),
            onPressed: this.onPress,
            icon: Stack(children: <Widget>[
              Opacity(
                opacity: animation.value,
                child: ImageIcon(AssetImage('assets/slanted_menu.png')),
              ),
              FractionalTranslation(
                translation: Tween<Offset>(
                  begin: Offset.zero,
                  end: Offset(1.0, 0.0),
                ).evaluate(animation),
                child: ImageIcon(AssetImage('assets/diamond.png')),
              )]),
          ),
        ),
        // Here, we do a custom cross fade between backTitle and frontTitle.
        // This makes a smooth animation between the two texts.
        Stack(
          children: <Widget>[
            Opacity(
              opacity: CurvedAnimation(
                parent: ReverseAnimation(animation),
                curve: Interval(0.5, 1.0),
              ).value,
              child: FractionalTranslation(
                translation: Tween<Offset>(
                  begin: Offset.zero,
                  end: Offset(0.5, 0.0),
                ).evaluate(animation),
                child: Semantics(
                    label: 'hide categories menu',
                    child: ExcludeSemantics(child: backTitle)
                ),
              ),
            ),
            Opacity(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Interval(0.5, 1.0),
              ).value,
              child: FractionalTranslation(
                translation: Tween<Offset>(
                  begin: Offset(-0.25, 0.0),
                  end: Offset.zero,
                ).evaluate(animation),
                child: Semantics(
                    label: 'show categories menu',
                    child: ExcludeSemantics(child: frontTitle)
                ),
              ),
            ),
          ],
        )
      ]),
    );
  }
}

/// Builds a Backdrop.
///
/// A Backdrop widget has two layers, front and back. The front layer is shown
/// by default, and slides down to show the back layer, from which a user
/// can make a selection. The user can also configure the titles for when the
/// front or back layer is showing.
class Backdrop extends StatefulWidget {
  final Category currentCategory;
  final Widget frontLayer;
  final Widget backLayer;
  final Widget frontTitle;
  final Widget backTitle;

  const Backdrop({
    @required this.currentCategory,
    @required this.frontLayer,
    @required this.backLayer,
    @required this.frontTitle,
    @required this.backTitle,
  })  : assert(currentCategory != null),
        assert(frontLayer != null),
        assert(backLayer != null),
        assert(frontTitle != null),
        assert(backTitle != null);

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with SingleTickerProviderStateMixin {
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');
  AnimationController _controller;
  bool darkMode = false, stayLoggedIn = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(Backdrop old) {
    super.didUpdateWidget(old);

    if (widget.currentCategory != old.currentCategory) {
      _toggleBackdropLayerVisibility();
    } else if (!_frontLayerVisible) {
      _controller.fling(velocity: _kFlingVelocity);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _frontLayerVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleBackdropLayerVisibility() {
    _controller.fling(
        velocity: _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    const double layerTitleHeight = 48.0;
    final Size layerSize = constraints.biggest;
    final double layerTop = layerSize.height - layerTitleHeight;

    Animation<RelativeRect> layerAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0.0, layerTop, 0.0, -layerTop),
      end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    ).animate(_controller.view);

    return Stack(
      key: _backdropKey,
      children: <Widget>[
        ExcludeSemantics(
          child: widget.backLayer,
          excluding: _frontLayerVisible,
        ),
        PositionedTransition(
          rect: layerAnimation,
          child: _FrontLayer(
            onTap: _toggleBackdropLayerVisibility,
            child: widget.frontLayer,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      brightness: Brightness.light,
      elevation: 0.0,
      titleSpacing: 0.0,
      title: _BackdropTitle(
        listenable: _controller.view,
        onPress: _toggleBackdropLayerVisibility,
        frontTitle: widget.frontTitle,
        backTitle: widget.backTitle,
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.search,
            semanticLabel: 'login',
          ),
          onPressed: () {
            showSearch(context: context, delegate: ProductSearchDelegate());
          },
        ),
        PopupMenuButton(
          onSelected: (MenuItem selected) {
            switch (selected) {
              case MenuItem.signOut:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
                break;
              case MenuItem.settings:
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => Settings(
                    darkMode: darkMode,
                    stayLoggedIn: stayLoggedIn,
                    onChange: (Map<String, Object> changes) => setState(() {
                      if (changes.containsKey(Settings.DARK_MODE)) {
                        darkMode = changes[Settings.DARK_MODE];
                      } else if (changes.containsKey(Settings.STAY_LOGGED_IN)) {
                        stayLoggedIn = changes[Settings.STAY_LOGGED_IN];
                      }
                    }),
                  ),
                );
                break;
              default:
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuItem>>[
            PopupMenuItem(
              value: MenuItem.settings,
              child: LeadingIcon(
                icon: Icon(Icons.settings, semanticLabel: 'settings',),
                child: Text('Settings'),
              ),
            ),
            PopupMenuItem(
              value: MenuItem.signOut,
              child: LeadingIcon(
                icon: Icon(Icons.exit_to_app, semanticLabel: 'log out',),
                child: Text('Log out'),
              ),
            ),
          ],
        ),
      ],
    );
    return Scaffold(
      appBar: appBar,
      body: LayoutBuilder(
        builder: _buildStack,
      ),
    );
  }
}

class LeadingIcon extends StatelessWidget {
  final Widget icon, child;

  LeadingIcon({@required this.icon, @required this.child}) : assert(icon != null), assert(child != null);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(child: icon, margin: EdgeInsets.only(right: 8),),
      child,
    ],
  );
}

class Settings extends StatefulWidget {
  final void Function(Map<String, Object>) onChange;
  final bool darkMode, stayLoggedIn;
  static const String DARK_MODE = 'Dark mode';
  static const String STAY_LOGGED_IN = 'Stay logged in';

  Settings({
    @required this.darkMode,
    @required this.stayLoggedIn,
    this.onChange,
  }) : assert(darkMode != null), assert(stayLoggedIn != null);

  @override
  State<Settings> createState() => _Settings(darkMode, stayLoggedIn);
}

class _Settings extends State<Settings> {
  bool _lDarkMode, _lStayLoggedIn;

  _Settings(this._lDarkMode, this._lStayLoggedIn);

  bool get _darkMode => _lDarkMode;
  set _darkMode(bool value) {
    widget.onChange({Settings.DARK_MODE: value});
    setState(() {
      _lDarkMode = value;
    });
  }

  bool get _stayLoggedIn => _lStayLoggedIn;
  set _stayLoggedIn(bool value) {
    widget.onChange({Settings.STAY_LOGGED_IN: value});
    setState(() {
      _lStayLoggedIn = value;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Container(
        padding: EdgeInsets.all(16),
        child: Text('Settings', style: Theme.of(context).textTheme.headline,),
      ),
      ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: ListTile.divideTiles(
          context: context,
          tiles: <ListTile>[
            ListTile(
              title: Text(Settings.DARK_MODE),
              onTap: () => _darkMode = !_darkMode,
              trailing: Switch(
                value: _darkMode,
                onChanged: (bool value) => _darkMode = value,
              ),
            ),
            ListTile(
              title: Text(Settings.STAY_LOGGED_IN),
              onTap: () => _stayLoggedIn = !_stayLoggedIn,
              trailing: Switch(
                value: _stayLoggedIn,
                onChanged: (bool value) => _stayLoggedIn = value,
              ),
            ),
          ]
        ).toList(),
      ),
    ],
  );

}

class ProductSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) => <Widget>[
    IconButton(
      icon: Icon(Icons.clear, semanticLabel: 'clear',),
      onPressed: () {
        query = '';
        showSuggestions(context);
      },
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back, semanticLabel: 'back',),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('You typed $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestions = query.isEmpty ? [] : [
      '${query}s',
      '$query alternatives',
    ];
    return ListView(
      children: ListTile.divideTiles(
        context: context,
        tiles: suggestions.map((String suggestion) => ListTile(
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        )),
      ).toList(),
    );
  }

}
