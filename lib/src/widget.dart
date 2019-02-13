// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:meta/meta.dart';

import 'builder.dart';
import 'style_sheet.dart';

/// Signature for callbacks used by [Markdown] when the user taps a link.
///
/// Used by [Markdown.onTapLink].
typedef void MarkdownTapLinkCallback(String href);

/// Creates a format [TextSpan] given a string.
///
/// Used by [Markdown] to highlight the contents of `pre` elements.
abstract class SyntaxHighlighter { // ignore: one_member_abstracts
  /// Returns the formated [TextSpan] for the given string.
  TextSpan format(String source);
}

/// A base class for widgets that parse and display Markdown.
///
/// Supports all standard Markdown from the original
/// [Markdown specification](https://daringfireball.net/projects/markdown/).
///
/// See also:
///
///  * [Markdown], which is a scrolling container of Markdown.
///  * [MarkdownBody], which is a non-scrolling container of Markdown.
///  * <https://daringfireball.net/projects/markdown/>
class Markdown extends StatefulWidget {

  factory Markdown.parse({
    Key key,
    @required String data,
    MarkdownStyleSheet styleSheet,
    SyntaxHighlighter syntaxHighlighter,
    MarkdownTapLinkCallback onTapLink,
    Directory imageDirectory,
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
    Key key,
    @required this.nodes,
    this.styleSheet,
    this.syntaxHighlighter,
    this.onTapLink,
    this.imageDirectory,
    this.scrollable = false,
    this.scrollablePadding = const EdgeInsets.all(16.0)
  }) : assert(nodes != null),
       assert(scrollable != null),
       super(key: key);

  final List<md.Node> nodes;

  /// The styles to use when displaying the Markdown.
  ///
  /// If null, the styles are inferred from the current [Theme].
  final MarkdownStyleSheet styleSheet;

  /// The syntax highlighter used to color text in `pre` elements.
  ///
  /// If null, the [MarkdownStyleSheet.code] style is used for `pre` elements.
  final SyntaxHighlighter syntaxHighlighter;

  /// Called when the user taps a link.
  final MarkdownTapLinkCallback onTapLink;

  /// The base directory holding images referenced by Img tags with local file paths.
  final Directory imageDirectory;

  final bool scrollable;

  final EdgeInsets scrollablePadding;

  @override
  _MarkdownState createState() => new _MarkdownState();
}

class _MarkdownState extends State<Markdown> implements MarkdownBuilderDelegate {
  List<Widget> _children;
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
        || widget.styleSheet != oldWidget.styleSheet)
      _parseMarkdown();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parseMarkdown() {
    _disposeRecognizers();
    final MarkdownStyleSheet styleSheet = widget.styleSheet ?? new MarkdownStyleSheet.fromTheme(Theme.of(context));
    final MarkdownBuilder builder = new MarkdownBuilder(
      delegate: this,
      styleSheet: styleSheet,
      imageDirectory: widget.imageDirectory,
    );
    _children = builder.build(widget.nodes);
  }

  void _disposeRecognizers() {
    if (_recognizers.isEmpty)
      return;
    final List<GestureRecognizer> localRecognizers = new List<GestureRecognizer>.from(_recognizers);
    _recognizers.clear();
    for (GestureRecognizer recognizer in localRecognizers)
      recognizer.dispose();
  }

  @override
  GestureRecognizer createLink(String href) {
    final TapGestureRecognizer recognizer = new TapGestureRecognizer()
      ..onTap = () {
      if (widget.onTapLink != null)
        widget.onTapLink(href);
    };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    if (widget.syntaxHighlighter != null)
      return widget.syntaxHighlighter.format(code);
    return new TextSpan(style: styleSheet.code, text: code);
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