import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class TakeJobScreen extends StatefulWidget {
  const TakeJobScreen(this.cred, {super.key});

  final UserCredential cred;

  @override
  State<TakeJobScreen> createState() => _TakeJobScreen();
}

class _TakeJobScreen extends State<TakeJobScreen>{

  List<dynamic> jobs = [];
  bool jobsExist = false;
  FirebaseFirestore db = FirebaseFirestore.instance;
  String filter = "No filter applied";
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    checkJobSection();
    ScrollController scroll = ScrollController();
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Jobs"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
          controller: scroll,
          child: Column(
              children: [
                filterList(),
                applyFilterButton(context),
                jobView(context)
              ]
          )
      ),
    );
  }

  void getOnlyLTLLoads() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").where("isLTL", isEqualTo: true);
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  void getNoLTLLoads() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").where("isLTL", isEqualTo: false);
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  void getNoRefrig() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").where("isTempControlled", isEqualTo: true);
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  void getOnlyRefrig() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").where("isTempControlled", isEqualTo: false);
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  void getWeightAsc() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").orderBy("weight");
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  void getWeightDesc() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").orderBy("weight", descending: true);
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  void sortDateAsc() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").orderBy("epoch");
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  void sortDateDesc() async{
    if(jobsExist == true){
      final reference = db.collection("open-jobs").orderBy("epoch", descending: true);
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }

  Widget applyFilterButton(BuildContext context){
    return ElevatedButton(
        onPressed: () async{
          if(filter == "Only LTL Loads"){
            getOnlyLTLLoads();
          }else if(filter == "No LTL Loads"){
            getNoLTLLoads();
          }else if(filter == "Only Refrigerated Loads"){
            getOnlyRefrig();
          }else if(filter == "No Refrigerated Loads"){
            getNoRefrig();
          }else if(filter == "Sort by Ascending Cargo Weight"){
            getWeightAsc();
          }else if(filter == "Sort by Descending Cargo Weight"){
            getWeightDesc();
          }else if(filter == "Sort by Earliest Deadline"){
            sortDateAsc();
          }else if(filter == "Sort by Latest Deadline"){
            sortDateDesc();
          }
        },
        child: Text("Apply Filter")
    );
  }

  Widget filterList(){

    return ExpansionPanelList(
        expansionCallback: (index, status) {
          setState(() {
            expanded = !expanded;
          });
        },
        children: [
          ExpansionPanel(
              headerBuilder: (context, expanded) {
                return ListTile(
                  title: Text(filter),
                );
              },
              body: Column(
                  children: [
                    ElevatedButton(
                        onPressed: (){filter = "Only LTL Loads";},
                        child: Text("Only LTL Loads")
                    ),
                    ElevatedButton(
                        onPressed: (){
                          setState(() {
                            filter = "No LTL Loads";
                          });
                        },
                        child: Text("No LTL Loads")
                    ),
                    ElevatedButton(
                      child: Text("Only Refrigerated Loads"),
                      onPressed: (){
                        setState(() {
                          filter = "Only Refrigerated Loads";
                        });
                      },
                    ),
                    ElevatedButton(
                      child: Text("No Refrigerated Loads"),
                      onPressed: (){
                        setState(() {
                          filter = "No Refrigerated Loads";
                        });
                      },
                    ),
                    ElevatedButton(
                      child: Text("Sort by Ascending Cargo Weight"),
                      onPressed: (){
                        setState(() {
                          filter = "Sort by Ascending Cargo Weight";
                        });
                      },
                    ),
                    ElevatedButton(
                      child: Text("Sort by Descending Cargo Weight"),
                      onPressed: (){
                        setState(() {
                          filter = "Sort by Descending Cargo Weight";
                        });
                      },
                    ),
                    ElevatedButton(
                      child: Text("Sort by Earliest Deadline"),
                      onPressed: (){
                        setState(() {
                          filter = "Sort by Earliest Deadline";
                        });
                      },
                    ),
                    ElevatedButton(
                      child: Text("Sort by Latest Deadline"),
                      onPressed: (){
                        setState(() {
                          filter = "Sort by Latest Deadline";
                        });
                      },
                    ),
                  ]
              ),
              canTapOnHeader: true,
              isExpanded: expanded
          )
        ]
    );
  }




  Widget jobView(BuildContext context){
    if(jobs.isEmpty){
      return CircularProgressIndicator();
    }else{
      ScrollController scrollController = ScrollController();
      if(!jobsExist){
        return Text("No jobs are available at this time, please try again later");
      }else{
        return SizedBox(
            height: 700,
            child: Scrollbar(
                controller: scrollController,
                child: ListView.separated(
                  controller: scrollController,
                  itemBuilder: (BuildContext context, int index){
                    return jobObject(context, jobs[index]);
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider();
                  },
                  itemCount: jobs.length,
                )
            )
        );
      }
    }
  }

  Widget jobObject(BuildContext context, Map<String, dynamic> jobInfo){
    String ltlNotice = "";
    if(jobInfo["isLTL"]){
      ltlNotice = "LTL Load";
    }else{
      ltlNotice = "Full Load";
    }
    String tempNotice = "";
    if(jobInfo["isTempControlled"]){
      tempNotice = "Temperature Controls required";
    }else{
      tempNotice = "Temperature Controls not required";
    }
    return Column(
        children: [
          Text("Deadline: ${jobInfo["deadline"]}", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("Merchant Name: ${jobInfo["merchant"]}"),
          Container(
              constraints: BoxConstraints(maxHeight: 500, maxWidth: 500),
              child: mapDisplay(context, jobInfo["origin"], jobInfo["destin"], true)
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(ltlNotice),
              Text(", ${jobInfo["weight"]} lbs")
            ],
          ),
          Text(tempNotice),
          takeJobButton(jobInfo["id"], jobInfo),
        ]
    );

  }

  Widget mapDisplay(BuildContext context, Map<String, dynamic> origin, Map<String, dynamic> destination, bool isJobObject){
    MapController controller = MapController(
      initPosition: GeoPoint(
          latitude: (destination["y"]!),
          longitude: (destination["x"]!)
      ),
    );
    if(isJobObject){
      controller.listenerMapSingleTapping.addListener(() {
        if (controller.listenerMapSingleTapping.value != null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Map of Route"),
                  contentPadding: EdgeInsets.zero,
                  content: mapDisplay(context, origin, destination, false),
                  actions: [
                    TextButton(
                      child: Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ]
              );
            },
          );
        }
      });
    }
    StaticPositionGeoPoint originPoint = StaticPositionGeoPoint(
        "origin",
        MarkerIcon(icon: Icon(Icons.location_on)),
        [GeoPoint(latitude: origin["y"]!, longitude: origin["x"]!)]
    );

    StaticPositionGeoPoint destinPoint = StaticPositionGeoPoint(
        "destination",
        MarkerIcon(icon: Icon(Icons.flag_sharp, color: Colors.red)),
        [GeoPoint(latitude: destination["y"]!, longitude: destination["x"]!)]
    );
    return OSMFlutter(
      controller: controller,
      mapIsLoading: CircularProgressIndicator(),
      osmOption: OSMOption(
        isPicker: false,
        zoomOption: ZoomOption(
          initZoom: 10,
          minZoomLevel: 3,
          maxZoomLevel: 19,
          stepZoom: 1.0,
        ),
        staticPoints: [originPoint, destinPoint],
      ),
      onMapIsReady: (status) {
        if(status){
          controller.drawRoad(
              GeoPoint(latitude: origin["y"]!, longitude: origin["x"]!),
              GeoPoint(latitude: destination["y"]!, longitude: destination["x"]!),
              roadOption: RoadOption(roadColor: Colors.deepPurple)
          );
        }
      },
    );
  }

  void checkJobSection() async{
    if(jobsExist == true){
      return;
    }
    final reference = db.collection("open-jobs");
    final snapshot = await reference.get();
    if(snapshot.size != 0){
      setState(() {
        jobsExist = true;
      });
      getJobs();
    }
  }

  Widget takeJobButton(String id, Map<String, dynamic> jobInfo){
    return ElevatedButton(
        onPressed: () {
          db.collection("open-jobs").doc(id).delete();
          jobInfo["inProgress"] = "Accepted";
          jobInfo["driverId"] = widget.cred.user?.email;
          db.collection("users").doc(widget.cred.user?.email).collection("jobs").doc(id).set(jobInfo);
          db.collection("users").doc(jobInfo["merchantId"]).collection("jobs").doc(id).set(jobInfo);
          setState(() {
            jobsExist = false;
            checkJobSection();
            getJobs();
          });
        },
        child: Text("Take Job")
    );
  }

  void getJobs() async{
    if(jobsExist){
      final reference = db.collection("open-jobs");
      final snapshot = await reference.get();
      List jobsFound = [];
      for(var doc in snapshot.docs){
        var data = doc.data();
        data["id"] = doc.id;
        jobsFound.add(data);
      }
      setState(() {
        jobs = jobsFound;
      });
    }
  }


}