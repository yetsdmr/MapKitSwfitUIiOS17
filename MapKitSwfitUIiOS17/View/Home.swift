//
//  Home.swift
//  MapKitSwfitUIiOS17
//
//  Created by Yunus Emre Taşdemir on 24.06.2023.
//

import SwiftUI
import MapKit

struct Home: View {
    // Map Properties
    @State private var cameraPosition: MapCameraPosition = .region (.myRegion)
    @Namespace private var locationSpace
    @State private var viewingRegion: MKCoordinateRegion?
    @State private var mapSelection: MKMapItem?
    // Search Properties
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    @State private var searchResults: [MKMapItem] = []
    // Map Selection Detail Properties
    @State private var showDetails: Bool = false
    @State private var lookAroundScene: MKLookAroundScene?
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $mapSelection, scope: locationSpace) {
                // Map Annotations
                Annotation ("Apple Park", coordinate: .myLocation) {
                    ZStack {
                        Image (systemName: "applelogo")
                            .font(.title3)
                        
                        Image (systemName: "square")
                            .font(.largeTitle)
                    }
                }
                .annotationTitles (.hidden)
                
                // Simply Display Annotations as Marker, as we seen before
                ForEach(searchResults, id: \.self) { mapItem in
                    let placemark = mapItem.placemark
                    Marker(placemark.name ?? "Place", coordinate: placemark.coordinate)
                        .tint(.blue)
                }
                
                // To Show User Current Location
                UserAnnotation()
            }
            .onMapCameraChange({ ctx in
                viewingRegion = ctx.region
            })
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 15) {
                    MapCompass (scope: locationSpace)
                    MapPitchButton (scope: locationSpace)
                    MapUserLocationButton (scope: locationSpace)
                }
                .buttonBorderShape(.circle)
                .padding()
            }
            .mapScope(locationSpace)
            .navigationTitle ("Map" )
            .navigationBarTitleDisplayMode(.inline)
            // Search Bar
            .searchable(text: $searchText, isPresented: $showSearch)
            // Showing Trasnlucent ToolBar
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
            .sheet(isPresented: $showDetails, content: {
                MapDetails()
                    .presentationDetents([.height(300)])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(300)))
                    .presentationCornerRadius(25)
                    .interactiveDismissDisabled(true)
            })
        }
        .onSubmit(of: .search) {
            Task {
                guard !searchText.isEmpty else { return }
                
                await searchPlaces()
            }
        }
        .onChange(of: showSearch, initial: false) {
            if !showSearch {
                // Clearing Search Results
                searchResults.removeAll(keepingCapacity: false)
                showDetails = false
                // Zooming out to User Region when Search Cancelled
                withAnimation(.snappy) {
                    cameraPosition = .region(.myRegion)
                }
            }
        }
        .onChange(of: mapSelection) { oldValue, newValue in
            // Displaying Details about the Selected Place
            showDetails = newValue != nil
            // Fetching Look Around Preview, when ever selection Changes
            fetchLookAroundPreview()
        }
    }
    
    // Map Details View
    @ViewBuilder
    func MapDetails() -> some View {
        VStack(spacing: 15) {
            ZStack {
                // New Look Around API
                if lookAroundScene == nil {
                    // New Empty View API
                    ContentUnavailableView("No Preview Available", systemImage: "eye.slash")
                } else {
                    LookAroundPreview(scene: $lookAroundScene)
                }
            }
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 15))
            // Close Button
            .overlay (alignment: .topTrailing) {
                Button(action: {
                    // Closing View
                    showDetails = false
                    withAnimation(.snappy) {
                        mapSelection = nil
                    }
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .background(.white, in: .circle)
                })
                .padding(10)
            }
            
            // Direction's Button
            Button ("Get Directions") {
                
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.blue.gradient, in: .rect(cornerRadius: 15))
        }
        .padding(15)
    }
    
    // Search Places
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = viewingRegion ?? .myRegion
        
        let results = try? await MKLocalSearch(request: request).start()
        searchResults = results?.mapItems ?? []
    }
    
    // Fetching Location Preview
    func fetchLookAroundPreview() {
        if let mapSelection {
            // Clearing Old One
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                lookAroundScene = try? await request.scene
            }
        }
    }
}

#Preview {
    ContentView()
}

// Location Data
extension CLLocationCoordinate2D {
    static var myLocation: CLLocationCoordinate2D {
        return .init(latitude: 37.3346, longitude: -122.0090)
    }
}

extension MKCoordinateRegion {
    static var myRegion: MKCoordinateRegion {
        return .init(center: .myLocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
    }
}
