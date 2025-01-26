import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_two/bloc/camera/camera_cubit.dart';
import 'package:gallery_two/bloc/camera_message/camera_message_cubit.dart';
import 'package:gallery_two/bloc/gallery/gallerycubit_cubit.dart';
import 'package:gallery_two/bloc/navigation/navigation_cubit.dart';
import 'package:gallery_two/bloc/selection/selection_cubit.dart';
import 'package:gallery_two/core/camera_screen.dart';
import 'package:gallery_two/core/gallery_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>(create: (context) => NavigationCubit()),
        BlocProvider<CameraCubit>(
            create: (context) => CameraCubit(CameraMessageCubit())),
      ],
      child: MaterialApp(
        home: BlocBuilder<NavigationCubit, NavigationState>(
          builder: (context, state) {
            return PageView(
              controller: PageController(initialPage: 1),
              children: [
                MultiBlocProvider(
                  providers: [
                    BlocProvider<GalleryCubit>(
                        create: (context) => GalleryCubit()),
                    BlocProvider<SelectionCubit>(
                        create: (context) => SelectionCubit()),
                  ],
                  child: const GalleryScreen(),
                ),
                const CameraScreen(),
              ],
            );
          },
        ),
      ),
    );
  }
}
