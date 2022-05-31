import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class GetxPageGenerator  extends GeneratorForAnnotation<> {

}

Builder routeMainBuilder(BuilderOptions options) =>
    SharedPartBuilder([GetxPageGenerator()], 'getx_page_gen');
