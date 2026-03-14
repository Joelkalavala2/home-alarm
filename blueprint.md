# Project Blueprint

## Overview

This document outlines the plan for creating a location-based alarm app. The app will allow users to save locations (like "Home" or "Work") and will trigger an alarm when the user enters a customizable radius around any of these saved locations.

## Features

*   **Map View:** The main screen will display a map using `google_maps_flutter`.
*   **Location Saving:** Users can tap on the map to select a location and save it with a custom name.
*   **Geofencing:** The app will continuously check the user's current location.
*   **Customizable Radius:** Users can set a radius (in kilometers) for the geofence.
*   **Personalized Alarm:** When the user is within the specified radius of a saved location, the app will play a text-to-speech alarm with a personalized message (e.g., "Hi [Name], you are near home").
*   **Persistence:** Saved locations, the user's name, and the radius setting will be saved to the device and loaded when the app starts.
*   **State Management:** The `provider` package will be used for state management.

## Plan

1.  **Dependencies:** Add `google_maps_flutter`, `geolocator`, `flutter_tts`, `provider`, and `shared_preferences` to `pubspec.yaml`.
2.  **UI:**
    *   Create a `HomeScreen` with a `GoogleMap` widget.
    *   Add UI elements for saving locations, entering a name, and setting the radius.
3.  **State Management:**
    *   Create a `LocationProvider` to manage saved locations, user settings, and the current location.
4.  **Location Logic:**
    *   Use `geolocator` to get the user's current position.
    *   Calculate the distance between the current position and saved locations.
5.  **Alarm:**
    *   Use `flutter_tts` to generate a spoken alarm when the geofence is triggered.
6.  **Persistence:**
    *   Use `shared_preferences` to save and retrieve user data.
