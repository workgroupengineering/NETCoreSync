library netcoresync_moor_generator;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/table_generator.dart';
import 'src/netcoresync_client_generator.dart';

Builder TableGeneratorBuilder(BuilderOptions builderOptions) => LibraryBuilder(
      TableGenerator(),
      generatedExtension: ".netcoresync_moor_table.part",
    );

Builder ClientGeneratorBuilder(BuilderOptions builderOptions) =>
    SharedPartBuilder(
      [NetCoreSyncClientGenerator()],
      "netcoresync_moor_client",
    );