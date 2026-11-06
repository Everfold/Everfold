import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import 'app_scope.dart';

const appInk = Color(0xFF202824);
const appMuted = Color(0xFF6B756F);
const appAccent = Color(0xFF35634B);
const appCanvas = Color(0xFFF7F8F5);
const appLine = Color(0xFFE3E8E1);

bool usesCupertino(BuildContext context) =>
    AppScope.of(context).style == InterfaceStyle.cupertino;

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (usesCupertino(context)) {
      return c.CupertinoPageScaffold(
        navigationBar: c.CupertinoNavigationBar(
          middle: Text(title),
          leading: leading,
          trailing: trailing,
          backgroundColor: appCanvas,
          border: const Border(bottom: BorderSide(color: appLine)),
        ),
        child: SafeArea(child: child),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: leading,
        actions: [?trailing],
        backgroundColor: appCanvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(top: false, child: child),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (usesCupertino(context)) {
      return primary
          ? c.CupertinoButton.filled(
              onPressed: onPressed,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(label),
            )
          : c.CupertinoButton(
              onPressed: onPressed,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(label),
            );
    }
    return primary
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : TextButton(onPressed: onPressed, child: Text(label));
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (usesCupertino(context)) {
      return Semantics(
        label: label,
        button: true,
        child: c.CupertinoButton(
          padding: const EdgeInsets.all(10),
          onPressed: onPressed,
          child: Icon(icon, size: 21),
        ),
      );
    }
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
    );
  }
}

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    required this.placeholder,
    this.minLines = 1,
    this.maxLines = 1,
    this.secret = false,
    this.onChanged,
    this.focusNode,
  });
  final TextEditingController controller;
  final String placeholder;
  final int minLines;
  final int maxLines;
  final bool secret;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (usesCupertino(context)) {
      return c.CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        focusNode: focusNode,
        minLines: minLines,
        maxLines: maxLines,
        obscureText: secret,
        onChanged: onChanged,
        autocorrect: !secret,
        enableSuggestions: !secret,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: appLine),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        minLines: minLines,
        maxLines: maxLines,
        obscureText: secret,
        onChanged: onChanged,
        autocorrect: !secret,
        enableSuggestions: !secret,
        decoration: InputDecoration(
          hintText: placeholder,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: appLine),
          ),
        ),
      ),
    );
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    if (usesCupertino(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: appLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: body,
      );
    }
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: appLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: body,
    );
  }
}

class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.children, this.maxWidth = 680});
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.size = 28});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: appInk,
    ),
  );
}

class Caption extends StatelessWidget {
  const Caption(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, color: appMuted, height: 1.6),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.message, {super.key, this.action});
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AppSurface(
    color: const Color(0xFFF2F0E6),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: appInk, height: 1.6)),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: action!),
      ],
    ),
  );
}
