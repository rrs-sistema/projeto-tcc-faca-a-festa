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
  Size get preferredSize => Size.fromHeight(subtitle == null ? 56 : 64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
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
                fontSize: 16,
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
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 14, color: AdminPalette.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Limpar',
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey.shade400),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminPalette.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AdminPalette.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdminPalette.ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AdminPalette.muted, height: 1.4),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminPalette.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AdminPalette.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 108),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  GoogleFonts.poppins(fontSize: 11, color: AdminPalette.muted),
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
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: highlighted
          ? AdminPalette.primary.withValues(alpha: 0.35)
          : AdminPalette.border,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: highlighted ? 0.06 : 0.03),
        blurRadius: highlighted ? 14 : 8,
        offset: const Offset(0, 3),
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
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: adminCardDecoration(),
          padding: padding,
          child: child,
        ),
      ),
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
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminPalette.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
