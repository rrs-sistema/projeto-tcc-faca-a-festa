import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';

class AdminBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const AdminBackAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 52 : 58);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      ),
      centerTitle: true,
      elevation: 0,
      flexibleSpace: Container(
          decoration:
              const BoxDecoration(gradient: AdminPalette.appBarGradient)),
      title: subtitle == null
          ? Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 15.5,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 15.5,
                  ),
                ),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
      actions: actions,
    );
  }
}

class AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 13.5, color: AdminPalette.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 18),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Limpar',
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: Colors.grey.shade400),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AdminPalette.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: AdminPalette.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AdminPalette.ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: AdminPalette.muted, height: 1.35),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(actionLabel!,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminPalette.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AdminStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory AdminStatusChip.success(String label, {IconData? icon}) =>
      AdminStatusChip(label: label, color: AdminPalette.success, icon: icon);

  factory AdminStatusChip.warning(String label, {IconData? icon}) =>
      AdminStatusChip(label: label, color: AdminPalette.warning, icon: icon);

  factory AdminStatusChip.danger(String label, {IconData? icon}) =>
      AdminStatusChip(label: label, color: AdminPalette.danger, icon: icon);

  factory AdminStatusChip.neutral(String label, {IconData? icon}) =>
      AdminStatusChip(label: label, color: AdminPalette.muted, icon: icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const AdminMetricChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AdminPalette.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AdminPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const AdminSummaryChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AdminPalette.ink,
                height: 1,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AdminPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration adminCardDecoration({bool highlighted = false}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: highlighted
          ? AdminPalette.primary.withValues(alpha: 0.32)
          : AdminPalette.border,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: highlighted ? 0.05 : 0.02),
        blurRadius: highlighted ? 10 : 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  const AdminCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 10, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: adminCardDecoration(),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class AdminLeadingMark extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AdminLeadingMark({
    super.key,
    required this.icon,
    this.color = AdminPalette.primary,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class AdminIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const AdminIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(icon, size: 18, color: color ?? AdminPalette.muted),
    );
  }
}

class AdminCompactSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminCompactSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.78,
      alignment: Alignment.centerRight,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class AdminMetaLine extends StatelessWidget {
  final List<String> parts;

  const AdminMetaLine({super.key, required this.parts});

  @override
  Widget build(BuildContext context) {
    final visiveis = parts.where((p) => p.trim().isNotEmpty).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    return Text(
      visiveis.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 11.5,
        color: AdminPalette.muted,
        height: 1.25,
      ),
    );
  }
}

class AdminCreateFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const AdminCreateFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: backgroundColor ?? AdminPalette.dark,
      foregroundColor: Colors.white,
      elevation: 2,
      extendedIconLabelSpacing: 8,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5),
      ),
      onPressed: onPressed,
    );
  }
}

InputDecoration adminInputDecoration({
  required String label,
  IconData? icon,
  String? hint,
  String? helperText,
  int? maxLines,
  bool obrigatorio = false,
}) {
  return InputDecoration(
    labelText: obrigatorio ? '$label *' : label,
    hintText: hint,
    helperText: helperText,
    helperMaxLines: 2,
    prefixIcon: icon == null ? null : Icon(icon, color: AdminPalette.primary),
    filled: true,
    fillColor: AdminPalette.surface,
    labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminPalette.muted),
    helperStyle: GoogleFonts.poppins(fontSize: 11, color: AdminPalette.muted),
    errorMaxLines: 2,
    errorStyle: GoogleFonts.poppins(fontSize: 11.5, height: 1.2),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AdminPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AdminPalette.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
  );
}

Future<bool> confirmarAcaoAdmin(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmar = 'Confirmar',
  Color cor = AdminPalette.danger,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(titulo,
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
      content:
          Text(mensagem, style: GoogleFonts.poppins(fontSize: 14, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar',
              style: GoogleFonts.poppins(color: AdminPalette.muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cor),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmar,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return ok == true;
}
