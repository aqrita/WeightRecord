/// 照片文件存取接口（页面/服务注入与测试用）。
///
/// 照片统一存放在应用文档目录的 photos/ 子目录中，数据库只存文件名。
abstract class PhotoStore {
  /// 删除照片目录中的指定文件；文件不存在时静默返回。
  Future<void> deletePhoto(String fileName);

  /// 返回照片的完整路径（用于显示）。
  Future<String> photoFullPath(String fileName);
}
