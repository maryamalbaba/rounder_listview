import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';


import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';



/// A delegate that supplies children for [CircleListScrollView].
///
/// [CircleListScrollView] lazily constructs its children during layout to avoid
/// creating more children than are visible through the [Viewport]. This
/// delegate is responsible for providing children to [CircleListScrollView]
/// during that stage.
///
/// See also:
///  * [ListWheelChildListDelegate], a delegate that supplies children using an
///    explicit list.
///  * [ListWheelChildLoopingListDelegate], a delegate that supplies infinite
///    children by looping an explicit list.
///  * [ListWheelChildBuilderDelegate], a delegate that supplies children using
///    a builder callback.
abstract class CircleListChildDelegate {
  /// Return the child at the given index. If the child at the given
  /// index does not exist, return null.
  Widget? build(BuildContext context, int index);

  /// Returns an estimate of the number of children this delegate will build.
  int? get estimatedChildCount;

  /// Returns the true index for a child built at a given index. Defaults to
  /// the given index, however if the delegate is [ListWheelChildLoopingListDelegate],
  /// this value is the index of the true element that the delegate is looping to.
  ///
  ///
  /// Example: [ListWheelChildLoopingListDelegate] is built by looping a list of
  /// length 8. Then, trueIndexOf(10) = 2 and trueIndexOf(-5) = 3.
  int trueIndexOf(int index) => index;

  /// Called to check whether this and the old delegate are actually 'different',
  /// so that the caller can decide to rebuild or not.
  bool shouldRebuild(covariant CircleListChildDelegate oldDelegate);
}

/// A delegate that supplies children for [CircleListScrollView] using an
/// explicit list.
///
/// [CircleListScrollView] lazily constructs its children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an explicit list, which is convenient but reduces the benefit
/// of building children lazily.
///
/// In general building all the widgets in advance is not efficient. It is
/// better to create a delegate that builds them on demand using
/// [ListWheelChildBuilderDelegate] or by subclassing [ListWheelChildDelegate]
/// directly.
///
/// This class is provided for the cases where either the list of children is
/// known well in advance (ideally the children are themselves compile-time
/// constants, for example), and therefore will not be built each time the
/// delegate itself is created, or the list is small, such that it's likely
/// always visible (and thus there is nothing to be gained by building it on
/// demand). For example, the body of a dialog box might fit both of these
/// conditions.
class CircleListChildListDelegate extends CircleListChildDelegate {
  /// Constructs the delegate from a concrete list of children.
  CircleListChildListDelegate({required this.children});

  /// The list containing all children that can be supplied.
  final List<Widget> children;

  @override
  int get estimatedChildCount => children.length;

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= children.length) return null;
    return IndexedSemantics(child: children[index], index: index);
  }

  @override
  bool shouldRebuild(covariant CircleListChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

/// A delegate that supplies infinite children for [CircleListScrollView] by
/// looping an explicit list.
///
/// [CircleListScrollView] lazily constructs its children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an explicit list, which is convenient but reduces the benefit
/// of building children lazily.
///
/// In general building all the widgets in advance is not efficient. It is
/// better to create a delegate that builds them on demand using
/// [ListWheelChildBuilderDelegate] or by subclassing [ListWheelChildDelegate]
/// directly.
///
/// This class is provided for the cases where either the list of children is
/// known well in advance (ideally the children are themselves compile-time
/// constants, for example), and therefore will not be built each time the
/// delegate itself is created, or the list is small, such that it's likely
/// always visible (and thus there is nothing to be gained by building it on
/// demand). For example, the body of a dialog box might fit both of these
/// conditions.
class CircleListChildLoopingListDelegate extends CircleListChildDelegate {
  /// Constructs the delegate from a concrete list of children.
  CircleListChildLoopingListDelegate({required this.children});

  /// The list containing all children that can be supplied.
  final List<Widget> children;

  @override
  int? get estimatedChildCount => null;

  @override
  int trueIndexOf(int index) => index % children.length;

  @override
  Widget? build(BuildContext context, int index) {
    if (children.isEmpty) return null;
    return IndexedSemantics(
        child: children[index % children.length], index: index);
  }

  @override
  bool shouldRebuild(covariant CircleListChildLoopingListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

/// A delegate that supplies children for [CircleListScrollView] using a builder
/// callback.
///
/// [CircleListScrollView] lazily constructs its children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an [IndexedWidgetBuilder] callback, so that the children do
/// not have to be built until they are displayed.
class CircleListChildBuilderDelegate extends CircleListChildDelegate {
  /// Constructs the delegate from a builder callback.
  CircleListChildBuilderDelegate({
    required this.builder,
    this.childCount,
  });

  /// Called lazily to build children.
  final IndexedWidgetBuilder builder;

  /// {@template flutter.widgets.wheelList.childCount}
  /// If non-null, [childCount] is the maximum number of children that can be
  /// provided, and children are available from 0 to [childCount] - 1.
  ///
  /// If null, then the lower and upper limit are not known. However the [builder]
  /// must provide children for a contiguous segment. If the builder returns null
  /// at some index, the segment terminates there.
  /// {@endtemplate}
  final int? childCount;

  @override
  int? get estimatedChildCount => childCount;

  @override
  Widget? build(BuildContext context, int index) {
    if (childCount == null) {
      final Widget child = builder(context, index);
      return IndexedSemantics(child: child, index: index);
    }
    if (index < 0 || index >= childCount!) return null;
    return IndexedSemantics(child: builder(context, index), index: index);
  }

  @override
  bool shouldRebuild(covariant CircleListChildBuilderDelegate oldDelegate) {
    return builder != oldDelegate.builder ||
        childCount != oldDelegate.childCount;
  }
}

/// A controller for scroll views whose items have the same size.
///
/// Similar to a standard [ScrollController] but with the added convenience
/// mechanisms to read and go to item indices rather than a raw pixel scroll
/// offset.
///
/// See also:
///
///  * [CircleListScrollView], a scrollable view widget with fixed size items
///    that this widget controls.
///  * [FixedExtentMetrics], the `metrics` property exposed by
///    [ScrollNotification] from [CircleListScrollView] which can be used
///    to listen to the current item index on a push basis rather than polling
///    the [FixedExtentScrollController].
class FixedExtentScrollController extends ScrollController {
  /// Creates a scroll controller for scrollables whose items have the same size.
  ///
  /// [initialItem] defaults to 0 and must not be null.
  FixedExtentScrollController({
    this.initialItem = 0,
  });

  /// The page to show when first creating the scroll view.
  ///
  /// Defaults to 0 and must not be null.
  final int initialItem;

  /// The currently selected item index that's closest to the center of the viewport.
  ///
  /// There are circumstances that this [FixedExtentScrollController] can't know
  /// the current item. Reading [selectedItem] will throw an [AssertionError] in
  /// the following cases:
  ///
  /// 1. No scroll view is currently using this [FixedExtentScrollController].
  /// 2. More than one scroll views using the same [FixedExtentScrollController].
  ///
  /// The [hasClients] property can be used to check if a scroll view is
  /// attached prior to accessing [selectedItem].
  int get selectedItem {
    assert(
      positions.isNotEmpty,
      'FixedExtentScrollController.selectedItem cannot be accessed before a '
      'scroll view is built with it.',
    );
    assert(
      positions.length == 1,
      'The selectedItem property cannot be read when multiple scroll views are '
      'attached to the same FixedExtentScrollController.',
    );
    final _FixedExtentScrollPosition position =
        this.position as _FixedExtentScrollPosition;
    return position.itemIndex;
  }

  /// Animates the controlled scroll view to the given item index.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  Future<void> animateToItem(
    int itemIndex, {
    required Duration duration,
    required Curve curve,
  }) async {
    if (!hasClients) {
      return;
    }

    final List<Future<void>> futures = <Future<void>>[];
    for (_FixedExtentScrollPosition position in positions as List<dynamic>) {
      futures.add(position.animateTo(
        itemIndex * position.itemExtent,
        duration: duration,
        curve: curve,
      ));
    }
    await Future.wait<void>(futures);
  }

  /// Changes which item index is centered in the controlled scroll view.
  ///
  /// Jumps the item index position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  void jumpToItem(int itemIndex) {
    for (_FixedExtentScrollPosition position in positions as List<dynamic>) {
      position.jumpTo(itemIndex * position.itemExtent);
    }
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return _FixedExtentScrollPosition(
      physics: physics,
      context: context,
      initialItem: initialItem,
      oldPosition: oldPosition,
    );
  }
}

/// Metrics for a [ScrollPosition] to a scroll view with fixed item sizes.
///
/// The metrics are available on [ScrollNotification]s generated from a scroll
/// views such as [CircleListScrollView]s with a [FixedExtentScrollController] and
/// exposes the current [itemIndex] and the scroll view's [itemExtent].
///
/// `FixedExtent` refers to the fact that the scrollable items have the same size.
/// This is distinct from `Fixed` in the parent class name's [FixedScrollMetric]
/// which refers to its immutability.
class FixedExtentMetrics extends FixedScrollMetrics {
  /// Creates an immutable snapshot of values associated with a
  /// [CircleListScrollView].
  FixedExtentMetrics({
    required double minScrollExtent,
    required double maxScrollExtent,
    required double pixels,
    required double viewportDimension,
    required AxisDirection axisDirection,
    required this.itemIndex,
    required this.devicePixelRatio,
  }) : super(
          minScrollExtent: minScrollExtent,
          maxScrollExtent: maxScrollExtent,
          pixels: pixels,
          viewportDimension: viewportDimension,
          axisDirection: axisDirection,
          devicePixelRatio: devicePixelRatio,
        );

  @override
  FixedExtentMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    int? itemIndex,
    double? devicePixelRatio,
  }) {
    return FixedExtentMetrics(
      minScrollExtent: minScrollExtent ?? this.minScrollExtent,
      maxScrollExtent: maxScrollExtent ?? this.maxScrollExtent,
      pixels: pixels ?? this.pixels,
      viewportDimension: viewportDimension ?? this.viewportDimension,
      axisDirection: axisDirection ?? this.axisDirection,
      itemIndex: itemIndex ?? this.itemIndex,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

  /// The scroll view's currently selected item index.
  final int itemIndex;

  /// The [FlutterView.devicePixelRatio] of the view that the [Scrollable].
  final double devicePixelRatio;
}

int _getItemFromOffset({
  required double offset,
  required double itemExtent,
  required double minScrollExtent,
  required double maxScrollExtent,
}) {
  return (_clipOffsetToScrollableRange(
              offset, minScrollExtent, maxScrollExtent) /
          itemExtent)
      .round();
}

double _clipOffsetToScrollableRange(
    double offset, double minScrollExtent, double maxScrollExtent) {
  return math.min(math.max(offset, minScrollExtent), maxScrollExtent);
}

/// A [ScrollPositionWithSingleContext] that can only be created based on
/// [_FixedExtentScrollable] and can access its `itemExtent` to derive [itemIndex].
class _FixedExtentScrollPosition extends ScrollPositionWithSingleContext
    implements FixedExtentMetrics {
  _FixedExtentScrollPosition({
    required ScrollPhysics physics,
    required ScrollContext context,
    required int initialItem,
    bool keepScrollOffset = true,
    ScrollPosition? oldPosition,
    String? debugLabel,
  })  : assert(context is _FixedExtentScrollableState,
            'FixedExtentScrollController can only be used with CircleListScrollViews'),
        super(
          physics: physics,
          context: context,
          initialPixels: _getItemExtentFromScrollContext(context) * initialItem,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  static double _getItemExtentFromScrollContext(ScrollContext context) {
    final _FixedExtentScrollableState scrollable =
        context as _FixedExtentScrollableState;
    return scrollable.itemExtent;
  }

  double get itemExtent => _getItemExtentFromScrollContext(context);

  @override
  int get itemIndex {
    return _getItemFromOffset(
      offset: pixels,
      itemExtent: itemExtent,
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
    );
  }

  @override
  FixedExtentMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    int? itemIndex,
    double? devicePixelRatio,
  }) {
    return FixedExtentMetrics(
      minScrollExtent: minScrollExtent ?? this.minScrollExtent,
      maxScrollExtent: maxScrollExtent ?? this.maxScrollExtent,
      pixels: pixels ?? this.pixels,
      viewportDimension: viewportDimension ?? this.viewportDimension,
      axisDirection: axisDirection ?? this.axisDirection,
      itemIndex: itemIndex ?? this.itemIndex,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

/// A [Scrollable] which must be given its viewport children's item extent
/// size so it can pass it on ultimately to the [FixedExtentScrollController].
class _FixedExtentScrollable extends Scrollable {
  const _FixedExtentScrollable({
    Key? key,
    AxisDirection axisDirection = AxisDirection.down,
    ScrollController? controller,
    ScrollPhysics? physics,
    required this.itemExtent,
    required ViewportBuilder viewportBuilder,
  }) : super(
          key: key,
          axisDirection: axisDirection,
          controller: controller,
          physics: physics,
          viewportBuilder: viewportBuilder,
        );

  final double itemExtent;

  @override
  _FixedExtentScrollableState createState() => _FixedExtentScrollableState();
}

/// This [ScrollContext] is used by [_FixedExtentScrollPosition] to read the
/// prescribed [itemExtent].
class _FixedExtentScrollableState extends ScrollableState {
  double get itemExtent {
    // Downcast because only _FixedExtentScrollable can make _FixedExtentScrollableState.
    final _FixedExtentScrollable actualWidget =
        widget as _FixedExtentScrollable;
    return actualWidget.itemExtent;
  }
}

/// A snapping physics that always lands directly on items instead of anywhere
/// within the scroll extent.
///
/// Behaves similarly to a slot machine wheel except the ballistics simulation
/// never overshoots and rolls back within a single item if it's to settle on
/// that item.
///
/// Must be used with a scrollable that uses a [FixedExtentScrollController].
///
/// Defers back to the parent beyond the scroll extents.
class CircleFixedExtentScrollPhysics extends ScrollPhysics {
  /// Creates a scroll physics that always lands on items.
  const CircleFixedExtentScrollPhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  CircleFixedExtentScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CircleFixedExtentScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    assert(
        position is _FixedExtentScrollPosition,
        'CircleFixedExtentScrollPhysics can only be used with Scrollables that uses '
        'the FixedExtentScrollController');

    final _FixedExtentScrollPosition metrics =
        position as _FixedExtentScrollPosition;

    // Scenario 1:
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at the scrollable's boundary.
    if ((velocity <= 0.0 && metrics.pixels <= metrics.minScrollExtent) ||
        (velocity >= 0.0 && metrics.pixels >= metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    // Create a test simulation to see where it would have ballistically fallen
    // naturally without settling onto items.
    final Simulation? testFrictionSimulation =
        super.createBallisticSimulation(metrics, velocity);

    // Scenario 2:
    // If it was going to end up past the scroll extent, defer back to the
    // parent physics' ballistics again which should put us on the scrollable's
    // boundary.
    if (testFrictionSimulation != null &&
        (testFrictionSimulation.x(double.infinity) == metrics.minScrollExtent ||
            testFrictionSimulation.x(double.infinity) ==
                metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    // From the natural final position, find the nearest item it should have
    // settled to.
    final int settlingItemIndex = _getItemFromOffset(
      offset: testFrictionSimulation?.x(double.infinity) ?? metrics.pixels,
      itemExtent: metrics.itemExtent,
      minScrollExtent: metrics.minScrollExtent,
      maxScrollExtent: metrics.maxScrollExtent,
    );

    final double settlingPixels = settlingItemIndex * metrics.itemExtent;

    // Scenario 3:
    // If there's no velocity and we're already at where we intend to land,
    // do nothing.
    if (velocity.abs() < tolerance.velocity &&
        (settlingPixels - metrics.pixels).abs() < tolerance.distance) {
      return null;
    }

    // Scenario 4:
    // If we're going to end back at the same item because initial velocity
    // is too low to break past it, use a spring simulation to get back.
    if (settlingItemIndex == metrics.itemIndex) {
      return SpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 0.5,
          stiffness: 100.0,
          ratio: 0.6,
        ),
        metrics.pixels,
        settlingPixels,
        velocity,
        tolerance: tolerance,
      );
    }

    // Scenario 5:
    // Create a new spring simulation on the item closest to the natural stopping point.
    return SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 100.0,
        ratio: 0.9,
      ),
      metrics.pixels,
      settlingPixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

/// A box in which children on a wheel can be scrolled.
///
/// This widget is similar to a [ListView] but with the restriction that all
/// children must be the same size along the scrolling axis.
///
/// When the list is at the zero scroll offset, the first child is aligned with
/// the middle of the viewport. When the list is at the final scroll offset,
/// the last child is aligned with the middle of the viewport
///
/// The children are rendered as if rotating on a wheel instead of scrolling on
/// a plane.
class CircleListScrollView extends StatefulWidget {
  /// Constructs a list in which children are scrolled a wheel. Its children
  /// are passed to a delegate and lazily built during layout.
  CircleListScrollView({
    Key? key,
    this.controller,
    this.physics,
    required this.itemExtent,
    this.onSelectedItemChanged,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    required List<Widget> children,
    this.axis = Axis.vertical,
    this.radius = 100,
  })  : assert(itemExtent > 0),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderCircleListViewport
              .clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        childDelegate = CircleListChildListDelegate(children: children),
        super(key: key);

  /// Constructs a list in which children are scrolled a wheel. Its children
  /// are managed by a delegate and are lazily built during layout.
  const CircleListScrollView.useDelegate({
    Key? key,
    this.controller,
    this.physics,
    required this.itemExtent,
    this.onSelectedItemChanged,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    required this.childDelegate,
    this.axis = Axis.vertical,
    this.radius = 100,
  })  : assert(itemExtent > 0),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderCircleListViewport
              .clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        super(key: key);

  /// Typically a [FixedExtentScrollController] used to control the current item.
  ///
  /// A [FixedExtentScrollController] can be used to read the currently
  /// selected/centered child item and can be used to change the current item.
  ///
  /// If none is provided, a new [FixedExtentScrollController] is implicitly
  /// created.
  ///
  /// If a [ScrollController] is used instead of [FixedExtentScrollController],
  /// [ScrollNotification.metrics] will no longer provide [FixedExtentMetrics]
  /// to indicate the current item index and [onSelectedItemChanged] will not
  /// work.
  ///
  /// To read the current selected item only when the value changes, use
  /// [onSelectedItemChanged].
  final ScrollController? controller;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// Size of each child in the main axis. Must not be null and must be
  /// positive.
  final double itemExtent;

  /// On optional listener that's called when the centered item changes.
  final ValueChanged<int>? onSelectedItemChanged;

  /// {@macro flutter.rendering.wheelList.clipToSize}
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.renderChildrenOutsideViewport}
  final bool renderChildrenOutsideViewport;

  /// A delegate that helps lazily instantiating child.
  final CircleListChildDelegate childDelegate;

  /// Define a main axis of scrolling
  final Axis axis;

  /// Circle radius
  final double radius;

  @override
  _CircleListScrollViewState createState() => _CircleListScrollViewState();
}

class _CircleListScrollViewState extends State<CircleListScrollView> {
  int _lastReportedItemIndex = 0;
  ScrollController? scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = widget.controller ?? FixedExtentScrollController();
    if (widget.controller is FixedExtentScrollController) {
      final FixedExtentScrollController controller =
          widget.controller as FixedExtentScrollController;
      _lastReportedItemIndex = controller.initialItem;
    }
  }

  @override
  void didUpdateWidget(CircleListScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != scrollController) {
      final ScrollController? oldScrollController = scrollController;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        oldScrollController!.dispose();
      });
      scrollController = widget.controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 &&
            widget.onSelectedItemChanged != null &&
            notification is ScrollUpdateNotification &&
            notification.metrics is FixedExtentMetrics) {
          final FixedExtentMetrics metrics =
              notification.metrics as FixedExtentMetrics;
          final int currentItemIndex = metrics.itemIndex;
          if (currentItemIndex != _lastReportedItemIndex) {
            _lastReportedItemIndex = currentItemIndex;
            final int trueIndex =
                widget.childDelegate.trueIndexOf(currentItemIndex);
            widget.onSelectedItemChanged!(trueIndex);
          }
        }
        return false;
      },
      child: _FixedExtentScrollable(
        axisDirection: widget.axis == Axis.horizontal
            ? AxisDirection.right
            : AxisDirection.down,
        controller: scrollController,
        physics: widget.physics,
        itemExtent: widget.itemExtent,
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return CircleListViewport(
            axis: widget.axis,
            radius: widget.radius,
            itemExtent: widget.itemExtent,
            clipToSize: widget.clipToSize,
            renderChildrenOutsideViewport: widget.renderChildrenOutsideViewport,
            offset: offset,
            childDelegate: widget.childDelegate,
          );
        },
      ),
    );
  }
}

/// Element that supports building children lazily for [ListWheelViewport].
class CircleListElement extends RenderObjectElement
    implements CircleListChildManager {
  /// Creates an element that lazily builds children for the given widget.
  CircleListElement(CircleListViewport widget) : super(widget);

  @override
  CircleListViewport get widget => super.widget as CircleListViewport;

  @override
  RenderCircleListViewport get renderObject =>
      super.renderObject as RenderCircleListViewport;

  // We inflate widgets at two different times:
  //  1. When we ourselves are told to rebuild (see performRebuild).
  //  2. When our render object needs a new child (see createChild).
  // In both cases, we cache the results of calling into our delegate to get the
  // widget, so that if we do case 2 later, we don't call the builder again.
  // Any time we do case 1, though, we reset the cache.

  /// A cache of widgets so that we don't have to rebuild every time.
  final Map<int, Widget?> _childWidgets = HashMap<int, Widget?>();

  /// The map containing all active child elements. SplayTreeMap is used so that
  /// we have all elements ordered and iterable by their keys.
  final SplayTreeMap<int, Element> _childElements =
      SplayTreeMap<int, Element>();

  @override
  void update(CircleListViewport newWidget) {
    final CircleListViewport oldWidget = widget;
    super.update(newWidget);
    final CircleListChildDelegate newDelegate = newWidget.childDelegate;
    final CircleListChildDelegate oldDelegate = oldWidget.childDelegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) performRebuild();
  }

  @override
  int? get childCount => widget.childDelegate.estimatedChildCount;

  @override
  void performRebuild() {
    _childWidgets.clear();
    super.performRebuild();
    if (_childElements.isEmpty) return;

    final int firstIndex = _childElements.firstKey()!;
    final int lastIndex = _childElements.lastKey()!;

    for (int index = firstIndex; index <= lastIndex; ++index) {
      final Element? newChild =
          updateChild(_childElements[index], retrieveWidget(index), index);
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    }
  }

  /// Asks the underlying delegate for a widget at the given index.
  ///
  /// Normally the builder is only called once for each index and the result
  /// will be cached. However when the element is rebuilt, the cache will be
  /// cleared.
  Widget? retrieveWidget(int index) {
    return _childWidgets.putIfAbsent(
        index, () => widget.childDelegate.build(this, index));
  }

  @override
  bool childExistsAt(int index) => retrieveWidget(index) != null;

  @override
  void createChild(int index, {required RenderBox? after}) {
    owner!.buildScope(this, () {
      final bool insertFirst = after == null;
      assert(insertFirst || _childElements[index - 1] != null);
      final Element? newChild =
          updateChild(_childElements[index], retrieveWidget(index), index);
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  void removeChild(RenderBox? child) {
    final int? index = renderObject.indexOf(child!);
    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index));
      final Element? result = updateChild(_childElements[index], null, index);
      assert(result == null);
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, dynamic newSlot) {
    final CircleListParentData? oldParentData =
        child?.renderObject?.parentData as CircleListParentData?;
    final Element? newChild = super.updateChild(child, newWidget, newSlot);
    final CircleListParentData? newParentData =
        newChild?.renderObject?.parentData as CircleListParentData?;
    if (newParentData != null) {
      newParentData.index = newSlot;
      if (oldParentData != null) newParentData.offset = oldParentData.offset;
    }

    return newChild;
  }

  @override
  void insertRenderObjectChild(RenderObject child, int slot) {
    final RenderCircleListViewport renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child as RenderBox,
        after: _childElements[slot - 1]?.renderObject as RenderBox?);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderObject child, Object? object, dynamic slot) {
    const String moveChildRenderObjectErrorMessage =
        'Currently we maintain the list in contiguous increasing order, so '
        'moving children around is not allowed.';
    assert(false, moveChildRenderObjectErrorMessage);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? newSlot) {
    assert(child.parent == renderObject);
    renderObject.remove(child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _childElements.forEach((int key, Element child) {
      visitor(child);
    });
  }
}

/// A viewport showing a subset of children on a wheel.
///
/// Typically used with [CircleListScrollView], this viewport is similar to
/// [Viewport] in that it shows a subset of children in a scrollable based
/// on the scrolling offset and the children's dimensions. But uses
/// [RenderCircleListViewport] to display the children on a wheel.
///
/// See also:
///
///  * [CircleListScrollView], widget that combines this viewport with a scrollable.
///  * [RenderCircleListViewport], the render object that renders the children
///    on a wheel.
class CircleListViewport extends RenderObjectWidget {
  /// Creates a viewport where children are rendered onto a wheel.
  ///
  /// The [diameterRatio] argument defaults to 2.0 and must not be null.
  ///
  /// The [itemExtent] argument in pixels must be provided and must be positive.
  ///
  /// The [clipToSize] argument defaults to true and must not be null.
  ///
  /// The [renderChildrenOutsideViewport] argument defaults to false and must
  /// not be null.
  ///
  /// The [offset] argument must be provided and must not be null.
  const CircleListViewport({
    Key? key,
    required this.itemExtent,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    required this.offset,
    required this.childDelegate,
    required this.axis,
    this.radius = 100,
  })  : assert(itemExtent > 0),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderCircleListViewport
              .clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        super(key: key);

  /// {@macro flutter.rendering.wheelList.itemExtent}
  final double itemExtent;

  /// {@macro flutter.rendering.wheelList.clipToSize}
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.renderChildrenOutsideViewport}
  final bool renderChildrenOutsideViewport;

  /// [ViewportOffset] object describing the content that should be visible
  /// in the viewport.
  final ViewportOffset offset;

  /// A delegate that lazily instantiates children.
  final CircleListChildDelegate childDelegate;

  final Axis axis;

  final double radius;

  @override
  CircleListElement createElement() => CircleListElement(this);

  @override
  RenderCircleListViewport createRenderObject(BuildContext context) {
    final CircleListElement childManager = context as CircleListElement;
    return RenderCircleListViewport(
      axis: axis,
      radius: radius,
      childManager: childManager,
      offset: offset,
      itemExtent: itemExtent,
      clipToSize: clipToSize,
      renderChildrenOutsideViewport: renderChildrenOutsideViewport,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCircleListViewport renderObject) {
    renderObject
      ..axis = axis
      ..radius = radius
      ..offset = offset
      ..itemExtent = itemExtent
      ..clipToSize = clipToSize
      ..renderChildrenOutsideViewport = renderChildrenOutsideViewport;
  }
}
//////////////////////////////////////
typedef _ChildSizingFunction = double Function(RenderBox child);

/// A delegate used by [RenderCircleListViewport] to manage its children.
///
/// [RenderCircleListViewport] during layout will ask the delegate to create
/// children that are visible in the viewport and remove those that are not.
abstract class CircleListChildManager {
  /// The maximum number of children that can be provided to
  /// [RenderCircleListViewport].
  ///
  /// If non-null, the children will have index in the range [0, childCount - 1].
  ///
  /// If null, then there's no explicit limits to the range of the children
  /// except that it has to be contiguous. If [childExistsAt] for a certain
  /// index returns false, that index is already past the limit.
  int? get childCount;

  /// Checks whether the delegate is able to provide a child widget at the given
  /// index.
  ///
  /// This function is not about whether the child at the given index is
  /// attached to the [RenderCircleListViewport] or not.
  bool childExistsAt(int index);

  /// Creates a new child at the given index and updates it to the child list
  /// of [RenderCircleListViewport]. If no child corresponds to `index`, then do
  /// nothing.
  ///
  /// It is possible to create children with negative indices.
  void createChild(int index, {required RenderBox? after});

  /// Removes the child element corresponding with the given RenderBox.
  void removeChild(RenderBox? child);
}

/// [ParentData] for use with [RenderCircleListViewport].
class CircleListParentData extends ContainerBoxParentData<RenderBox> {
  /// Index of this child in its parent's child list.
  int? index;
}

/// Render, onto a wheel, a bigger sequential set of objects inside this viewport.
///
/// Takes a scrollable set of fixed sized [RenderBox]es and renders them
/// sequentially from top down on a vertical scrolling axis.
///
/// It starts with the first scrollable item in the center of the main axis
/// and ends with the last scrollable item in the center of the main axis. This
/// is in contrast to typical lists that start with the first scrollable item
/// at the start of the main axis and ends with the last scrollable item at the
/// end of the main axis.
///
/// Instead of rendering its children on a flat plane, it renders them
/// as if each child is broken into its own plane and that plane is
/// perpendicularly fixed onto a cylinder which rotates along the scrolling
/// axis.
///
/// This class works in 3 coordinate systems:
///
/// 1. The **scrollable layout coordinates**. This coordinate system is used to
///    communicate with [ViewportOffset] and describes its children's abstract
///    offset from the beginning of the scrollable list at (0.0, 0.0).
///
///    The list is scrollable from the start of the first child item to the
///    start of the last child item.
///
///    Children's layout coordinates don't change as the viewport scrolls.
///
/// 2. The **untransformed plane's viewport painting coordinates**. Children are
///    not painted in this coordinate system. It's an abstract intermediary used
///    before transforming into the next cylindrical coordinate system.
///
///    This system is the **scrollable layout coordinates** translated by the
///    scroll offset such that (0.0, 0.0) is the top left corner of the
///    viewport.
///
///    Because the viewport is centered at the scrollable list's scroll offset
///    instead of starting at the scroll offset, there are paintable children
///    ~1/2 viewport length before and after the scroll offset instead of ~1
///    viewport length after the scroll offset.
///
///    Children's visibility inclusion in the viewport is determined in this
///    system regardless of the cylinder's properties such as [diameterRatio]
///    or [perspective]. In other words, a 100px long viewport will always
///    paint 10-11 visible 10px children if there are enough children in the
///    viewport.
///
/// 3. The **transformed cylindrical space viewport painting coordinates**.
///    Children from system 2 get their positions transformed into a cylindrical
///    projection matrix instead of its cartesian offset with respect to the
///    scroll offset.
///
///    Children in this coordinate system are painted.
///
///    The wheel's size and the maximum and minimum visible angles are both
///    controlled by [diameterRatio]. Children visible in the **untransformed
///    plane's viewport painting coordinates**'s viewport will be radially
///    evenly laid out between the maximum and minimum angles determined by
///    intersecting the viewport's main axis length with a cylinder whose
///    diameter is [diameterRatio] times longer, as long as those angles are
///    between -pi/2 and pi/2.
///
///    For example, if [diameterRatio] is 2.0 and this [RenderCircleListViewport]
///    is 100.0px in the main axis, then the diameter is 200.0. And children
///    will be evenly laid out between that cylinder's -arcsin(1/2) and
///    arcsin(1/2) angles.
///
///    The cylinder's 0 degree side is always centered in the
///    [RenderCircleListViewport]. The transformation from **untransformed
///    plane's viewport painting coordinates** is also done such that the child
///    in the center of that plane will be mostly untransformed with children
///    above and below it being transformed more as the angle increases.
class RenderCircleListViewport extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, CircleListParentData>
    implements RenderAbstractViewport {
  /// Creates a [RenderCircleListViewport] which renders children on a wheel.
  ///
  /// All arguments must not be null. Optional arguments have reasonable defaults.
  RenderCircleListViewport({
    required this.childManager,
    required ViewportOffset offset,
    required double itemExtent,
    required Axis axis,
    double radius = 100,
    bool clipToSize = true,
    bool renderChildrenOutsideViewport = false,
    List<RenderBox>? children,
  })  : assert(itemExtent > 0),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        _axis = axis,
        _radius = radius,
        _offset = offset,
        _itemExtent = itemExtent,
        _clipToSize = clipToSize,
        _renderChildrenOutsideViewport = renderChildrenOutsideViewport {
    addAll(children);
  }

  /// An error message to show when [clipToSize] and [renderChildrenOutsideViewport]
  /// are set to conflicting values.
  static const String clipToSizeAndRenderChildrenOutsideViewportConflict =
      'Cannot renderChildrenOutsideViewport and clipToSize since children '
      'rendered outside will be clipped anyway.';

  /// The delegate that manages the children of this object.
  final CircleListChildManager childManager;

  /// The associated ViewportOffset object for the viewport describing the part
  /// of the content inside that's visible.
  ///
  /// The [ViewportOffset.pixels] value determines the scroll offset that the
  /// viewport uses to select which part of its content to display. As the user
  /// scrolls the viewport, this value changes, which changes the content that
  /// is displayed.
  ///
  /// Must not be null.
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    if (value == _offset) return;
    if (attached) _offset.removeListener(_hasScrolled);
    _offset = value;
    if (attached) _offset.addListener(_hasScrolled);
    markNeedsLayout();
  }

  /// {@template flutter.rendering.wheelList.itemExtent}
  /// The size of the children along the main axis. Children [RenderBox]es will
  /// be given the [BoxConstraints] of this exact size.
  ///
  /// Must not be null and must be positive.
  /// {@endtemplate}
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    assert(value > 0);
    if (value == _itemExtent) return;
    _itemExtent = value;
    markNeedsLayout();
  }

  /// {@template flutter.rendering.wheelList.clipToSize}
  /// Whether to clip painted children to the inside of this viewport.
  ///
  /// Defaults to [true]. Must not be null.
  ///
  /// If this is false and [renderChildrenOutsideViewport] is false, the
  /// first and last children may be painted partly outside of this scroll view.
  /// {@endtemplate}
  bool get clipToSize => _clipToSize;
  bool _clipToSize;
  set clipToSize(bool value) {
    assert(
      !renderChildrenOutsideViewport || !clipToSize,
      clipToSizeAndRenderChildrenOutsideViewportConflict,
    );
    if (value == _clipToSize) return;
    _clipToSize = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// {@template flutter.rendering.wheelList.renderChildrenOutsideViewport}
  /// Whether to paint children inside the viewport only.
  ///
  /// If false, every child will be painted. However the [Scrollable] is still
  /// the size of the viewport and detects gestures inside only.
  ///
  /// Defaults to [false]. Must not be null. Cannot be true if [clipToSize]
  /// is also true since children outside the viewport will be clipped, and
  /// therefore cannot render children outside the viewport.
  /// {@endtemplate}
  bool get renderChildrenOutsideViewport => _renderChildrenOutsideViewport;
  bool _renderChildrenOutsideViewport;
  set renderChildrenOutsideViewport(bool value) {
    assert(
      !renderChildrenOutsideViewport || !clipToSize,
      clipToSizeAndRenderChildrenOutsideViewportConflict,
    );
    if (value == _renderChildrenOutsideViewport) return;
    _renderChildrenOutsideViewport = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  Axis get axis => _axis;
  Axis _axis;
  set axis(Axis value) {
    if (value == _axis) return;
    _axis = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  double get radius => _radius;
  double _radius;
  set radius(double value) {
    assert(value > 0);
    if (value == _radius) return;
    _radius = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  void _hasScrolled() {
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! CircleListParentData)
      child.parentData = CircleListParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_hasScrolled);
  }

  @override
  void detach() {
    _offset.removeListener(_hasScrolled);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  /// Main axis length in the untransformed plane.
  double get _viewportExtent {
    assert(hasSize);
    return axis == Axis.horizontal ? size.width : size.height;
  }

  double get _mainAxisSize {
    return _viewportExtent;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the first item in the center.
  double get _minEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null) return double.negativeInfinity;
    return 0.0;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the last item in the center.
  double get _maxEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null) return double.infinity;

    return math.max(0.0, (childManager.childCount! - 1) * _itemExtent);
  }

  /// Scroll extent distance in the untransformed plane between the center
  /// position in the viewport and the top position in the viewport.
  ///
  /// It's also the distance in the untransformed plane that children's painting
  /// is offset by with respect to those children's [BoxParentData.offset].
  ///
  double get _scrollMarginExtent {
    assert(hasSize);
    // Consider adding alignment options other than center.
    return -_mainAxisSize / 2.0 + _itemExtent / 2.0;
  }

  /// Transforms a **scrollable layout coordinates**' y position to the
  /// **untransformed plane's viewport painting coordinates**' y position given
  /// the current scroll offset.
  double _getUntransformedPaintingCoordinate(double layoutCoordinate) {
    return layoutCoordinate - _scrollMarginExtent - offset.pixels;
  }

  double _getIntrinsicCrossAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      child = childAfter(child);
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (axis == Axis.horizontal) {
      if (childManager.childCount == null) {
        return 0.0;
      }
      return childManager.childCount! * _itemExtent;
    }

    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (axis == Axis.horizontal) {
      if (childManager.childCount == null) {
        return 0.0;
      }
      return childManager.childCount! * _itemExtent;
    }

    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (axis == Axis.vertical) {
      if (childManager.childCount == null) {
        return 0.0;
      }
      return childManager.childCount! * _itemExtent;
    }

    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (axis == Axis.vertical) {
      if (childManager.childCount == null) {
        return 0.0;
      }
      return childManager.childCount! * _itemExtent;
    }

    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  /// Gets the index of a child by looking at its parentData.
  int? indexOf(RenderBox child) {
    final CircleListParentData childParentData =
        child.parentData as CircleListParentData;
    assert(childParentData.index != null);
    return childParentData.index;
  }

  /// Returns the index of the child at the given offset.
  int scrollOffsetToIndex(double scrollOffset) =>
      (scrollOffset / itemExtent).floor();

  /// Returns the scroll offset of the child with the given index.
  double indexToScrollOffset(int index) => index * itemExtent;

  void _createChild(int index, {RenderBox? after}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.createChild(index, after: after);
    });
  }

  void _destroyChild(RenderBox? child) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.removeChild(child);
    });
  }

  void _layoutChild(RenderBox child, BoxConstraints constraints, int index) {
    child.layout(constraints, parentUsesSize: true);
    final CircleListParentData? childParentData =
        child.parentData as CircleListParentData?;
    // Centers the child horizontally.

    if (axis == Axis.horizontal) {
      final double crossPosition = size.height / 2.0 - child.size.height / 2.0;
      childParentData!.offset =
          Offset(indexToScrollOffset(index), crossPosition);
    } else {
      final double crossPosition = size.width / 2.0 - child.size.width / 2.0;
      childParentData!.offset =
          Offset(crossPosition, indexToScrollOffset(index));
    }
  }

  /// Performs layout based on how [childManager] provides children.
  ///
  /// From the current scroll offset, the minimum index and maximum index that
  /// is visible in the viewport can be calculated. The index range of the
  /// currently active children can also be acquired by looking directly at
  /// the current child list. This function has to modify the current index
  /// range to match the target index range by removing children that are no
  /// longer visible and creating those that are visible but not yet provided
  /// by [childManager].
  @override
  void performLayout() {
    final BoxConstraints childConstraints = constraints.copyWith(
      minHeight: _itemExtent,
      maxHeight: _itemExtent,
      minWidth: 0.0,
    );

    // The height, in pixel, that children will be visible and might be laid out
    // and painted.
    double visibleSize = _mainAxisSize;
    // If renderChildrenOutsideViewport is true, we spawn extra children by
    // doubling the visibility range, those that are in the backside of the
    // cylinder won't be painted anyway.
    if (renderChildrenOutsideViewport) visibleSize *= 2;

    final double firstVisibleOffset =
        offset.pixels + _itemExtent / 2 - visibleSize / 2;
    final double lastVisibleOffset = firstVisibleOffset + visibleSize;

    // The index range that we want to spawn children. We find indexes that
    // are in the interval [firstVisibleOffset, lastVisibleOffset).
    int targetFirstIndex = scrollOffsetToIndex(firstVisibleOffset);
    int targetLastIndex = scrollOffsetToIndex(lastVisibleOffset);
    // Because we exclude lastVisibleOffset, if there's a new child starting at
    // that offset, it is removed.
    if (targetLastIndex * _itemExtent == lastVisibleOffset) targetLastIndex--;

    // Validates the target index range.
    while (!childManager.childExistsAt(targetFirstIndex) &&
        targetFirstIndex <= targetLastIndex) targetFirstIndex++;
    while (!childManager.childExistsAt(targetLastIndex) &&
        targetFirstIndex <= targetLastIndex) targetLastIndex--;

    // If it turns out there's no children to layout, we remove old children and
    // return.
    if (targetFirstIndex > targetLastIndex) {
      while (firstChild != null) _destroyChild(firstChild);
      return;
    }

    // Now there are 2 cases:
    //  - The target index range and our current index range have intersection:
    //    We shorten and extend our current child list so that the two lists
    //    match. Most of the time we are in this case.
    //  - The target list and our current child list have no intersection:
    //    We first remove all children and then add one child from the target
    //    list => this case becomes the other case.

    // Case when there is no intersection.
    if (childCount > 0 &&
        (indexOf(firstChild!)! > targetLastIndex ||
            indexOf(lastChild!)! < targetFirstIndex)) {
      while (firstChild != null) _destroyChild(firstChild);
    }

    // If there is no child at this stage, we add the first one that is in
    // target range.
    if (childCount == 0) {
      _createChild(targetFirstIndex);
      _layoutChild(firstChild!, childConstraints, targetFirstIndex);
    }

    int currentFirstIndex = indexOf(firstChild!)!;
    int currentLastIndex = indexOf(lastChild!)!;

    // Remove all unnecessary children by shortening the current child list, in
    // both directions.
    while (currentFirstIndex < targetFirstIndex) {
      _destroyChild(firstChild);
      currentFirstIndex++;
    }
    while (currentLastIndex > targetLastIndex) {
      _destroyChild(lastChild);
      currentLastIndex--;
    }

    // Relayout all active children.
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    // Spawning new children that are actually visible but not in child list yet.
    while (currentFirstIndex > targetFirstIndex) {
      _createChild(currentFirstIndex - 1);
      _layoutChild(firstChild!, childConstraints, --currentFirstIndex);
    }
    while (currentLastIndex < targetLastIndex) {
      _createChild(currentLastIndex + 1, after: lastChild);
      _layoutChild(lastChild!, childConstraints, ++currentLastIndex);
    }

    offset.applyViewportDimension(_viewportExtent);

    // Applying content dimensions bases on how the childManager builds widgets:
    // if it is available to provide a child just out of target range, then
    // we don't know whether there's a limit yet, and set the dimension to the
    // estimated value. Otherwise, we set the dimension limited to our target
    // range.
    final double minScrollExtent =
        childManager.childExistsAt(targetFirstIndex - 1)
            ? _minEstimatedScrollExtent
            : indexToScrollOffset(targetFirstIndex);
    final double maxScrollExtent =
        childManager.childExistsAt(targetLastIndex + 1)
            ? _maxEstimatedScrollExtent
            : indexToScrollOffset(targetLastIndex);
    offset.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  bool _shouldClipAtCurrentOffset() {
    final double firsttUntransformedPaint =
        _getUntransformedPaintingCoordinate(0.0);
    return firsttUntransformedPaint < 0.0 ||
        _mainAxisSize <
            firsttUntransformedPaint + _maxEstimatedScrollExtent + _itemExtent;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (childCount > 0) {
      if (_clipToSize && _shouldClipAtCurrentOffset()) {
        context.pushClipRect(
          needsCompositing,
          offset,
          Offset.zero & size,
          _paintVisibleChildren,
        );
      } else {
        _paintVisibleChildren(context, offset);
      }
    }
  }

  /// Paints all children visible in the current viewport.
  void _paintVisibleChildren(PaintingContext context, Offset offset) {
    RenderBox? childToPaint = firstChild;
    CircleListParentData? childParentData =
        childToPaint?.parentData as CircleListParentData?;

    while (childParentData != null) {
      _paintTransformedChild(
          childToPaint, context, offset, childParentData.offset);
      if (childToPaint != null) childToPaint = childAfter(childToPaint);
      childParentData = childToPaint?.parentData as CircleListParentData?;
    }
  }

  /// Takes in a child with a **scrollable layout offset** and paints it in the
  /// **transformed cylindrical space viewport painting coordinates**.
  void _paintTransformedChild(
    RenderBox? child,
    PaintingContext context,
    Offset offset,
    Offset layoutOffset,
  ) {
    final Offset untransformedPaintingCoordinates = offset +
        Offset(
          axis == Axis.vertical
              ? layoutOffset.dx
              : _getUntransformedPaintingCoordinate(layoutOffset.dx),
          axis == Axis.horizontal
              ? layoutOffset.dy
              : _getUntransformedPaintingCoordinate(layoutOffset.dy),
        );

    final mainCordinate = axis == Axis.horizontal
        ? untransformedPaintingCoordinates.dx
        : untransformedPaintingCoordinates.dy;

    final fractional =
        ((_mainAxisSize / 2) - (mainCordinate + _itemExtent / 2.0)) /
            (_mainAxisSize / 2);

    double? angle;

    if (axis == Axis.horizontal) {
      angle = lerpDouble(-math.pi / 2, -math.pi, fractional);
    } else {
      angle = lerpDouble(0, -math.pi / 2, fractional);
    }

    final circleOffset =
        Offset(radius * math.cos(angle!), radius * math.sin(angle));

    final Matrix4 circleTransform = Matrix4.translationValues(
      axis == Axis.vertical ? circleOffset.dx - radius : circleOffset.dx,
      axis == Axis.horizontal ? circleOffset.dy : circleOffset.dy - radius,
      0,
    );

    // Offset that helps painting everything in the center (e.g. angle = 0).
    Offset offsetToCenter;

    if (axis == Axis.horizontal) {
      offsetToCenter = Offset(
        0,
        untransformedPaintingCoordinates.dy + radius,
      );
    } else {
      offsetToCenter = Offset(
        untransformedPaintingCoordinates.dx,
        radius - _scrollMarginExtent,
      );
    }

    _paintChild(context, offset, child, circleTransform, offsetToCenter);
  }

  // / Paint the child cylindrically at given offset.
  void _paintChild(
    PaintingContext context,
    Offset offset,
    RenderBox? child,
    Matrix4 circleTransform,
    Offset offsetToCenter,
  ) {
    context.pushTransform(
      // Text with TransformLayers and no cullRects currently have an issue rendering
      // https://github.com/flutter/flutter/issues/14224.
      false,
      offset,
      circleTransform,
      // Pre-transform painting function.
      (PaintingContext context, Offset offset) {
        context.paintChild(
          child!,
          // Paint everything in the center (e.g. angle = 0), then transform.
          offset + offsetToCenter,
        );
      },
    );
  }

  /// This returns the matrices relative to the **untransformed plane's viewport
  /// painting coordinates** system.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final CircleListParentData? parentData =
        child.parentData as CircleListParentData?;
    if (axis == Axis.vertical) {
      transform.translate(
          0.0, _getUntransformedPaintingCoordinate(parentData!.offset.dy));
    } else {
      transform.translate(
          _getUntransformedPaintingCoordinate(parentData!.offset.dx), 0.0);
    }
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    if (_shouldClipAtCurrentOffset()) {
      return Offset.zero & size;
    }
    return null;
  }

  @override
  bool hitTestChildren(HitTestResult result, {Offset? position}) {
    return false;
  }

  

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (descendant != null) {
      // Shows the descendant in the selected/center position.
      final RevealedOffset revealedOffset =
          getOffsetToReveal(descendant, 0.5, rect: rect);
      if (duration == Duration.zero) {
        offset.jumpTo(revealedOffset.offset);
      } else {
        offset.animateTo(revealedOffset.offset,
            duration: duration, curve: curve);
      }
      rect = revealedOffset.rect;
    }

    super.showOnScreen(
      rect: rect,
      duration: duration,
      curve: curve,
    );
  }
  
  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment, {Rect? rect, Axis? axis}) {
     rect ??= target.paintBounds;

    // `child` will be the last RenderObject before the viewport when walking up from `target`.
    RenderObject child = target;
    while (child.parent != this) child = child.parent as RenderObject;

    final CircleListParentData? parentData =
        child.parentData as CircleListParentData?;
    final double targetOffset = axis == Axis.horizontal
        ? parentData!.offset.dx
        : parentData!.offset.dy; // the so-called "centerPosition"

    final Matrix4 transform = target.getTransformTo(this);
    final Rect bounds = MatrixUtils.transformRect(transform, rect);
    final Rect targetRect = bounds.translate(
      axis == Axis.vertical ? 0.0 : (size.width - itemExtent) / 2,
      axis == Axis.horizontal ? 0.0 : (size.height - itemExtent) / 2,
    );

    return RevealedOffset(offset: targetOffset, rect: targetRect);
  }
}