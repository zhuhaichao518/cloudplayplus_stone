class DetailsTitleConfig {
  /// The spacing around the title content on the horizontal axis.
  final double? titleSpacing;

  /// Defines the height of the appbar when it is collapsed.
  final double? collapsedHeight;

  ///The size of the app bar when it is fully expanded.
  final double? expandedHeight;

  /// Whether the app should become visible as soon as the user scrolls towards the app bar.
  final bool floating;

  /// Whether the app bar should remain visible at the start of the scroll view.
  final bool pinned;

  final bool snap;

  /// Whether the app bar should stretch to fill the over-scroll area.
  final bool stretch;

  const DetailsTitleConfig({
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.stretch = false,
  });
}
