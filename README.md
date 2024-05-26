
## Features 
1-It contains special methods to create effect of scroling on circle.
2-you can control the movement of your list circle by scrollcontroller


## Getting started
just import package 'src/Rounded_List_View.dart'

## Usage

```class WheelExample extends StatefulWidget {
   WheelExample({super.key});

  @override
  State<WheelExample> createState() => _WheelExampleState();
}
class _WheelExampleState extends State<WheelExample>{
   List<String>numList=["1","10","20","30","40","50"];
  ScrollController scrollController=ScrollController() ;


  Widget _buildItem(int i) {
   
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Center(
          child: InkWell(
            onTap: () {
              print(i.toString());
            },
            
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wheel example'),
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 400,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Todo :
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: Radius.circular(100000),
                      topEnd: Radius.circular(100000),
                    ),
                    color: Colors.brown,
                  ),
                  width: 350,
                  height: 350,
                  child: Center(
                    child: Container(
                      width: 389,
                      height: 389,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFFFFF8C7)),
                      child: Center(
                        child: Container(
                          width: 264,
                          height: 264,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 216, 194, 169)),
                          child: Center(
                            child: Container(
                              width: 225,
                              height: 225,
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage("assets/mandela.png"))),
                        
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  
                  // height: 260,
                   width: 300,
                  child: CircleListScrollView(
                    controller: scrollController,
                    // physics: const CircleFixedExtentScrollPhysics(),
                    axis: Axis.horizontal,
                    itemExtent: 30,
                    radius: MediaQuery.of(context).size.width * 0.4,
                    onSelectedItemChanged: (int index) {
                   
                   setState(() {
                        print('Current index: ${numList[index]}');
                     
              
                   });
                    },
                    children: List.generate(numList.length, (index)=>InkWell(
                    onTap: () {
                      print(numList[index]);
                    },
                      child: InkWell(
                        onTap: () {
                          print("object");
                        },
                        child: Container(
                                           
                        //  color: Colors.red,
                          child: ClipRRect(
                             borderRadius: BorderRadius.circular(40),
                            child: Center(child: Text("${numList[index]}"))),
                        ),
                      ),
                    )),
                  ),
                ),
                Positioned(
                bottom: 145,
                  child: Center(
                                child: InkWell(
                                  onTap: () {
                                     scrollController.jumpTo(0);
                                     setState(() {
                                        // print('Current index: $ind');
                                     });
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:  Color(0xFFFFF8C7)),
                                  ),
                                ),
                              ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

