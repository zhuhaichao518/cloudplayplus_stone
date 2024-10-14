import 'package:cloudplayplus/controller/hardware_input_controller.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/webrtc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MouseStyleBloc extends Cubit<MouseCursor> {
  MouseStyleBloc() : super(SystemMouseCursors.basic);

  void setCursor(MouseCursor cursor) => emit(cursor);
}

class MouseStyleRegion extends StatefulWidget {
  const MouseStyleRegion({Key? key}) : super(key: key);

  @override
  _MouseStyleRegionState createState() => _MouseStyleRegionState();
}

class _MouseStyleRegionState extends State<MouseStyleRegion> {
  MouseCursor _cursorStyle = SystemMouseCursors.basic;
  MouseCursor _cursorStyleOnLeave = SystemMouseCursors.basic;

  @override
  void dispose() {
    InputController.removeCursorContext(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputController.setCursorContext(context);
    return BlocListener<MouseStyleBloc, MouseCursor>(
      listener: (context, cursor) {
        setState(() {
          _cursorStyleOnLeave = cursor;
          _cursorStyle = cursor;
        });
      },
      child: MouseRegion(
        cursor: _cursorStyle,
        hitTestBehavior: HitTestBehavior.translucent,
        //macos上 全屏模式下当鼠标向上移出去再移回来会切回默认鼠标样式 这个也只能缓解
        onEnter: (event) {
          if (AppPlatform.isMacos) {
            setState(() {
              _cursorStyle = SystemMouseCursors.basic;
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                setState(() {
                  _cursorStyle = _cursorStyleOnLeave;
                });
              }
            });
          }
        },
        onExit: (event) {
          //修复快速移出无法移动到边角的问题。
          WebrtcService.currentRenderingSession!.inputController?.requestMoveMouseAbsl(0, 0, -1);
        },
      ),
    );
  }
}
