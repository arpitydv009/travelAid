# ✈️ Travel Planner

A smart iOS travel-planning app that generates personalized itineraries based on your **destination, trip duration, traveler persona, and real-time weather**.

Built with **Swift and SwiftUI** as a first-year competition project, with a focus on both building a polished product and learning modern iOS development.

## 🎯 What It Does

Travel Planner takes a few simple inputs:

- 📍 Destination
- 📅 Trip duration
- 🎒 Traveler persona

It then uses real-time weather information to create a personalized itinerary.

The itinerary adapts to conditions such as:

- ☀️ Sunny weather → more outdoor activities
- 🌧️ Rain → more indoor activities
- 🌡️ Extreme temperatures → adjusted activity timing/types

Different traveler personas also influence the recommendations:

- 🎒 **Backpacker** — budget-friendly and adventurous
- ✨ **Luxury** — premium and comfort-focused
- 👨‍👩‍👧 **Family** — practical and family-friendly

## 🧠 How It Works

```text
Destination
     ↓
Location / Coordinates
     ↓
Real-time Weather
     ↓
Weather Classification
     ↓
Persona + Weather + Activity Data
     ↓
Itinerary Rules Engine
     ↓
Day-by-Day Travel Plan
     ↓
Optional AI Enhancement
```

The core itinerary generation is designed to be **deterministic and reliable**.

AI is used as an enhancement rather than being responsible for the application's core functionality. This means the app can still generate a usable itinerary if an AI service is unavailable.

## 🛠️ Tech Stack

- **Swift**
- **SwiftUI**
- **SwiftData**
- **MapKit**
- **CoreLocation**
- **URLSession**
- **Codable**
- **ShareLink**
- AI API integration (optional enhancement)

The project primarily uses Apple's native frameworks and avoids unnecessary third-party dependencies.

## 📱 Planned Screens

### Home

Configure a trip by entering:

- Destination
- Duration
- Traveler persona

### Trip Overview

A quick summary of:

- Destination
- Duration
- Persona
- Weather
- Itinerary information

### Itinerary

The main travel-planning experience with:

- Day-by-day plans
- Activity times
- Locations
- Indoor/outdoor information
- Weather-aware recommendations

### My Trips

Previously generated trips can be saved and reopened.

## ⭐ Optional Features

If time permits:

- 🗺️ MapKit-based itinerary maps
- 📏 Distance calculations
- 🚶 Estimated travel times
- 🔗 Shareable itineraries
- 💾 Persistent saved trips
- 🤖 AI-generated descriptions and summaries

## 🏗️ Development Approach

This project is being built incrementally rather than as one large implementation.

Major development areas include:

1. SwiftUI foundations
2. Trip configuration UI
3. Data modeling
4. Navigation and app state
5. Destination search
6. Networking fundamentals
7. Weather integration
8. Activity data
9. Itinerary rules engine
10. Daily scheduling
11. Trip generation
12. Itinerary UI
13. SwiftData persistence
14. AI enhancement
15. MapKit
16. Sharing
17. UI/UX polish
18. Testing and competition preparation

## 🤖 AI-Assisted Development

AI agents are being used heavily during development.

The current workflow uses different tools for different purposes:

- **Codex** — primary coding and repository agent
- **GitHub Copilot** — in-editor assistance
- **Claude** — architecture and code review
- **Gemini** — brainstorming, research, and alternative approaches

The goal is not simply to have AI build the application. The project is also being used to learn:

- Swift
- SwiftUI
- Networking
- APIs
- Async/await
- Architecture
- Algorithms
- SwiftData
- MapKit
- AI integration

The user remains actively involved in implementation, review, and technical decisions.

## 🚧 Project Status

**Currently in development.**

The project is starting from a blank SwiftUI application and is being developed phase-by-phase.

## 📄 Competition Requirements

### Required

- Destination city input
- Trip duration input
- Traveler persona selection
- Real-time weather API
- Weather-aware itinerary generation
- Persona-aware itinerary generation
- Functional and well-designed UI/UX

### Bonus

- Shareable itinerary URLs
- Local persistence
- Distance/time calculations

---

Built with ❤️ using SwiftUI.
