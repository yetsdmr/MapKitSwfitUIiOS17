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
    // Search Properties
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    @State private var searchResults: [MKMapItem] = []
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, scope: locationSpace) {
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
                    Marker (placemark.name ?? "Place", coordinate: placemark.coordinate)
                }
                
                // To Show User Current Location
                UserAnnotation()
            }
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
        }
        .onSubmit(of: .search) {
            Task {
                guard !searchText.isEmpty else { return }
                
                await searchPlaces()
            }
        }
    }
    
    // Search Places
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = .myRegion
        
        let results = try? await MKLocalSearch(request: request).start()
        searchResults = results?.mapItems ?? []
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
