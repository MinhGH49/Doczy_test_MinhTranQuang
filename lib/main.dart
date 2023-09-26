import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  //List các hình đã được tạo khi người dùng nhân 2 nút tròn/ chữ nhật
  List<Shape> shapes = List.empty(growable: true);


  @override
  Widget build(BuildContext context) {

    //custom paint vẽ tất cả các hình đã tạo mỗi khi chạy hàm paint
    final customPaint = ShapePainter(shapes);


    return Scaffold(
      //nếu để appbar thì chiều dọc của custom paint bị mất 79.xx pixel

      // appBar: AppBar(
      //   elevation: 5,
      //   clipBehavior: Clip.hardEdge,
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //
      //   title: Text(widget.title),
      // ),
      body:
        InteractiveViewer(
            clipBehavior: Clip.none,
          panEnabled: true,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(double.infinity),

          //khi để maxScale > 1 thì khi zoom in các đường lưới bị chạy
          minScale: 0.5,
          maxScale: 1,

          //khi để Clip.HardEdge thì lưới tọa độ bị cắt, không thẻ mở rộng được
          child: SizedBox.fromSize(
            size: Size.infinite,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                    child: ClipRect(
                      clipBehavior: Clip.none,
                      child: CustomPaint(

                          painter: customPaint,
                          child: Container(),
                      ),
                    ))
              ],
            ),
          )

    ),
      floatingActionButton: Row(
        //tạo 1 hàng 2 nút floating act button tại góc dưới bên phải
        mainAxisAlignment: MainAxisAlignment.end,

        children: [
          FloatingActionButton(
          onPressed: () {
            //tạo instance hình chữ nhật từ class RectModel kế thừa từ class Shape
            //thêm hình chữ nhật vào list các hình sẽ vẽ
            setState(() {
              shapes.add(RectModel(customPaint.currentCenter, customPaint.width/2, customPaint.height/2));
            });
          },
      tooltip: 'Rectangle',
      child: const Icon(Icons.rectangle),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10.0)),
          FloatingActionButton(
            onPressed: () {
              //tạo instance hình tròn từ class CircleModel kế thừa từ class Shape
              //thêm hình tròn vào list các hình sẽ vẽ
              setState(() {
                shapes.add(CircleModel(customPaint.currentCenter, customPaint.width/2));

              });
            },
            tooltip: 'Circle',
            child: const Icon(Icons.circle),
          )
        ],
      )
      , // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ShapePainter extends CustomPainter {
  var unitScale = 60.0; //chiều dài của 1 đơn vị
  var unitWidth = 10.0; //chiều rộng nẹt vẽ của các đường đơn vị

  //vị trí tương đối của tâm của màn hình hiện tại so với tâm tọa độ
  //khi di chuyển hệ trục thì tâm màn hình này sẽ được update
  //hàm callback khi nhấn thêm hình (chữ nhật/tròn) sẽ dùng giá trị này để
  //tạo Offset cho tâm của hình mới
  var currentCenter = Offset(0.0, 0.0);

  //chiều rộng/ dài của tọa độ được vẽ
  var width = 0.0;
  var height = 0.0;

  //constructor, nhận vào các hình sẽ được vẽ
  final List<Shape> shapes;
  ShapePainter(this.shapes);

  //hàm vẽ số đơn vị cho trục Ox
  void paintIndexX(Canvas canvas, double x, double scaleRate) {
    //số được đánh sau khi chia cho chiều dài đơn vị và chia cho tỉ lệ scale khi zoom
    final index = x/unitScale/scaleRate;
    final indexPainter = TextPainter(
        text: TextSpan(
            text:index.toStringAsFixed(1), //giới hạn chiều dài số được vẽ
            style: const TextStyle(color: Colors.black)
        ),
        textDirection: TextDirection.ltr
    );
    indexPainter.layout(minWidth: 0, maxWidth: 50);
    //số được vẽ tại tại tọa độ x tương ứng trên trục ox
    //dưới đường đơn vị 10 điểm
    Offset indexPos = Offset(x, 10);
    indexPainter.paint(canvas, indexPos);
  }

  //hàm vẽ số đơn vị cho trục Oy
  void paintIndexY(Canvas canvas, double y, double scaleRate) {
    //vẽ số đơn vị như trên trục Oy
    //số được vẽ tại tọa độ y tương ứng trên trục oy
    //nằm phên phải đường đơn vị 10 điểm
    final index = -y/unitScale/scaleRate;
    final indexPainter = TextPainter(
        text: TextSpan(
            text: index.toStringAsFixed(1),
            style: const TextStyle(color: Colors.black)
        ),
        textDirection: TextDirection.ltr
    );
    indexPainter.layout(minWidth: 0, maxWidth: 50);
    Offset indexPos = Offset(10, y);
    indexPainter.paint(canvas, indexPos);
  }

  @override
  void paint(Canvas canvas, Size size) {

    //lấy các giá trị transform của canvas
    //khi zoom, kéo thì canvas transform
    //hàm getTransform trả về 1 mảng số float
    var tf = canvas.getTransform();
    print("Minh get transform ${canvas.getTransform().toString()}");

    //tf1 = giá trị transform khi khéo canvas theo chiều ngang
    //tf1 = 0 khi canvas giữa tâm màn hình
    // (gốc của lưới tọa độ được vẽ trùng tâm màn hình hiện tại)
    //tf1 tăng khi khéo canvas qua phải và ngược lại
    //tf1 = chiều rộng màn / 2 khi tâm tọa độc ở cạnh end màn hình
    //tf1 = -(chiều rộng màn / 2) khi tâm tọa độ ở cạnh start màn hình
    var tf1 = tf[12];
    //tf2 = giá trị transform khi khéo canvas theo chiều dọc
    //tf2 = 0 khi canvas giữa tâm màn hình
    // (gốc của lưới tọa độ được vẽ trùng tâm màn hình hiện tại)
    //tf2 tăng khi khéo canvas qua duống dưới và ngược lại
    //tf2 = chiều dài màn / 2 khi tâm tọa độc ở cạnh bottom màn hình
    //tf1 = -(chiều dài màn / 2) khi tâm tọa độ ở cạnh top màn hình
    var tf2 = tf[13];

    //giá trị scale hiện tại của canvas
    //khi zoom in max thì tf0 = maxScale, zoom out max thì tf0 = minScale
    var tf0 = tf[0];

    //chuyển độ chiều dài/ rộng tọa độ theo scale khi zoom
    width = size.width /tf0;
    height = size.height /tf0;

    //cập nhật vị trí tâm màn hình so với gốc tọa độ
    currentCenter = Offset(-tf1/tf0, -tf2/tf0);

    //đưa gốc tọa độ về giữa màn hình
    canvas.translate(width/2, height/2);

    //cọ vẽ màu đỏ, nét rộng 5
    var paintRed = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    //cọ vẽ màu xanh, nét rộng 5
    var paintBlue = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    //cọ vẽ màu xám (vẽ lưới tọa độ), nét rộng 5
    var paintGrid = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;


    //vẽ gốc tạo độ
    canvas.drawCircle(Offset.zero, unitWidth, paintRed);

    //đếm số lượng điểm vẽ trên trục Ox
    //code này chỉ vẽ 1 lượng cố định lines ngay cả khi kéo đến vô tận của
    //lưới tọa độ,
    var counterNeg = 0;
    var counterPos = 0;

    //điểm bắt đầu để vẽ lines trên trục ox âm
    var startNegX = 0.0;
    //điểm kết thúc vẽ lines trên trục ox âm
    var endNegX = -width;
    //điểm bắt đầu để vẽ lines trên trục ox dương
    var startPosX = 0.0;
    //điểm kết thúc vẽ lines trên trục ox dương
    var endPosX = width;
    //khi kéo màn hình qua trái, gốc tạo độ càng cách xa tâm màn hình
    //tf1 đi về âm vô cùng

    if (tf1 < 0) {
      //khi đó giới hạn vẽ của lines trên trục ox dương sẽ bằng
      //khoảng cấch từ gốc tọa độ tới tâm màn hình hiện tại + một nữa chiều rộng
      //màn hình (để có thể vẽ được line trên hết chiều rộng màn)
      endPosX = tf1.abs() +width/2;
      //khi gốc tọa độ cách quá nửa chiều dài màn hình thì
      //chỉ cần vẽ lines trên ox dương
      // bắt dầu từ cạnh trái màn hình cho đến cạnh phải màn hình
      //không cần vẽ lines trên ox âm
      if (tf1 < -width/2) {
        startPosX = -tf1-width/2;
        endNegX = 0;
      }
     //khi kéo màn hình qua phải, gốc tạo độ càng cách xa tâm màn hình
      // tf1 đi về dương vô cùng
    } else if (tf1 > 0) {
      //khi đó giới hạn vẽ của lines trên trục ox âm sẽ bằng
    //khoảng cấch từ gốc tọa độ tới tâm màn hình hiện tại + một nữa chiều rộng
    //màn hình (để có thể vẽ được line trên hết chiều rộng màn)
      endNegX = -tf1 - width/2;
      //khi gốc tọa độ cách quá nửa chiều dài màn hình thì
      //chỉ cần vẽ lines trên ox âm
      // bắt dầu từ cạnh phải màn hình cho đến cạnh trái màn hình
      //không cần vẽ lines trên ox dương
      if (tf1 > width/2) {
        startNegX = -tf1 + width/2;
        endPosX = 0;
      }
    }
    //logic tương tự trên trục oy

    var startNegY = 0.0;
    var endNegY = -height;
    var startPosY = 0.0;
    var endPosY = height;
    if (tf2 < 0) {
      endPosY = tf2.abs() +height/2;
      if (tf2 < -height/2) {
        startPosY = -tf2-height/2;
        endNegY = 0;
      }
    } else if (tf2 > 0) {
      endNegY = -tf2 - height/2;
      if (tf2 > height/2) {
        startNegY = -tf2 + height/2;
        endPosY = 0;
      }
    }

    //khi zoom thì phải chia giới hạn cần vẽ lines với scale của canvas

    startNegX /= tf0;
    endNegX /= tf0;
    startPosX /=tf0;
    endPosX /= tf0;

    startNegY /= tf0;
    endNegY /= tf0;
    startPosY /= tf0;
    endPosY /= tf0;


    // print("Minh debug start neg = $startNegX");
    // print("Minh debug end neg = $endNegX");
    // print("Minh debug start pos = $startPosX");
    // print("Minh debug end pos = $endPosX");

    //vẽ lines trên trục ox âm (từ gốc tọa độ về cạnh trái màn)
    for(var i=startNegX;i>=endNegX;i-=unitScale) {

      //vẽ đường đơn vị
      Offset start = Offset(i, unitWidth);
      Offset end = Offset(i, -unitWidth);
      canvas.drawLine(start, end, paintRed);
      counterNeg++;

      //vẽ số đơn vị
      paintIndexX(canvas, i, tf0);

      //vẽ lưới dọc trên Ox âm
      Offset startGrid = Offset(i, endNegY);
      Offset endGrid = Offset(i, endPosY);
      canvas.drawLine(startGrid, endGrid, paintGrid);


    }

    //vẽ lines trên trục ox dương (từ gốc tọa độ về cạnh phải màn)
    for(var i=startPosX;i<=endPosX;i+=unitScale) {
      //vẽ đường đơn vị
      Offset start = Offset(i, unitWidth);
      Offset end = Offset(i, -unitWidth);
      canvas.drawLine(start, end, paintRed);


      counterPos++;
      //vẽ số đơn vị
      paintIndexX(canvas, i, tf0);

      //vẽ lưới dọc trên Ox dương
      Offset startGrid = Offset(i, endNegY);
      Offset endGrid = Offset(i, endPosY);
      canvas.drawLine(startGrid, endGrid, paintGrid);
    }

    //vẽ lines trên trục oy dương (từ gốc tọa độ về cạnh trên màn)
    //khi vẽ số thì lấy giá trị đối của tọa độ
    //vì tọa độ đi lên theo trục oy của flutter là âm (ngược với descartes)
    for(var i=startNegY;i>=endNegY;i-=unitScale) {
      //vẽ đường đơn vị
      Offset start = Offset(-unitWidth, i);
      Offset end = Offset(unitWidth, i);
      canvas.drawLine(start, end, paintBlue);

      //vẽ số đơn vị
      paintIndexY(canvas, i, tf0);

      //vẽ lưới dọc trên Ox dương
      Offset startGrid = Offset(endNegX, i);
      Offset endGrid = Offset(endPosX, i);
      canvas.drawLine(startGrid, endGrid, paintGrid);

    }
    //vẽ lines trên trục oy âm (từ gốc tọa độ về cạnh dưới màn)
    for(var i=startPosY;i<=endPosY;i+=unitScale) {
      Offset start = Offset(-unitWidth, i);
      Offset end = Offset(unitWidth, i);
      canvas.drawLine(start, end, paintBlue);

      paintIndexY(canvas, i, tf0);

      Offset startGrid = Offset(endNegX, i);
      Offset endGrid = Offset(endPosX, i);
      canvas.drawLine(startGrid, endGrid, paintGrid);
    }

    //khi kéo tới vô hạn của tạo độ, số lượng đường vẽ là 2*26+2*26
    //khi zoom out max
    print("Minh drawn neg points = $counterNeg");
    print("Minh drawn pos points = $counterPos");


    //lặp qua list các hình đã thêm, vẽ hình
    //hình nào thêm trước vẽ trước
    for(Shape shape in shapes) {
      var paint = Paint()
        ..color = Colors.primaries[shape.colorInt]
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;

      //nếu hình hiện tại là instance của CircleModel thì vẽ hình tròn
      //ngược lại thì hình chữ nhật
      if (shape is CircleModel) {
        canvas.drawCircle(shape.centre, shape.radius, paint);
      }
      if (shape is RectModel) {
        final Rect rectShape = Rect.fromCenter(center: shape.centre, width: shape.width, height: shape.height);
        canvas.drawRect(rectShape, paint);

      }

    }








  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return false;
  }

}

//class shape là cha của circleModel và rectModel
//cả 2 circle và rect đều có điểm chung là tọa độ tâm hình (offset)
//và màu ngẫu nhiên
//circle có thuộc tính riêng là bán kính
//rect có thuộc tính riêng là dài rộng
class Shape {
  final Offset centre;
  late final int colorInt;
  Shape(this.centre) {
    colorInt = Random().nextInt(Colors.primaries.length);
  }
}

class CircleModel extends Shape{

  late final double radius;

  final double maxRadius;
  CircleModel(super.centre, this.maxRadius) {
    radius = Random().nextDouble() * maxRadius/2;

  }
}


class RectModel extends Shape{

  late final double width;
  late final double height;

  final double maxWidth;
  final double maxHeight;
  RectModel(super.centre, this.maxWidth, this.maxHeight) {
    width = Random().nextDouble() * maxWidth/2;
    height = Random().nextDouble() * maxHeight/2;
  }
}




