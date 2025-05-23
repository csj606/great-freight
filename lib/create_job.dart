import 'dart:convert' as convert;

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:string_validator/string_validator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class CreateJob extends StatefulWidget {
  const CreateJob(this.cred, this.userId, this.userName, {super.key});

  final UserCredential cred;
  final String userId;
  final String userName;
  @override
  State<CreateJob> createState() => _CreateJob();
}

class _CreateJob extends State<CreateJob>{

  TextEditingController deadline = TextEditingController();
  TextEditingController weight = TextEditingController();
  TextEditingController value = TextEditingController();
  MapController controller = MapController(
    initPosition: GeoPoint(
        latitude: 40.726963,
        longitude: -73.995069
    ),
  );
  MapController destinController = MapController(
    initPosition: GeoPoint(
        latitude: 0,
        longitude: 0
    ),
  );
  Map<String, double> origin = {};
  Map<String, double> destin = {};
  bool? ltlLoad = false;
  bool? temperatureControls = false;
  String errorMessage = "";
  String destinationAddress = "";
  String originAddress = "";
  FirebaseFirestore db = FirebaseFirestore.instance;
  DateTime time = DateTime.now();
  bool retrievingOriginAddress = false;
  bool retrievingDestinAddress = false;

  Widget theForm(BuildContext context){
    ScrollController scrollController = ScrollController();
    return Scrollbar(
      controller: scrollController,
      child:ListView(
        children: [
          Row(
            children: [
              ltlCheckbox(),
              Text("Is this shipment an LTL Load?")
            ],
          ),
          Row(
            children: [
              tempControlsCheckbox(),
              Text("Does the shipment require temperature controls?")
            ],
          ),
          deadlineInput(),
          weightInput(),
          valueInput(),
          originButton(context),
          originAddressDisplay(),
          destinButton(context),
          destinationAddressDisplay(),
          Container(
              child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red
                  )
              )
          ),
          createJobButton(context)
        ],
      ),
    );
  }

  Widget originAddressDisplay(){
    if(originAddress.isNotEmpty){
      return Container(
        child: Text(
          originAddress,
          textAlign: TextAlign.center,
        ),
      );
    }else if(retrievingOriginAddress){
      return CircularProgressIndicator();
    }else{
      return Text("Origin has not been selected");
    }
  }

  Widget destinationAddressDisplay(){
    if(destinationAddress.isNotEmpty){
      return Container(
        child: Text(
          destinationAddress,
          textAlign: TextAlign.center,
        ),
      );
    }else if(retrievingDestinAddress){
      return CircularProgressIndicator();
    }else{
      return Text("Destination has not been selected or is being processed");
    }
  }

  Widget ltlCheckbox(){
    return Checkbox(
      value: ltlLoad,
      onChanged: (bool? change){
        setState(() {
          ltlLoad = change;
        });
      },
    );
  }

  Widget tempControlsCheckbox(){
    return Checkbox(
      value: temperatureControls,
      onChanged: (bool? change){
        setState(() {
          temperatureControls = change;
        });
      },
    );
  }

  Widget deadlineInput(){
    return TextField(
        controller: deadline,
        onTap: () async{
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if(pickedDate != null){
            time = pickedDate;
            String formattedDate = DateFormat("MM/dd/yyyy").format(pickedDate);
            setState(() {
              deadline.text = formattedDate;
            });
          }
        },
        decoration: InputDecoration(
            labelText: "   Deadline"
        )
    );
  }

  Widget weightInput(){
    return TextField(
        controller: weight,
        onSubmitted: (String input) async{
          if(isNumeric(input)){
            setState(() {
              weight.text = input;
            });
          }else{
            setState(() {
              errorMessage = "Invalid weight input - the input must be a number";
            });
          }
        },
        decoration: InputDecoration(
            labelText: "   Cargo Weight in Pounds"
        )
    );
  }

  Widget valueInput(){
    return TextField(
        controller: value,
        onSubmitted: (String input) async{
          if(isNumeric(input)){
            setState(() {
              value.text = input;
            });
          }else{
            setState(() {
              errorMessage = "Invalid value input - the input must be a number";
            });
          }
        },
        decoration: InputDecoration(
            labelText: "   Cargo Value in US Dollars"
        )
    );
  }

  Widget originMap(){
    controller.listenerMapLongTapping.addListener(() {
      if (controller.listenerMapLongTapping.value != null) {
        GeoPoint value = controller.listenerMapLongTapping.value!;
        origin["x"] = value.latitude;
        origin["y"] = value.longitude;
        setState(() {
          controller.addMarker(value);
        });
      }
    });
    return SizedBox(
        width: 500,
        height: 500,
        child: OSMFlutter(
          controller: controller,
          osmOption: OSMOption(
            zoomOption: ZoomOption(
              initZoom: 10,
              minZoomLevel: 3,
              maxZoomLevel: 19,
              stepZoom: 1.0,
            ),
          ),
        )
    );
  }

  Widget destinMap(){
    destinController.listenerMapLongTapping.addListener(() {
      if (destinController.listenerMapLongTapping.value != null) {
        GeoPoint value = destinController.listenerMapLongTapping.value!;
        destin["x"] = value.latitude;
        destin["y"] = value.longitude;
        setState(() {
          destinController.addMarker(value);
        });
      }
    });
    return SizedBox(
        width: 500,
        height: 500,
        child: OSMFlutter(
          controller: destinController,
          osmOption: OSMOption(
            zoomOption: ZoomOption(
              initZoom: 10,
              minZoomLevel: 3,
              maxZoomLevel: 19,
              stepZoom: 1.0,
            ),
          ),
        )
    );
  }

  Widget createJobButton(BuildContext context){
    return ElevatedButton(
        onPressed: () {
          if(deadline.text == ""){
            errorMessage = "Please select a date";
          }else if(weight.text == ""){
            errorMessage = "Please select a weight";
          }else if(origin.isEmpty){
            errorMessage = "Please select a origin for the job";
          }else if(destin.isEmpty){
            errorMessage = "Please select a destination";
          }else{
            Map <String, dynamic> jobRecord = {};
            jobRecord["deadline"] = deadline.text;
            jobRecord["weight"] = int.parse(weight.text);
            jobRecord["value"] = double.parse(value.text);
            jobRecord["epoch"] = time.millisecondsSinceEpoch;
            jobRecord["origin"] = origin;
            jobRecord["destin"] = destin;
            jobRecord["isLTL"] = ltlLoad;
            jobRecord["isTempControlled"] = temperatureControls;
            jobRecord["merchantId"] = widget.userId;
            jobRecord["merchant"] = widget.userName;
            final reference = db.collection("users").doc(widget.userId).collection("jobs").doc();
            reference.set(jobRecord);
            db.collection("open-jobs").doc(reference.id).set(jobRecord);
            Navigator.pop(context);
          }
        },
        child: Text("Submit Job")
    );
  }

  Widget originButton(BuildContext context){
    return ElevatedButton(
      onPressed: () async {
        GeoPoint? originPoint = await showSimplePickerLocation(
            context: context,
            isDismissible: true,
            title: "Choose your start location",
            textConfirmPicker: "Confirm",
            initPosition: GeoPoint(
                latitude: 40.726963,
                longitude: -73.995069
            )
        );
        if(originPoint != null){
          origin["x"] = originPoint.longitude;
          origin["y"] = originPoint.latitude;
          setState(() {
            retrievingOriginAddress = true;
          });
          var response = await http.get(Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${originPoint.latitude}&lon=${originPoint.longitude}'));
          var json = convert.jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            originAddress = "Origin Address: ${json["display_name"]}";
            retrievingOriginAddress = false;
          });
        }
      },
      child: Text("Choose a start location"),
    );
  }

  Widget destinButton(BuildContext context){
    return ElevatedButton(
      onPressed: () async {
        GeoPoint? originPoint = await showSimplePickerLocation(
            context: context,
            isDismissible: true,
            title: "Choose your end location",
            textConfirmPicker: "Please confirm your selection",
            initPosition: GeoPoint(
                latitude: 40.726963,
                longitude: -73.995069
            )
        );
        if(originPoint != null){
          destin["x"] = originPoint.longitude;
          destin["y"] = originPoint.latitude;
          setState(() {
            retrievingDestinAddress = true;
          });
          var response = await http.get(Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${originPoint.latitude}&lon=${originPoint.longitude}'));
          var json = convert.jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            retrievingDestinAddress = false;
            destinationAddress = "Destination Address: ${json["display_name"]}";
          });
        }
      },
      child: Text("Choose a end location"),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Create a new job"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: theForm(context)
    );
  }
}