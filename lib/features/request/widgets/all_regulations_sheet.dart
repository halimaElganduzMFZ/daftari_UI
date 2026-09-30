import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../data/models/regulations_center.dart';
import '../../../data/static/static_regulations_center.dart';

/// مركز اللوائح والمخالفات — من regulations-modal.php.
Future<void> showAllRegulationsSheet(
  BuildContext context, {
  String initialTabId = 'permissions',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.9,
            width: double.infinity,
            child: _AllRegulationsSheet(initialTabId: initialTabId),
          ),
        ),
      );
    },
  );
}

class _AllRegulationsSheet extends StatefulWidget {
  const _AllRegulationsSheet({required this.initialTabId});

  final String initialTabId;

  @override
  State<_AllRegulationsSheet> createState() => _AllRegulationsSheetState();
}

class _AllRegulationsSheetState extends State<_AllRegulationsSheet> {
  late String _tabId;
  int _penaltyIndex = 0;

  @override
  void initState() {
    super.initState();
    final exists = StaticRegulationsCenter.tabs.any(
      (tab) => tab.id == widget.initialTabId,
    );
    _tabId = exists ? widget.initialTabId : StaticRegulationsCenter.tabs.first.id;
  }

  RegulationTab get _current =>
      StaticRegulationsCenter.byId(_tabId) ?? StaticRegulationsCenter.tabs.first;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.9;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.bookOpen,
                  size: 18,
                  color: AppColors.goldDeep,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مركز اللوائح — الإجازات والأذونات والبصمات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: StaticRegulationsCenter.tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = StaticRegulationsCenter.tabs[index];
                final selected = tab.id == _tabId;
                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: FaIcon(
                    tab.icon,
                    size: 12,
                    color: selected ? AppColors.goldDeep : AppColors.slate,
                  ),
                  label: Text(tab.label),
                  selectedColor: AppColors.goldSoft,
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: selected ? AppColors.gold : AppColors.line,
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: selected ? AppColors.goldDeep : AppColors.charcoal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _tabId = tab.id;
                      _penaltyIndex = 0;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                for (final section in _current.sections) ...[
                  if (section.isPenaltyTable)
                    _PenaltySection(
                      section: section,
                      selectedIndex: _penaltyIndex,
                      onSelect: (index) {
                        setState(() => _penaltyIndex = index);
                      },
                    )
                  else
                    _TextSection(section: section),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('حسناً، فهمت'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.section});

  final RegulationSection section;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: AppColors.goldDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in section.items) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.article,
                      style: const TextStyle(
                        color: AppColors.goldDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        color: AppColors.charcoal,
                        height: 1.5,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PenaltySection extends StatelessWidget {
  const _PenaltySection({
    required this.section,
    required this.selectedIndex,
    required this.onSelect,
  });

  final RegulationSection section;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final categories = section.penaltyCategories;
    if (categories.isEmpty) return const SizedBox.shrink();
    final index = selectedIndex.clamp(0, categories.length - 1);
    final category = categories[index];

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: AppColors.goldDeep,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < categories.length; i++)
                ChoiceChip(
                  selected: i == index,
                  showCheckmark: false,
                  label: Text(categories[i].shortLabel),
                  selectedColor: AppColors.goldSoft,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: i == index ? AppColors.goldDeep : AppColors.slate,
                  ),
                  side: BorderSide(
                    color: i == index ? AppColors.gold : AppColors.line,
                  ),
                  onSelected: (_) => onSelect(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            category.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 640),
              child: Table(
                border: TableBorder.all(color: AppColors.line, width: 1),
                columnWidths: const {
                  0: FlexColumnWidth(2.4),
                  1: FlexColumnWidth(1.1),
                  2: FlexColumnWidth(1.1),
                  3: FlexColumnWidth(1.1),
                  4: FlexColumnWidth(1.1),
                  5: FlexColumnWidth(1.2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.goldSoft),
                    children: [
                      for (final header in category.headers)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            header,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (final row in category.rows) _buildPenaltyRow(row),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildPenaltyRow(PenaltyRow row) {
    final cells = <Widget>[
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          row.violation,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
      ),
    ];

    // نفرد الخلايا مع مراعاة colspan لملء 5 خانات العقوبات.
    var filled = 0;
    for (final cell in row.penalties) {
      final remaining = 5 - filled;
      final span = cell.colspan.clamp(1, remaining);
      cells.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            cell.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: span > 1 ? AppColors.goldDeep : AppColors.slate,
            ),
          ),
        ),
      );
      filled += 1;
      // للتبسيط البصري نكرر نفس النص في الخانات الممتدة بدل Table colspan المعقّد.
      for (var i = 1; i < span; i++) {
        cells.add(
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              '←',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.line, fontSize: 12),
            ),
          ),
        );
        filled += 1;
      }
      if (filled >= 5) break;
    }
    while (cells.length < 6) {
      cells.add(
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('—', textAlign: TextAlign.center),
        ),
      );
    }

    return TableRow(children: cells);
  }
}
