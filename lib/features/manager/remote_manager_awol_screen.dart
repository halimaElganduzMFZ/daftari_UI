import 'package:flutter/material.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/repositories/manager_repository.dart';
import 'remote_manager_widgets.dart';

class RemoteManagerAwolScreen extends StatefulWidget {
  const RemoteManagerAwolScreen({super.key, this.repository});
  final ManagerRepository? repository;
  @override
  State<RemoteManagerAwolScreen> createState() =>
      _RemoteManagerAwolScreenState();
}

class _RemoteManagerAwolScreenState extends State<RemoteManagerAwolScreen> {
  ManagerRepository get _repo => widget.repository ?? AppServices.manager;
  final _list = GlobalKey<ManagerPagedListState>();
  int? _count;
  Object? _countError;
  int _countSequence = 0;

  Future<void> _loadCount() async {
    final sequence = ++_countSequence;
    try {
      final count = await _repo.awolCount();
      if (mounted && sequence == _countSequence) {
        setState(() {
          _count = count;
          _countError = null;
        });
      }
    } catch (e) {
      if (mounted && sequence == _countSequence) {
        setState(() {
          _count = null;
          _countError = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('المنقطعون عن العمل')),
    body: ManagerPagedList(
      key: _list,
      load: (page) => _repo.page('/manager/awol', page: page),
      onRefresh: _loadCount,
      header: [
        if (_count != null)
          Text(
            'حالات الانقطاع الفعّالة: $_count',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        if (_countError != null)
          ManagerError(error: _countError!, retry: _loadCount),
        const SizedBox(height: 8),
        const Text(
          'تأكيد المسؤول لا ينهي الانقطاع؛ يبقى السجل ظاهرًا حتى تنهي الموارد البشرية الحالة.',
        ),
      ],
      itemBuilder: (item) {
        final employee = item['employee'] as Map;
        return AppSurface(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _AwolDetail(repository: _repo, id: item['id']),
              ),
            );
            if (mounted) await _list.currentState?.refresh();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                managerText(employee['name']),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              ManagerInfo('الرقم الوظيفي', employee['number']),
              ManagerInfo('أول يوم غياب', item['firstAbsentDate']),
              ManagerInfo('أيام الغياب', item['missedDays']),
              Text(
                item['confirmed'] == true || item['managerStatus'] == 3
                    ? 'انقطاع فعّال — تم تأكيد المسؤول'
                    : 'انقطاع فعّال — بانتظار تأكيد المسؤول',
                style: const TextStyle(color: AppColors.goldDeep),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _AwolDetail extends StatefulWidget {
  const _AwolDetail({required this.repository, required this.id});
  final ManagerRepository repository;
  final Object id;
  @override
  State<_AwolDetail> createState() => _AwolDetailState();
}

class _AwolDetailState extends State<_AwolDetail> {
  ManagerJson? _data;
  Object? _error;
  bool _loading = true;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });
    try {
      final data = await widget.repository.detail('/manager/awol', widget.id);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final note = await managerNoteDialog(
        context,
        title: 'تأكيد الانقطاع وإرسال الملاحظة',
        maxLength: 1500,
      );
      if (note == null || !mounted) return;
      final result = await widget.repository.confirmAwol(widget.id, note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'تم تسجيل تأكيد المسؤول',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(managerError(e))));
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final employee = data?['employee'] as Map?;
    final workplace = data?['workplace'] as Map?;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('تفاصيل الانقطاع')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: ManagerError(error: _error!, retry: _load),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ManagerInfo('الموظف', employee?['name']),
                        ManagerInfo('الرقم الوظيفي', employee?['number']),
                        ManagerInfo('الإدارة', workplace?['department']),
                        ManagerInfo('القسم', workplace?['section']),
                        ManagerInfo('الوحدة', workplace?['unit']),
                        ManagerInfo('أول يوم غياب', data!['firstAbsentDate']),
                        ManagerInfo(
                          'تاريخ الانقطاع الفعلي',
                          data['suspensionDate'],
                        ),
                        ManagerInfo('عدد أيام الغياب', data['missedDays']),
                        ManagerInfo(
                          'حالة المدير المسجلة',
                          data['managerStatus'],
                        ),
                        ManagerInfo('ملاحظة النظام', data['systemNotes']),
                        ManagerInfo('ملاحظة الموارد البشرية', data['hrNotes']),
                        ManagerInfo('ملاحظة المدير', data['managerNotes']),
                        ManagerInfo('تاريخ التأكيد', data['enteredAt']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data['confirmed'] != true && data['managerStatus'] != 3)
                    FilledButton(
                      onPressed: _saving ? null : _confirm,
                      child: const Text('تأكيد وإرسال'),
                    )
                  else
                    const Text(
                      'تم تأكيد المسؤول. يبقى الانقطاع فعّالًا حتى تنهيه الموارد البشرية.',
                    ),
                  if (_saving) const Center(child: CircularProgressIndicator()),
                ],
              ),
      ),
    );
  }
}
