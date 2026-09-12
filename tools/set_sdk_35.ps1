# إن لم يكن API 35 مثبتاً أيضاً، غيّري الرقم إلى 34 في الأمرين أدناه.

$f = "C:\Users\halima\Documents\Daftari_flutter\daftari_UI\android\app\build.gradle.kts"
$c = Get-Content $f -Raw
$c = $c -replace 'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 35'
$c = $c -replace 'compileSdk\s*=\s*\d+', 'compileSdk = 35'
$c = $c -replace 'targetSdk\s*=\s*flutter\.targetSdkVersion', 'targetSdk = 35'
$c = $c -replace 'targetSdk\s*=\s*\d+', 'targetSdk = 35'
Set-Content $f $c -Encoding UTF8
Write-Host "Updated compileSdk/targetSdk to 35"
Select-String -Path $f -Pattern "compileSdk|targetSdk"
