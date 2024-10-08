import 'package:cloudplayplus/controller/hardware_input_controller.dart';
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
          _cursorStyle = cursor;
        });
      },
      child: MouseRegion(
        cursor: _cursorStyle,
        hitTestBehavior: HitTestBehavior.translucent,
      ),
    );
  }
}
