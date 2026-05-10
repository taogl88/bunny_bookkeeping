/// 将 account_data 中的路径转为实际带 @3x 的文件名
/// 例: 'assets/images/e_catering.png' -> 'assets/images/e_catering@3x.png'
String iconPath(String raw) {
  return raw.replaceAll('.png', '@3x.png');
}
