import '../l10n/tr.dart';
import 'bangla_number.dart';

/// "5 min ago" / "৫ মিনিট আগে" style labels for feeds and histories.
String relativeTime(DateTime time, AppLanguage lang, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  final bn = lang == AppLanguage.bn;
  String num(int v) => bn ? toBanglaDigits(v) : '$v';
  if (diff.inMinutes < 1) return bn ? 'এইমাত্র' : 'just now';
  if (diff.inHours < 1) return bn ? '${num(diff.inMinutes)} মিনিট আগে' : '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return bn ? '${num(diff.inHours)} ঘণ্টা আগে' : '${diff.inHours} h ago';
  if (diff.inDays < 7) return bn ? '${num(diff.inDays)} দিন আগে' : '${diff.inDays} d ago';
  return shortDate(time, lang);
}

const _monthsBn = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রি', 'মে', 'জুন', 'জুলা', 'আগ', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "23 Nov" / "২৩ নভে".
String shortDate(DateTime time, AppLanguage lang) => lang == AppLanguage.bn
    ? '${toBanglaDigits(time.day)} ${_monthsBn[time.month - 1]}'
    : '${time.day} ${_monthsEn[time.month - 1]}';

/// mm:ss timer label in the active script.
String clockLabel(Duration d, AppLanguage lang) {
  final m = d.inMinutes.remainder(600).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final out = '$m:$s';
  return lang == AppLanguage.bn ? toBanglaDigits(out) : out;
}
