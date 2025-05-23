import 'dart:convert' as convert;

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:final_project/take_job.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:http/http.dart' as http;

import 'create_job.dart';

class HomePage extends StatefulWidget {
  const HomePage(this.cred, {super.key});

  final UserCredential cred;
  @override
  State<HomePage> createState() => _HomePage();

}

class _HomePage extends State<HomePage>{

  Map<String, dynamic> userData = {};
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool jobsExist = false;
  bool retrievedInfo = false;
  List userJobs = [];

  @override
  Widget build(BuildContext context) {
    getUserData();
    checkJobSection();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Home"),
      ),
      body:Column(
          children: [
            futureProfile(),
            Expanded(
                child: jobDetails(context)
            )
          ]
      ),
      bottomNavigationBar: navigationBar(context),
    );
  }

  Widget futureProfile(){
    return FutureBuilder(
        future: db.collection("users").doc(widget.cred.user!.email).get(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
            DocumentSnapshot shot = snapshot.data!;
            return profileSection(shot.data() as Map<String, dynamic>);
          }else{
            return CircularProgressIndicator();
          }
        }
    );
  }

  Widget profileSection(Map<String, dynamic>userData){
    TextEditingController name = TextEditingController();
    name.text = userData["name"];
    TextEditingController address = TextEditingController();
    if(userData["address"] != null){
      address.text = userData["address"];
    }
    TextEditingController phoneNumber = TextEditingController();
    if(userData["phone-number"] != null){
      phoneNumber.text = userData["phone-number"];
    }
    return Container(
        color: Colors.amber.shade50,
        child: Column(
          children: [
            Text(
                "User Profile",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold
                )
            ),
            TextField(
                controller: name,
                onSubmitted: (input) {
                  if(input != null){
                    setState(() {
                      name.text = input;
                    });
                  }
                },
                decoration: InputDecoration(
                    labelText: "   Name"
                )
            ),
            TextField(
                controller: address,
                onSubmitted: (input) {
                  if(input != null){
                    setState(() {
                      address.text = input;
                    });
                  }
                },
                decoration: InputDecoration(
                    labelText: "   Home Address"
                )
            ),
            TextField(
                controller: phoneNumber,
                onSubmitted: (input) {
                  if(input != null){
                    setState(() {
                      phoneNumber.text = input;
                    });
                  }
                },
                decoration: InputDecoration(
                    labelText: "   Phone Number"
                )
            ),
            ElevatedButton(
                onPressed: () async {
                  final id = widget.cred.user!.email;
                  final reference = db.collection("users").doc(id);
                  userData["name"] = name.text;
                  userData["address"] = address.text;
                  userData["phone-number"] = phoneNumber.text;
                  reference.update(userData);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Profile Updated!"))
                  );
                },
                child: Text("Update Profile")
            ),
          ],
        )
    );
  }

  void getUserData() {
    final id = widget.cred.user!.email;
    final reference = db.collection("users").doc(id);
    if(!retrievedInfo){
      reference.get().then( (DocumentSnapshot doc) {
        if(!doc.exists){

        }else{
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            userData = data;
          });
        }
      });
      retrievedInfo = true;
    }
  }

  void getJobs() async{
    if(jobsExist){
      final id = widget.cred.user!.email;
      final reference = db.collection("users").doc(id).collection("jobs").orderBy("epoch");
      final snapshot = await reference.get();
      List jobs = [];
      for(var doc in snapshot.docs){
        final data = doc.data();
        data["id"] = doc.id;
        jobs.add(data);
      }
      setState(() {
        userJobs = jobs;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    getUserData();
  }

  Widget jobObject(BuildContext context, Map<String, dynamic> jobInfo){
    if(userData["isDriver"]){
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

      if(jobInfo["inProgress"] == "Accepted"){
        return Column(
            children: [
              Text("Deadline: ${jobInfo["deadline"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Client Name: ${jobInfo["merchant"]}"),
              Text("Job Status: ${jobInfo["inProgress"]}"),
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
              weatherAlert("Origin Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["origin"]["y"],
                  longitude: jobInfo["origin"]["x"]
              )),
              weatherAlert("Destination Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["destin"]["y"],
                  longitude: jobInfo["destin"]["x"]
              )),
              markPickUpButton(jobInfo["id"], jobInfo["merchantId"], jobInfo),
            ]
        );
      }else if(jobInfo["inProgress"] == "Picked up"){
        return Column(
            children: [
              Text("Deadline: ${jobInfo["deadline"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Client Name: ${jobInfo["merchant"]}"),
              Text("Job Status: ${jobInfo["inProgress"]}"),
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
              weatherAlert("Origin Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["origin"]["y"],
                  longitude: jobInfo["origin"]["x"]
              )),
              weatherAlert("Destination Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["destin"]["y"],
                  longitude: jobInfo["destin"]["x"]
              )),
              deliverButton(jobInfo["id"], jobInfo["merchantId"], jobInfo),
            ]
        );
      }else{
        return Column(
            children: [
              Text("Deadline: ${jobInfo["deadline"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Client Name: ${jobInfo["merchant"]}"),
              Text("Job Status: ${jobInfo["inProgress"]}"),
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
              weatherAlert("Origin Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["origin"]["y"],
                  longitude: jobInfo["origin"]["x"]
              )),
              weatherAlert("Destination Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["destin"]["y"],
                  longitude: jobInfo["destin"]["x"]
              )),
            ]
        );
      }
    }else{
      if(jobInfo["inProgress"] == null){
        return Column(
            children: [
              Text("Job Deadline: ${jobInfo["deadline"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Value of Cargo: \$${jobInfo["value"]}"),
              Text("Job Status: Awaiting Driver"),
              Container(
                  constraints: BoxConstraints(maxHeight: 500, maxWidth: 500),
                  child: mapDisplay(context, jobInfo["origin"], jobInfo["destin"], true)
              ),
              weatherAlert("Origin Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["origin"]["y"],
                  longitude: jobInfo["origin"]["x"]
              )),
              weatherAlert("Destination Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["destin"]["y"],
                  longitude: jobInfo["destin"]["x"]
              )),
              cancelJobButton(jobInfo["id"]),
            ]
        );
      }else if(jobInfo["inProgress"] == "Delivered"){
        return Column(
            children: [
              Text("Job Deadline: ${jobInfo["deadline"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Value of Cargo: \$${jobInfo["value"]}"),
              Text("Job Status: ${jobInfo["inProgress"]}"),
              Container(
                  constraints: BoxConstraints(maxHeight: 500, maxWidth: 500),
                  child: mapDisplay(context, jobInfo["origin"], jobInfo["destin"], true)
              ),
              weatherAlert("Origin Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["origin"]["y"],
                  longitude: jobInfo["origin"]["x"]
              )),
              weatherAlert("Destination Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["destin"]["y"],
                  longitude: jobInfo["destin"]["x"]
              )),
              completeJobButton(jobInfo["id"], jobInfo["driverId"])
            ]
        );
      }else{
        return Column(
            children: [
              Text("Job Deadline: ${jobInfo["deadline"]}", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Value of Cargo: \$${jobInfo["value"]}"),
              Text("Job Status: ${jobInfo["inProgress"]}"),
              Container(
                  constraints: BoxConstraints(maxHeight: 500, maxWidth: 500),
                  child: mapDisplay(context, jobInfo["origin"], jobInfo["destin"], true)
              ),
              weatherAlert("Origin Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["origin"]["y"],
                  longitude: jobInfo["origin"]["x"]
              )),
              weatherAlert("Destination Weather Alerts: ", GeoPoint(
                  latitude: jobInfo["destin"]["y"],
                  longitude: jobInfo["destin"]["x"]
              )),
            ]
        );
      }
    }
  }

  Widget jobDetails(BuildContext context){
    if(userData.isEmpty){
      return CircularProgressIndicator();
    }else{
      ScrollController scrollController = ScrollController();
      if(!jobsExist){
        if(userData["isDriver"]){
          return Text("No jobs assigned? Click on the button below!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)
          );
        }else if(userData["isMerchant"] as bool){
          return Text("No jobs created? Click on the button below!",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          );
        }
      }else{
        return Scrollbar(
            controller: scrollController,
            child: ListView.separated(
              controller: scrollController,
              itemBuilder: (BuildContext context, int index){
                return jobObject(context, userJobs[index]);
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
              itemCount: userJobs.length,
            )
        );
      }
    }
    return CircularProgressIndicator();
  }

  Widget goToJobBoardButton(BuildContext context, bool isDriver){
    return IconButton(
      color: Colors.black,
      icon: Icon(Icons.add,size: 60),
      onPressed: () async{
        if(isDriver){
          await Navigator.push(context, MaterialPageRoute(
              builder: (context) => TakeJobScreen(widget.cred)
          ));
          setState(() {
            checkJobSection();
            getJobs();
          });
        }else{
          await Navigator.push(context, MaterialPageRoute(
              builder: (context) => CreateJob(widget.cred, userData["email"], userData["name"])
          ));
          setState(() {
            checkJobSection();
            getJobs();
          });
        }
      },
    );
  }

  Widget navigationBar(BuildContext context){
    if(userData.isEmpty){
      return CircularProgressIndicator();
    }else{
      return Container(
          color: Theme.of(context).colorScheme.inversePrimary,
          child: goToJobBoardButton(context, userData["isDriver"])
      );
    }
  }

  Widget mapDisplay(BuildContext context, Map<String, dynamic> origin, Map<String, dynamic> destination, bool isJobObject){
    MapController controller = MapController(
      initPosition: GeoPoint(
          latitude: (origin["y"]!),
          longitude: (origin["x"]!)
      ),
    );
    if(isJobObject){
      controller.listenerMapSingleTapping.addListener(() {
        if (controller.listenerMapSingleTapping.value != null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  insetPadding:  EdgeInsets.zero,
                  contentPadding: EdgeInsets.zero,
                  title: Text("Map of Route"),
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
              roadOption: RoadOption(
                  roadColor: Colors.deepPurple
              )
          );
        }
      },
    );
  }

  Widget cancelJobButton(var id){
    return ElevatedButton(
        onPressed: () {
          db.collection("users").doc(widget.cred.user?.email).collection("jobs").doc(id).delete();
          db.collection("open-jobs").doc(id).delete();
          checkJobSection();
          getJobs();
        },
        child: Text("Cancel Job")
    );
  }

  Widget markPickUpButton(var id, String merchantId, Map<String, dynamic> jobInfo){
    return ElevatedButton(
        onPressed: () {
          jobInfo["inProgress"] = "Picked up";
          db.collection("users").doc(widget.cred.user?.email).collection("jobs").doc(id).update(jobInfo);
          db.collection("users").doc(merchantId).collection("jobs").doc(id).update(jobInfo);
          getJobs();
        },
        child: Text("Mark Cargo as Loaded")
    );
  }

  Widget deliverButton(var id, String merchantId, Map<String, dynamic> jobInfo){
    return ElevatedButton(
        onPressed: () {
          jobInfo["inProgress"] = "Delivered";
          db.collection("users").doc(widget.cred.user?.email).collection("jobs").doc(id).update(jobInfo);
          db.collection("users").doc(merchantId).collection("jobs").doc(id).update(jobInfo);
          getJobs();
        },
        child: Text("Mark Cargo as Delivered")
    );
  }

  Widget completeJobButton(var id, String merchantId){
    return ElevatedButton(
        onPressed: () {
          db.collection("users").doc(widget.cred.user?.email).collection("jobs").doc(id).delete();
          db.collection("users").doc(merchantId).collection("jobs").doc(id).delete();
          checkJobSection();
          getJobs();
        },
        child: Text("Confirm Job Completion")
    );
  }

  void checkJobSection() async{
    if(jobsExist == true){
      return;
    }
    final id = widget.cred.user!.email;
    final reference = db.collection("users").doc(id).collection("jobs");
    final snapshot = await reference.get();
    if(snapshot.size != 0){
      setState(() {
        jobsExist = true;
      });
      getJobs();
    }
  }

  Widget weatherAlert(String type, GeoPoint point){
    return FutureBuilder(
        future: getWeatherAlerts(point),
        builder: (context, snapshot){
          if(snapshot.hasData){
            return Text(type + snapshot.data!);
          }else{
            return CircularProgressIndicator();
          }
        }
    );
  }

  Future<String> getWeatherAlerts(GeoPoint point) async {
    var response = await http.get(Uri.parse('https://api.weather.gov/alerts/active?point=${point.latitude},${point.longitude}'));
    var json = convert.jsonDecode(response.body) as Map<String, dynamic>;
    if(response.statusCode == 400) {
      if(json["detail"].contains("invalid")){
        return "Unable to retrieve data from outside the United States";
      }
    }
    for(var item in json["features"]){
      String alert = item["properties"]["event"];
      return alert;
    }
    return "No alerts";
  }
}