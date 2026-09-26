import 'package:flutter/material.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/models/employee.dart';
import '../../data/repositories/manager_repository.dart';
import '../../data/repositories/permission_requests_repository.dart';
import '../../data/repositories/leave_requests_repository.dart';
import '../../data/session/app_session.dart';
import '../request/make_request_screen.dart';
import '../leave/make_leave_screen.dart';
import 'remote_manager_requests_screen.dart';
import 'remote_manager_widgets.dart';

class RemoteOnBehalfEmployeesScreen extends StatefulWidget {
  const RemoteOnBehalfEmployeesScreen({super.key, this.repository});
  final ManagerRepository? repository;
  @override
  State<RemoteOnBehalfEmployeesScreen> createState() =>
      _RemoteOnBehalfEmployeesScreenState();
}

class _RemoteOnBehalfEmployeesScreenState
    extends State<RemoteOnBehalfEmployeesScreen> {
  ManagerRepository get _repo => widget.repository ?? AppServices.manager;
  final _list = GlobalKey<ManagerPagedListState>();
  final _search = TextEditingController();
  String _query = '';
  bool _opening = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _find() {
    setState(() => _query = _search.text.trim());
    _list.currentState?.refresh();
  }

  Future<void> _open(ManagerJson item) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      // Resolve the actual allowed employee and acting structure on the server.
      final resolved = await _repo.detail(
        '/manager/on-behalf/employees',
        item['id'],
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              _OnBehalfWorkspace(repository: _repo, resolved: resolved),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(managerError(e))));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('نيابة عن موظف')),
    body: ManagerPagedList(
      key: _list,
      load: (page) => _repo.page(
        '/manager/on-behalf/employees',
        page: page,
        filters: {'q': _query, 'structure': AppSession.activeStructure?.id},
      ),
      header: [
        const Text(
          'اختر الموظف لتقديم إذن أو إجازة ومتابعة طلباته.',
          style: TextStyle(height: 1.6),
        ),
        TextField(
          controller: _search,
          maxLength: 100,
          onSubmitted: (_) => _find(),
          decoration: InputDecoration(
            labelText: 'الاسم أو الرقم الوظيفي',
            suffixIcon: IconButton(
              onPressed: _find,
              icon: const Icon(Icons.search),
            ),
          ),
        ),
        if (_opening) const LinearProgressIndicator(),
      ],
      itemBuilder: (item) => AppSurface(
        onTap: _opening ? null : () => _open(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              managerText(item['name']),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            ManagerInfo('الرقم الوظيفي', item['number']),
            ManagerInfo('الهيكل', (item['workplace'] as Map?)?['name']),
          ],
        ),
      ),
    ),
  );
}

/// A scoped workspace, not an identity swap. Personal dashboard/assets/profile
/// endpoints are deliberately absent because the API has no on-behalf equivalents.
class _OnBehalfWorkspace extends StatefulWidget {
  const _OnBehalfWorkspace({required this.repository, required this.resolved});
  final ManagerRepository repository;
  final ManagerJson resolved;
  @override
  State<_OnBehalfWorkspace> createState() => _OnBehalfWorkspaceState();
}

class _OnBehalfWorkspaceState extends State<_OnBehalfWorkspace> {
  int _revision = 0;
  Map get _employee => widget.resolved['employee'] as Map;
  String get _base => '/manager/on-behalf/employees/${_employee['id']}';
  Employee get _displayEmployee => Employee(
    id: '${_employee['id']}',
    employeeNumber: managerText(_employee['number']),
    fullName: managerText(_employee['name']),
    department: managerText((_employee['workplace'] as Map?)?['name']),
    jobTitle: '—',
    phone: '—',
    email: '—',
    hireDate: DateTime(1970),
    status: EmploymentStatus.active,
  );
  Future<void> _newRequest(bool leave) async {
    final client = widget.repository.client;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => leave
            ? MakeLeaveScreen(
                employee: _displayEmployee,
                repository: ApiLeaveRequestsRepository(
                  client,
                  basePath: '$_base/leave/requests',
                ),
                onSubmitted: () => Navigator.of(routeContext).pop(),
              )
            : MakeRequestScreen(
                employee: _displayEmployee,
                repository: ApiPermissionRequestsRepository(
                  client,
                  basePath: '$_base/requests',
                ),
              ),
      ),
    );
    if (mounted) setState(() => _revision++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text('نيابة عن ${managerText(_employee['name'])}')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: AppSurface(
            child: Column(
              children: [
                Text(
                  'تُسجّل الطلبات باسم الموظف، ويُسجّل حسابك كمدخل للطلب.',
                  style: const TextStyle(height: 1.6),
                ),
                if (widget.resolved['structure'] is Map)
                  ManagerInfo(
                    'الهيكل المعتمد لهذه النيابة',
                    (widget.resolved['structure'] as Map)['name'],
                  ),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _newRequest(false),
                      icon: const Icon(Icons.add),
                      label: const Text('طلب إذن'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _newRequest(true),
                      icon: const Icon(Icons.event),
                      label: const Text('طلب إجازة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RemoteManagerRequestsScreen(
            key: ValueKey(_revision),
            repository: widget.repository,
            employeeId: '${_employee['id']}',
            employeeName: managerText(_employee['name']),
          ),
        ),
      ],
    ),
  );
}
