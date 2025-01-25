import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_two/bloc/camera/camera_cubit.dart';
import 'package:gallery_two/bloc/camera_message/camera_message_cubit.dart';
import 'package:gallery_two/core/camera.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CameraCubit(CameraMessageCubit()),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text("Camera TWO"),
          ),
          body: const Center(
            child: CameraScreen(),
          ),
        ),
      ),
    );
  }
}
