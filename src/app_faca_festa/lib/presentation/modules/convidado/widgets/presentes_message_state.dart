part of '../pages/area/presentes_section.dart';

class _PremiumMessageState extends StatelessWidget {
  final Color primary;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _PremiumMessageState({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 280.0;
        final tight = compact || height < 240;
        final extraTight = height < 180;
        final outerPad = extraTight ? 8.0 : (tight ? 12.0 : 24.0);
        final innerPad = extraTight ? 10.0 : (tight ? 14.0 : 22.0);
        final iconSize = extraTight ? 22.0 : (tight ? 28.0 : 38.0);
        final iconPad = extraTight ? 8.0 : (tight ? 12.0 : 16.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(outerPad),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(innerPad),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(extraTight ? 18 : 28),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.85)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: extraTight ? 12 : 24,
                        offset: Offset(0, extraTight ? 6 : 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconPad),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: primary, size: iconSize),
                      ),
                      SizedBox(height: extraTight ? 8 : 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: extraTight ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: extraTight ? 13 : (tight ? 14 : 16),
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: extraTight ? 4 : 7),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: extraTight ? 3 : 5,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: extraTight ? 11 : (tight ? 11.5 : 12.5),
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
