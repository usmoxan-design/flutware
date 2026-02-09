import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../models/block_definitions.dart';

import 'block_painter.dart';

class VisualBlockWidget extends StatelessWidget {
  final ActionBlock action;
  final VoidCallback? onDelete;
  final String? targetPageName;
  final bool isHat;
  final Widget? innerContent;
  final Widget? elseContent;

  const VisualBlockWidget({
    super.key,
    required this.action,
    this.onDelete,
    this.targetPageName,
    this.isHat = false,
    this.innerContent,
    this.elseContent,
  });

  @override
  Widget build(BuildContext context) {
    Color blockColor = Colors.grey;
    String blockName = 'Noma\'lum';
    IconData blockIcon = Icons.help_outline;
    bool hasParams = false;

    final def = BlockRegistry.get(action.type);
    if (def != null) {
      blockColor = def.category.color;
      blockName = def.name;
      blockIcon = def.category.icon;
      hasParams = def.parameters.isNotEmpty;
    } else if (action.type == 'event') {
      blockColor = const Color(0xFFFFD300); // Scratch Yellow
      blockName = 'QACHONKI ${action.data['label']} BO\'LGANDA';
      blockIcon = Icons.play_arrow;
      hasParams = false;
    }

    final isControl = action.type == 'if' || action.type == 'if_else';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomPaint(
        painter: BlockShapePainter(
          color: blockColor,
          isHat: isHat,
          isMouth: isControl,
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: isControl ? 100 : 0),
          padding: EdgeInsets.fromLTRB(14, isHat ? 22 : 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(blockIcon, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blockName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            letterSpacing: 0.35,
                          ),
                        ),
                        if (hasParams) ...[
                          const SizedBox(height: 6),
                          _buildParamsPreview(def!),
                        ],
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              if (isControl) ...[
                const SizedBox(height: 10),
                _buildControlSlot(title: 'THEN', child: innerContent),
                if (action.type == 'if_else') ...[
                  const SizedBox(height: 10),
                  _buildControlSlot(title: 'ELSE', child: elseContent),
                ],
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlSlot({required String title, required Widget? child}) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 4),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child:
                child ??
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'BLOKNI SHU YERGA SUDRANG',
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamsPreview(BlockDefinition def) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: def.parameters.map((p) {
        String value = '';
        if (p.type == 'page') {
          value = targetPageName ?? 'SAHIFA TANLANG';
        } else {
          value =
              action.data[p.key]?.toString() ??
              p.defaultValue?.toString() ??
              '...';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 2),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 10, color: def.category.color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: def.category.color.withOpacity(0.85),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
