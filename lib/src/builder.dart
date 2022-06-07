import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:getx_annotation/getx_annotation.dart';
import 'package:source_gen/source_gen.dart';

class GetxPageGenerator extends GeneratorForAnnotation<GetxPage> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final main = genGetxPageElement(element)!;
    return genMain(main);
  }

  String genMain(GetxPageElement main) {
    final mainBuffer = StringBuffer();
    final name = getDartMemberName(main.filedName);
    final paths = StringBuffer();
    final item = genChildrenBuffer(main, paths, '', root: true);
    mainBuffer.write('''
        class Routes {
          Routes._();
          static void init() {
            Get.addPage($name);
          }
          /// route == null 时, 可以使用 settings
          static PageRoute? Function(PageRoute? route, RouteSettings settings)?
            routeIntercept;

          static PageRoute? onGenerateRoute(RouteSettings settings) {
            final route = PageRedirect(settings: settings).page();
            if (routeIntercept != null) {
              return routeIntercept!(route, settings);
            }
            return route;
          }
          static final $name = $item;
        }
        class Paths {
          Paths._();
          $paths
        }
      ''');
    return mainBuffer.toString();
  }

  String genChildrenBuffer(
      GetxPageElement page, StringBuffer paths, String parentPath,
      {bool root = false}) {
    final name = getDartMemberName(page.filedName);

    final currentPage = page.page as ClassElement;
    var constructor = '';
    for (var item in currentPage.constructors) {
      if (item.name.isEmpty) {
        final pageClassName = currentPage.name;
        if (item.isConst) {
          constructor = 'const $pageClassName()';
        } else {
          constructor = '$pageClassName()';
        }
        break;
      }
    }
    var pageName = '';
    var currentPath = '';
    if (root) {
      pageName = '/';
      currentPath = '/';
    } else {
      pageName = '/$name';
      if (parentPath.endsWith('/')) {
        currentPath = '$parentPath$name';
      } else {
        currentPath = '$parentPath$pageName';
      }
    }

    paths.write('''
      static const $name = '$currentPath';
    ''');

    var children =
        page.children.map((e) => genChildrenBuffer(e, paths, currentPath));
    var childrenBuffer = '';
    if (children.isNotEmpty) {
      childrenBuffer = '''
      children: [
     ${children.join(',')},
     ],
    ''';
    }
    var bindings = '';
    if (page.bindings.isNotEmpty) {
      final bindinsString = page.bindings.map((e) => '${e.name}(),').toList();
      bindings = '''
      bindings: $bindinsString,
      ''';
    }
    return '''
    GetPage(
      name: '$pageName',
      page: () => $constructor,
      $childrenBuffer
      $bindings
    )
    ''';
  }

  GetxPageElement? genGetxPageElement(Element element) {
    for (var meta in element.metadata) {
      final metaValue = meta.computeConstantValue();
      if (metaValue != null &&
          metaValue.type?.getDisplayString(withNullability: false) ==
              'GetxPage') {
        return genChildren(metaValue, isRoot: true);
      }
    }
    return null;
  }

  GetxPageElement genChildren(DartObject value, {bool isRoot = false}) {
    final name = value.getField('name')!.toStringValue()!;
    final page = value.getField('page')!.toTypeValue()!.element!;
    final children =
        value.getField('children')!.toListValue()!.map(genChildren).toList();
    final bindings = value
        .getField('bindings')!
        .toListValue()!
        .map((e) => e.toTypeValue()!.element as ClassElement)
        .toList();

    return GetxPageElement(
      children: children,
      name: name,
      page: page,
      bindings: bindings,
      isRoot: isRoot,
    );
  }
}

class GetxPageElement {
  GetxPageElement({
    required this.children,
    required this.name,
    required this.page,
    required this.bindings,
    this.isRoot = false,
  });
  final String name;
  final Element page;
  ClassElement get classPage => page as ClassElement;
  final bool isRoot;
  String get filedName => name.isEmpty
      ? isRoot
          ? 'root'
          : classPage.name
      : name;
  final List<GetxPageElement> children;
  final List<ClassElement> bindings;
}

Builder getxPageBuilder(BuilderOptions options) =>
    SharedPartBuilder([GetxPageGenerator()], 'getx_gen');

String getToCamel(String name) {
  return name.replaceAllMapped(RegExp('[_-]([A-Za-z]+)'), (match) {
    final data = match[1]!;
    final first = data.substring(0, 1).toUpperCase();
    final second = data.substring(1);
    return '$first$second';
  });
}

String getDartClassName(String name) {
  final camel = getToCamel(name);
  if (camel.length <= 1) return camel.toUpperCase();
  final first = camel.substring(0, 1).toUpperCase();
  final others = camel.substring(1);
  return '$first$others';
}

String getDartMemberName(String name) {
  final camel = getToCamel(name);
  if (camel.length <= 1) return camel.toLowerCase();
  final first = camel.substring(0, 1).toLowerCase();
  final others = camel.substring(1);
  return '$first$others';
}
