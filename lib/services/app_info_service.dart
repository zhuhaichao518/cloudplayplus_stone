//掉线连接管理.md
enum ControlState { normal, controlRequested, answerSent, conneted }
enum HostState { normal, offerSent, answerReceived, conneted }

//这个类负责管理当前运行的app的状态 见 如何管理用户登录状态.md
class AppStateService {
  static late Future<int> appInitState;
  // When conneted to ws server, get the ws session id.
  static String? websocketSessionid;
  static ControlState controlState = ControlState.normal;
  static HostState hostState = HostState.normal;
  //static bool visible = true;
  
  
}
