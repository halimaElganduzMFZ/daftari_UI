import 'package:flutter/material.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../data/repositories/manager_repository.dart';
import '../../data/session/app_session.dart';
import 'remote_manager_widgets.dart';
import 'remote_manager_awol_screen.dart';
import 'remote_on_behalf_screen.dart';
import 'manager_statistics_screen.dart';

class RemoteManagerRequestsScreen extends StatefulWidget {
  const RemoteManagerRequestsScreen({
    super.key,
    this.history = false,
    this.review = false,
    this.employeeId,
    this.employeeName,
    this.repository,
  });
  final bool history;
  final bool review;
  final String? employeeId;
  final String? employeeName;
  final ManagerRepository? repository;
  @override
  State<RemoteManagerRequestsScreen> createState() =>
      _RemoteManagerRequestsScreenState();
}

class _RemoteManagerRequestsScreenState
    extends State<RemoteManagerRequestsScreen> {
  ManagerRepository get _repo => widget.repository ?? AppServices.manager;
  final _list = GlobalKey<ManagerPagedListState>();
  final _search = TextEditingController();
  List<ManagerJson> _types = [];
  Object? _typesError;
  late String _status;
  String _query = '';
  String? _type;
  DateTime? _date;
  ManagerJson? _counts;
  Object? _countsError;
  String? _searchError;
  int _countsGeneration = 0;
  int _awolGeneration = 0;
  int? _awolCount;
  Object? _awolError;
  bool get _onBehalf => widget.employeeId != null;
  String get _path => _onBehalf
      ? '/manager/on-behalf/employees/${widget.employeeId}/requests'
      : widget.review
      ? '/review/requests'
      : '/manager/requests';

  @override
  void initState() {
    super.initState();
    _status = widget.history || widget.review || _onBehalf ? 'all' : 'pending';
    _loadTypes();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _summary() async {
    await Future.wait([
      _requestSummary(),
      if (!widget.history &&
          !widget.review &&
          !_onBehalf &&
          AppSession.currentUser?.canManageAwol == true)
        _loadAwolCount(),
    ]);
  }

  Future<void> _loadAwolCount() async {
    final generation = ++_awolGeneration;
    try {
      final count = await _repo.awolCount();
      if (mounted && generation == _awolGeneration) {
        setState(() {
          _awolCount = count;
          _awolError = null;
        });
      }
    } catch (e) {
      if (mounted && generation == _awolGeneration) {
        setState(() {
          _awolCount = null;
          _awolError = e;
        });
      }
    }
  }

  Future<void> _requestSummary() async {
    if (widget.review) return;
    final generation = ++_countsGeneration;
    try {
      final counts = await _repo.counts(_path);
      if (mounted && generation == _countsGeneration) {
        setState(() {
          _counts = counts;
          _countsError = null;
        });
      }
    } catch (e) {
      if (mounted && generation == _countsGeneration) {
        setState(() {
          _counts = null;
          _countsError = e;
        });
      }
    }
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _repo.requestTypes();
      if (mounted) {
        setState(() {
          _types = types;
          _typesError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _typesError = e);
    }
  }

  void _applySearch() {
    final query = _search.text.trim();
    if (query.isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(query) &&
        query.length < 2) {
      setState(() => _searchError = 'اكتب حرفين على الأقل للبحث بالاسم');
      return;
    }
    setState(() {
      _query = query;
      _searchError = null;
    });
    _list.currentState?.refresh();
  }

  Map<String, String?> get _filters => {
    'status': _status,
    'type': _type,
    if (!_onBehalf && _query.isNotEmpty)
      RegExp(r'^\d+$').hasMatch(_query) ? 'employeeNumber' : 'q': _query,
    if (_date != null) ...{
      widget.review ? 'from' : 'date': _date!.toIso8601String().substring(
        0,
        10,
      ),
      if (widget.review) 'to': _date!.toIso8601String().substring(0, 10),
    },
  };

  Future<void> _open(ManagerJson item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManagerRequestDetailScreen(
          repository: _repo,
          path: _path,
          item: item,
          canDecide: !widget.review && !_onBehalf,
          loadDetail: !_onBehalf,
        ),
      ),
    );
    if (mounted) await _list.currentState?.refresh();
  }

  Future<void> _navigate(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _list.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ManagerPagedList(
      key: _list,
      load: (page) => _repo.page(_path, page: page, filters: _filters),
      onRefresh: _summary,
      header: [
        Text(
          _onBehalf
              ? 'طلبات ${widget.employeeName}'
              : widget.review
              ? 'مراجعة طلبات الموظفين'
              : widget.history
              ? 'سجل الطلبات'
              : 'موافقات المدراء',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.charcoal,
          ),
        ),
        if (!_onBehalf)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.review
                  ? 'طلبات جميع الموظفين — للعرض فقط'
                  : 'الطلبات ضمن جميع الهياكل المخوّلة لك',
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
        if (!widget.history && !widget.review && !_onBehalf)
          Wrap(
            spacing: 8,
            children: [
              if (AppSession.currentUser?.canManageAwol == true)
                OutlinedButton.icon(
                  onPressed: () =>
                      _navigate(RemoteManagerAwolScreen(repository: _repo)),
                  icon: const Icon(Icons.person_off_outlined),
                  label: Text(
                    _awolCount == null
                        ? 'المنقطعون'
                        : 'المنقطعون ($_awolCount)',
                  ),
                ),
              if (AppSession.canActOnBehalf ||
                  AppSession.currentUser?.isAdmin == true)
                OutlinedButton.icon(
                  onPressed: () =>
                      _navigate(const RemoteOnBehalfEmployeesScreen()),
                  icon: const Icon(Icons.switch_account),
                  label: const Text('نيابة عن موظف'),
                ),
              if (AppSession.currentUser?.isRequestReviewer == true ||
                  AppSession.currentUser?.isAdmin == true)
                OutlinedButton.icon(
                  onPressed: () => _navigate(
                    Scaffold(
                      appBar: AppBar(title: const Text('مراجعة الطلبات')),
                      body: const RemoteManagerRequestsScreen(review: true),
                    ),
                  ),
                  icon: const Icon(Icons.manage_search),
                  label: const Text('مراجعة كل الطلبات'),
                ),
            ],
          ),
        if (_awolError != null)
          ManagerError(error: _awolError!, retry: _loadAwolCount),
        if (!widget.history &&
            !widget.review &&
            !_onBehalf &&
            AppSession.currentUser?.isAssigner == true)
          ManagerStatisticsEntry(
            repository: _repo,
            requestTypes: _types,
          ),
        if (_counts != null)
          AppSurface(
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text('معلّق: ${_counts!['pending']}'),
                Text('معتمد: ${_counts!['approved']}'),
                Text('مرفوض: ${_counts!['rejected']}'),
              ],
            ),
          ),
        if (_countsError != null)
          ManagerError(error: _countsError!, retry: _summary),
        const SizedBox(height: 12),
        if (!_onBehalf)
          TextField(
            controller: _search,
            maxLength: 100,
            onSubmitted: (_) => _applySearch(),
            decoration: InputDecoration(
              labelText: 'اسم الموظف أو رقمه الوظيفي',
              errorText: _searchError,
              suffixIcon: IconButton(
                onPressed: _applySearch,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        if (_typesError != null)
          ManagerError(error: _typesError!, retry: _loadTypes),
        DropdownButtonFormField<String>(
          initialValue: '',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'نوع الطلب'),
          items: [
            const DropdownMenuItem(value: '', child: Text('كل الأنواع')),
            for (final entry in {
              for (final type in _types)
                '${type['filterValue'] ?? type['code']}': managerText(
                  type['label'],
                ),
            }.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) {
            setState(() => _type = value);
            _list.currentState?.refresh();
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in const {
              'all': 'الكل',
              'pending': 'معلّق',
              'approved': 'معتمد',
              'rejected': 'مرفوض',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _status == entry.key,
                onSelected: (_) {
                  setState(() => _status = entry.key);
                  _list.currentState?.refresh();
                },
              ),
            if (!_onBehalf)
              ActionChip(
                label: Text(
                  _date == null
                      ? 'تاريخ الطلب'
                      : _date!.toIso8601String().substring(0, 10),
                ),
                avatar: const Icon(Icons.calendar_month, size: 18),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date == null || !mounted) return;
                  setState(() => _date = date);
                  _list.currentState?.refresh();
                },
              ),
            if (_date != null)
              ActionChip(
                label: const Text('مسح التاريخ'),
                onPressed: () {
                  setState(() => _date = null);
                  _list.currentState?.refresh();
                },
              ),
          ],
        ),
        if (!widget.history && !widget.review && !_onBehalf)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'اسحب البطاقة لإظهار: تفاصيل · موافقة · رفض',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ),
      ],
      itemBuilder: (item) {
        final employee = item['employee'] as Map?;
        final card = AppSurface(
          onTap: () => _open(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                managerText(employee?['name'] ?? widget.employeeName),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (employee != null)
                Text(
                  managerText(employee['number']),
                  style: const TextStyle(color: AppColors.goldDeep),
                ),
              ManagerInfo('نوع الطلب', item['type']),
              ManagerInfo('الحالة', item['state'] ?? item['status']),
              ManagerInfo('من', item['fromDate']),
              if (item['toDate'] != null) ManagerInfo('إلى', item['toDate']),
              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.chevron_left),
              ),
            ],
          ),
        );
        if (widget.history ||
            widget.review ||
            _onBehalf ||
            (_status != 'pending' && item['status'] != 'pending')) {
          return card;
        }
        return ManagerSwipeActions(
          onDetails: () => _open(item),
          onApprove: () => _decideFromList(item, approve: true),
          onReject: () => _decideFromList(item, approve: false),
          child: card,
        );
      },
    ),
  );

  Future<void> _decideFromList(ManagerJson item, {required bool approve}) async {
    try {
      String? reason;
      if (!approve) {
        reason = await managerNoteDialog(
          context,
          title: 'سبب رفض الطلب',
          maxLength: 1000,
        );
        if (reason == null || !mounted) return;
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('الموافقة على الطلب'),
            content: const Text('هل تريد تسجيل الموافقة على هذا الطلب؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('موافقة'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      final result = await _repo.decide(item['id'], reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(managerText(result['message']))),
      );
      await _list.currentState?.refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(managerError(e))));
      await _list.currentState?.refresh();
    }
  }
}

class ManagerRequestDetailScreen extends StatefulWidget {
  const ManagerRequestDetailScreen({
    super.key,
    required this.repository,
    required this.path,
    required this.item,
    required this.canDecide,
    this.loadDetail = true,
  });
  final ManagerRepository repository;
  final String path;
  final ManagerJson item;
  final bool canDecide;
  final bool loadDetail;
  @override
  State<ManagerRequestDetailScreen> createState() =>
      _ManagerRequestDetailScreenState();
}

class _ManagerRequestDetailScreenState
    extends State<ManagerRequestDetailScreen> {
  ManagerJson? _data;
  Object? _error;
  bool _loading = true;
  bool _saving = false;
  bool _openingAttachment = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = widget.loadDetail
          ? await widget.repository.detail(widget.path, widget.item['id'])
          : widget.item;
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(bool approve) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      String? reason;
      if (!approve) {
        reason = await managerNoteDialog(
          context,
          title: 'سبب رفض الطلب',
          maxLength: 1000,
        );
        if (reason == null || !mounted) return;
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('الموافقة على الطلب'),
            content: const Text('هل تريد تسجيل الموافقة على هذا الطلب؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('موافقة'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      final result = await widget.repository.decide(
        widget.item['id'],
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(managerText(result['message']))));
      // A successful intermediate approval may still be pending. Read the new
      // decision options instead of pretending it has received final approval.
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

  Future<void> _attachment(Map attachment) async {
    if (_openingAttachment) return;
    setState(() => _openingAttachment = true);
    try {
      final file = await widget.repository.attachment(
        widget.path,
        widget.item['id'],
        managerText(attachment['fileName']),
      );
      if (mounted) await AttachmentViewer.show(context, attachment: file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(managerError(e))));
      }
    } finally {
      if (mounted) setState(() => _openingAttachment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final employee = data?['employee'] as Map?;
    final decision = data?['decision'] as Map?;
    final attachment = data?['attachment'] as Map?;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
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
                        if (employee != null) ...[
                          ManagerInfo('الموظف', employee['name']),
                          ManagerInfo('الرقم الوظيفي', employee['number']),
                        ],
                        ManagerInfo('نوع الطلب', data!['type']),
                        ManagerInfo('الحالة', data['state']),
                        ManagerInfo('من', data['fromDate']),
                        ManagerInfo('إلى', data['toDate']),
                        ManagerInfo('عدد الأيام', data['days']),
                        ManagerInfo('تاريخ التقديم', data['enteredAt']),
                        ManagerInfo('مدخل الطلب', data['enteredBy']),
                        if (data['reason'] != null)
                          ManagerInfo('السبب', data['reason']),
                        if (data['location'] != null)
                          ManagerInfo('مكان الإجازة', data['location']),
                        if (data['rejectReason'] != null)
                          ManagerInfo('سبب الرفض', data['rejectReason']),
                        for (final event in (data['history'] as List? ?? []))
                          ManagerInfo('الإجراء', event),
                        if (decision?['level'] is Map)
                          ManagerInfo(
                            'مستوى الاعتماد',
                            (decision!['level'] as Map)['label'],
                          ),
                      ],
                    ),
                  ),
                  if (attachment != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: OutlinedButton.icon(
                        onPressed:
                            attachment['downloadable'] == true &&
                                !_openingAttachment
                            ? () => _attachment(attachment)
                            : null,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _openingAttachment
                              ? 'جاري فتح المرفق…'
                              : attachment['downloadable'] == true
                              ? managerText(attachment['fileName'])
                              : 'المرفق القديم غير متاح للتنزيل',
                        ),
                      ),
                    ),
                  if (widget.canDecide && decision?['canDecide'] == true) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : () => _decide(true),
                      child: const Text('موافقة'),
                    ),
                    OutlinedButton(
                      onPressed: _saving ? null : () => _decide(false),
                      child: const Text('رفض مع ذكر السبب'),
                    ),
                  ] else if (widget.canDecide)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لا يتاح اتخاذ قرار على هذا الطلب حاليًا حسب حالته ومستوى صلاحيتك.',
                      ),
                    ),
                  if (_saving) const Center(child: CircularProgressIndicator()),
                ],
              ),
      ),
    );
  }
}
