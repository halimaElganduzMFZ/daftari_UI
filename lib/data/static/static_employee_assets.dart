import '../models/employee_asset.dart';

/// Demo assets for the signed-in employee (mirrors Employee_Assets.php rows).
const List<EmployeeAsset> kStaticEmployeeAssets = [
  EmployeeAsset(
    id: 'a1',
    serial: 1,
    financialNumber: 'FN-10482',
    name: 'جهاز حاسوب محمول — Dell Latitude 5540',
  ),
  EmployeeAsset(
    id: 'a2',
    serial: 2,
    financialNumber: 'FN-11091',
    name: 'شاشة عرض 27 بوصة — LG UltraFine',
  ),
  EmployeeAsset(
    id: 'a3',
    serial: 3,
    financialNumber: 'FN-12240',
    name: 'هاتف مكتبي IP — Cisco 8841',
  ),
  EmployeeAsset(
    id: 'a4',
    serial: 4,
    financialNumber: 'FN-13015',
    name: 'طابعة ليزر متعددة الوظائف — HP LaserJet Pro',
  ),
  EmployeeAsset(
    id: 'a5',
    serial: 5,
    financialNumber: 'FN-14102',
    name: 'كرسي مكتبي متحرك — Herman Miller',
  ),
];
