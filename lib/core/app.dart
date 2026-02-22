import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outtake/bloc/camera/camera_cubit.dart';
import 'package:outtake/bloc/camera_message/camera_message_cubit.dart';
import 'package:outtake/bloc/gallery/gallerycubit_cubit.dart';
import 'package:outtake/bloc/navigation/navigation_cubit.dart';
import 'package:outtake/bloc/selection/selection_cubit.dart';
import 'package:outtake/core/camera_screen.dart';
import 'package:outtake/core/gallery_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>(create: (context) => NavigationCubit()),
        BlocProvider<CameraCubit>(
            create: (context) => CameraCubit(CameraMessageCubit())),
        BlocProvider<GalleryCubit>(create: (context) => GalleryCubit()),
        BlocProvider<SelectionCubit>(create: (context) => SelectionCubit()),
      ],
      child: MaterialApp(
        home: BlocBuilder<NavigationCubit, NavigationState>(
          builder: (context, state) {
            return PageView(
              controller: PageController(initialPage: 1),
              children: [
                const GalleryScreen(),
                const CameraScreen(),
              ],
            );
          },
        ),
      ),
    );
  }
}
