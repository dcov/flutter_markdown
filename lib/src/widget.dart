// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:markdown/markdown.dart' as md;

import '_functions_io.dart' if (dart.library.html) '_functions_web.dart';
import 'builder.dart';
import 'style_sheet.dart';

/// Signature for callbacks used by [MarkdownWidget] when the user taps a link.
/// The callback will return the link text, destination, and title from the
/// Markdown link tag in the document.
///
/// Used by [MarkdownWidget.onTapLink].
typedef void MarkdownTapLinkCallback(String text, String? href, String title);

/// Signature for custom image widget.
///
/// Used by [MarkdownWidget.imageBuilder]
typedef Widget MarkdownImageBuilder(Uri uri, String? title, String? alt);

/// Signature for custom checkbox widget.
///
/// Used by [MarkdownWidget.checkboxBuilder]
typedef Widget MarkdownCheckboxBuilder(bool value);

/// Creates a format [TextSpan] given a string.
///
/// Used by [Markdown] to highlight the contents of `pre` elements.
abstract class SyntaxHighlighter {
  // ignore: one_member_abstracts
  /// Returns the formatted [TextSpan] for the given string.
  TextSpan format(String source);
}

abstract class MarkdownElementBuilder {
  /// Called when an Element has been reached, before its children have been
  /// visited.
  void visitElementBefore(md.Element element) {}

  /// Called when a text node has been reached.
  ///
  /// If [MarkdownWidget.styleSheet] has a style of this tag, will passing
  /// to [preferredStyle].
  ///
  /// If you needn't build a widget, return null.
  Widget? visitText(md.Text text, TextStyle? preferredStyle) => null;

  /// Called when an Element has been reached, after its children have been
  /// visited.
  ///
  /// If [MarkdownWidget.styleSheet] has a style of this tag, will passing
  /// to [preferredStyle].
  ///
  /// If you needn't build a widget, return null.
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) =>
      null;
}

/// Enum to specify which theme being used when creating [MarkdownStyleSheet]
///
/// [material] - create MarkdownStyleSheet based on MaterialTheme
/// [cupertino] - create MarkdownStyleSheet based on CupertinoTheme
/// [platform] - create MarkdownStyleSheet based on the Platform where the
/// is running on. Material on Android and Cupertino on iOS
enum MarkdownStyleSheetBaseTheme { material, cupertino, platform }

/// Enumeration of alignment strategies for the cross axis of list items.
enum MarkdownListItemCrossAxisAlignment {
  /// Uses [CrossAxisAlignment.baseline] for the row the bullet and the list
  /// item are placed in.
  ///
  /// This alignment will ensure that the bullet always lines up with
  /// the list text on the baseline.
  ///
  /// However, note that this alignment does not support intrinsic height
  /// measurements because [RenderFlex] does not support it for
  /// [CrossAxisAlignment.baseline].
  /// See https://github.com/flutter/flutter_markdown/issues/311 for cases,
  /// where this might be a problem for you.
  ///
  /// See also:
  /// * [start], which allows for intrinsic height measurements.
  baseline,

  /// Uses [CrossAxisAlignment.start] for the row the bullet and the list item
  /// are placed in.
  ///
  /// This alignment will ensure that intrinsic height measurements work.
  ///
  /// However, note that this alignment might not line up the bullet with the
  /// list text in the way you would expect in certain scenarios.
  /// See https://github.com/flutter/flutter_markdown/issues/169 for example
  /// cases that do not produce expected results.
  ///
  /// See also:
  /// * [baseline], which will position the bullet and list item on the
  ///   baseline.
  start,
}

/// A base class for widgets that parse and display Markdown.
///
/// Supports all standard Markdown from the original
/// [Markdown specification](https://github.github.com/gfm/).
///
/// See also:
///
///  * [Markdown], which is a scrolling container of Markdown.
///  * [MarkdownBody], which is a non-scrolling container of Markdown.
///  * <https://daringfireball.net/projects/markdown/>
///  * <https://github.github.com/gfm/>
class Markdown extends StatefulWidget {

  factory Markdown.parse({
    Key? key,
    required String data,
    bool selectable = false,
    MarkdownStyleSheet? styleSheet,
    MarkdownStyleSheetBaseTheme? styleSheetTheme,
    SyntaxHighlighter? syntaxHighlighter,
    MarkdownTapLinkCallback? onTapLink,
    VoidCallback? onTapText,
    String? imageDirectory,
    List<md.BlockSyntax>? blockSyntaxes,
    List<md.InlineSyntax>? inlineSyntaxes,
    md.ExtensionSet? extensionSet,
    MarkdownImageBuilder? imageBuilder,
    MarkdownCheckboxBuilder? checkboxBuilder,
    Map<String, MarkdownElementBuilder> builders = const {},
    bool fitContent = false,
    MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment =
        MarkdownListItemCrossAxisAlignment.baseline,
    bool scrollable = false,
    EdgeInsets scrollablePadding = const EdgeInsets.all(16.0)
  }) {
    final List<String> lines = data.replaceAll('\r\n', '\n').split('\n');
    final md.Document document = new md.Document(encodeHtml: false);
    return Markdown(
      key: key,
      nodes: document.parseLines(lines),
      styleSheet: styleSheet,
      syntaxHighlighter: syntaxHighlighter,
      onTapLink: onTapLink,
      imageDirectory: imageDirectory,
      scrollable: scrollable,
      scrollablePadding: scrollablePadding,
    );
  }

  /// Creates a widget that parses and displays Markdown.
  ///
  /// The [data] argument must not be null.
  const Markdown({
    Key? key,
    required this.nodes,
    this.scrollable = false,
    this.scrollablePadding = const EdgeInsets.all(16.0),
    this.selectable = false,
    this.styleSheet,
    this.styleSheetTheme = MarkdownStyleSheetBaseTheme.material,
    this.syntaxHighlighter,
    this.onTapLink,
    this.onTapText,
    this.imageDirectory,
    this.blockSyntaxes,
    this.inlineSyntaxes,
    this.extensionSet,
    this.imageBuilder,
    this.checkboxBuilder,
    this.builders = const {},
    this.fitContent = false,
    this.listItemCrossAxisAlignment =
        MarkdownListItemCrossAxisAlignment.baseline,
  }) : super(key: key);

  final List<md.Node> nodes;

  final bool scrollable;

  final EdgeInsets scrollablePadding;

  /// If true, the text is selectable.
  ///
  /// Defaults to false.
  final bool selectable;

  /// The styles to use when displaying the Markdown.
  ///
  /// If null, the styles are inferred from the current [Theme].
  final MarkdownStyleSheet? styleSheet;

  /// Setting to specify base theme for MarkdownStyleSheet
  ///
  /// Default to [MarkdownStyleSheetBaseTheme.material]
  final MarkdownStyleSheetBaseTheme? styleSheetTheme;

  /// The syntax highlighter used to color text in `pre` elements.
  ///
  /// If null, the [MarkdownStyleSheet.code] style is used for `pre` elements.
  final SyntaxHighlighter? syntaxHighlighter;

  /// Called when the user taps a link.
  final MarkdownTapLinkCallback? onTapLink;

  /// Default tap handler used when [selectable] is set to true
  final VoidCallback? onTapText;

  /// The base directory holding images referenced by Img tags with local or network file paths.
  final String? imageDirectory;

  /// Collection of custom block syntax types to be used parsing the Markdown data.
  final List<md.BlockSyntax>? blockSyntaxes;

  /// Collection of custom inline syntax types to be used parsing the Markdown data.
  final List<md.InlineSyntax>? inlineSyntaxes;

  /// Markdown syntax extension set
  ///
  /// Defaults to [md.ExtensionSet.gitHubFlavored]
  final md.ExtensionSet? extensionSet;

  /// Call when build an image widget.
  final MarkdownImageBuilder? imageBuilder;

  /// Call when build a checkbox widget.
  final MarkdownCheckboxBuilder? checkboxBuilder;

  /// Render certain tags, usually used with [extensionSet]
  ///
  /// For example, we will add support for `sub` tag:
  ///
  /// ```dart
  /// builders: {
  ///   'sub': SubscriptBuilder(),
  /// }
  /// ```
  ///
  /// The `SubscriptBuilder` is a subclass of [MarkdownElementBuilder].
  final Map<String, MarkdownElementBuilder> builders;

  /// Whether to allow the widget to fit the child content.
  final bool fitContent;

  /// Controls the cross axis alignment for the bullet and list item content
  /// in lists.
  ///
  /// Defaults to [MarkdownListItemCrossAxisAlignment.baseline], which
  /// does not allow for intrinsic height measurements.
  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;

  @override
  _MarkdownState createState() => _MarkdownState();
}

class _MarkdownState extends State<Markdown> implements MarkdownBuilderDelegate {
  late List<Widget> _children;
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  @override
  void didChangeDependencies() {
    _parseMarkdown();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Markdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nodes != oldWidget.nodes
        || widget.styleSheet != oldWidget.styleSheet) {
      _parseMarkdown();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parseMarkdown() {
    _disposeRecognizers();
    final MarkdownStyleSheet fallbackStyleSheet =
        kFallbackStyle(context, widget.styleSheetTheme);
    final MarkdownStyleSheet styleSheet =
        fallbackStyleSheet.merge(widget.styleSheet);
    final MarkdownBuilder builder = MarkdownBuilder(
      delegate: this,
      selectable: widget.selectable,
      styleSheet: styleSheet,
      imageDirectory: widget.imageDirectory,
      imageBuilder: widget.imageBuilder,
      checkboxBuilder: widget.checkboxBuilder,
      builders: widget.builders,
      fitContent: widget.fitContent,
      listItemCrossAxisAlignment: widget.listItemCrossAxisAlignment,
      onTapText: widget.onTapText,
    );
    _children = builder.build(widget.nodes);
  }

  void _disposeRecognizers() {
    if (_recognizers.isEmpty) return;
    final List<GestureRecognizer> localRecognizers =
        List<GestureRecognizer>.from(_recognizers);
    _recognizers.clear();
    for (GestureRecognizer recognizer in localRecognizers) recognizer.dispose();
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()
      ..onTap = () {
        if (widget.onTapLink != null) {
          widget.onTapLink!(text, href, title);
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    code = code.replaceAll(RegExp(r'\n$'), '');
    if (widget.syntaxHighlighter != null) {
      return widget.syntaxHighlighter!.format(code);
    }
    return TextSpan(style: styleSheet.code, text: code);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scrollable) {
      return ListView(
        padding: widget.scrollablePadding,
        children: _children,
      );
    }

    if (_children.length == 1)
      return _children.single;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _children,
    );
  }
}

/// Parse [task list items](https://github.github.com/gfm/#task-list-items-extension-).
class TaskListSyntax extends md.InlineSyntax {
  // FIXME: Waiting for dart-lang/markdown#269 to land
  static final String _pattern = r'^ *\[([ xX])\] +';

  TaskListSyntax() : super(_pattern);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    md.Element el = md.Element.withTag('input');
    el.attributes['type'] = 'checkbox';
    el.attributes['disabled'] = 'true';
    el.attributes['checked'] = '${match[1]!.trim().isNotEmpty}';
    parser.addNode(el);
    return true;
  }
}
