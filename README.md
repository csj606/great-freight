# great-freight
3PL Flutter Application

## Overview

  During the initial spike of grocery prices in the United States, there was a great deal of discussion as to why transportation prices were continuing to increase. Many small businesses expressed frustration since transportation and freight costs were opaque given freight broker's activities and policies. Both truck drivers and small businesses would benefit from an application that would allow them to directly work with each other and cut out freight brokers who could be elevating prices and restricting trucker drivers' incomes. The idea of Great Freight is to create a demo of a platform which would enable them to do so.

## Features
In the app, there are two different user types. A user can either be a merchant or a driver.

There are four unique screens in total:
- A login page
- A home screen
- A screen where merchant users can create jobs
- A screen where driver users can sort and take unfilled jobs

Both types of users can:
- Create and modify a small user profile
- View ongoing jobs assigned or issued by them
- Modify the status of those jobs when relevant their home page

## Dependencies and APIs

This project heavily relies on Google Firebase for its backend services. In particular, it utilizes Firebase Authentication for IAM services and Firebase Firestore for the application's data base. For all maps displayed, the application calls on the OpenStreetMaps API to retrieve map tiles and display them, along with routes between the origin and destination. In the Create Job screen, the Nominatim API is used to retrieve street addresses from the inputted coordinates. Finally, the weather alerts provided in the home page are retrieved from the US National Weather Service API.

## Known Issues

1. Since this is a demo, I have elected to use the public APIs for OpenStreetMaps and Nominatim. However, for production usage, self-hosting these services is strongly recommended.
2. Not all dependencies have been included in the pubspec.yaml file. You may need to add some dependencies if you encounter build errors.

## Setup

Make sure to install the Firebase CLI prior to following these steps. Note this assumes that you have done all the necessary Firebase configurations and setup for Firebase Authentication (specifically email login) and Firebase Firestore. These commands should be executed in the directory that you clone this repository to.

1. firebase login
2. flutter pub add firebase_core
3. flutterfire configure
4. flutter run
