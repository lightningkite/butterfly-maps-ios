//
//  MKMapView+bind.swift
//  LKButterflyMaps
//
//  Created by Joseph Ivie on 10/28/19.
//  Copyright © 2019 Lightning Kite. All rights reserved.
//

import Foundation
import MapKit
import LKButterfly

public extension MKMapCamera {
    var zoom: Float {
        return 15 //ugh... this needs to be actually accurate
    }
}

public extension MKMapView {

    func bind(dependency: ViewControllerAccess, style: String? = nil) {
        //Not sure how to style MKMapView?
    }

    func bindView(
        dependency: ViewControllerAccess,
        position: ObservableProperty<GeoCoordinate?>,
        zoomLevel: Float = 15,
        animate: Bool = true,
        style: String? = nil
    ) {
        bindView(dependency, position, zoomLevel, animate)
    }
    func bindView(
        _ dependency: ViewControllerAccess,
        _ position: ObservableProperty<GeoCoordinate?>,
        _ zoomLevel: Float = 15,
        _ animate: Bool = true,
        _ style: String? = nil
    ) {
        self.bind(dependency: dependency, style: style)
        var annotation: MKPointAnnotation? = nil
        position.subscribeBy(
            onError: {_ in },
            onComplete: { },
            onNext: { value in
                if let value = value {
                    let point = annotation ?? {
                        let new = MKPointAnnotation()
                        new.coordinate = value.toIos()
                        self.addAnnotation(new)
                        return new
                    }()
                    let view = self.view(for: point)
                    view?.isDraggable = true
                    point.coordinate = value.toIos()
                    annotation = point
                    self.setCenter(value.toIos(), animated: true)
                    
                    let location = CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
                    let region = MKCoordinateRegion( center: location, latitudinalMeters: CLLocationDistance(exactly: (22 - zoomLevel) * 100)!, longitudinalMeters: CLLocationDistance(exactly: (22 - zoomLevel) * 100)!)
                    self.setRegion(self.regionThatFits(region), animated: animate)
                    
                } else {
                    if let point = annotation {
                        self.removeAnnotation(point)
                    }
                    annotation = nil
                }
            }
        ).until(self.removed)

        self.onClick {
            dependency.openMap(coordinate: position.value ?? GeoCoordinate(latitude: 39.161913, longitude: -142.788386))
        }
    }
    
    func bindSelect(
        dependency: ViewControllerAccess,
        position: MutableObservableProperty<GeoCoordinate?>,
        zoomLevel: Float = 15,
        animate: Bool = true,
        style: String? = nil
    ) {
        bindSelect(dependency, position, zoomLevel, animate)
    }
    func bindSelect(
        _ dependency: ViewControllerAccess,
        _ position: MutableObservableProperty<GeoCoordinate?>,
        _ zoomLevel: Float = 15,
        _ animate: Bool = true,
        _ style: String? = nil
    ) {
        self.bind(dependency: dependency, style: style)
        let delegate = SelectDelegate(position)
        var annotation: MKPointAnnotation? = nil
        position.subscribeBy(
            onError: {_ in },
            onComplete: { },
            onNext: { value in
                if let value = value {
                    if !delegate.suppress {
                        delegate.suppress = true
                        let point = annotation ?? {
                            let new = MKPointAnnotation()
                            new.coordinate = value.toIos()
                            self.addAnnotation(new)
                            return new
                        }()
                        let view = self.view(for: point)
                        view?.isDraggable = true
                        point.coordinate = value.toIos()
                        annotation = point
                        delegate.suppress = false
                        if !delegate.suppressAnimation {
                            self.setCenter(value.toIos(), animated: true)
                            let location = CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
                            let region = MKCoordinateRegion( center: location, latitudinalMeters: CLLocationDistance(exactly: (22 - zoomLevel)*100)!, longitudinalMeters: CLLocationDistance(exactly: (22 - zoomLevel)*100)!)
                            self.setRegion(self.regionThatFits(region), animated: true)
                        }
                    }
                } else {
                    if let point = annotation {
                        self.removeAnnotation(point)
                    }
                    annotation = nil
                }
            }
        ).until(self.removed)
        
        self.delegate = delegate
        self.retain(as: "delegate", item: delegate, until: removed)
        
        onLongClickWithGR { [weak self, unowned delegate] gr in
            guard let self = self else { return }
//            let coords = self.convert(gr.locationInView(self), toCoo(in: : self)
            let coords = self.convert(gr.location(in: self), toCoordinateFrom: self)
            delegate.suppressAnimation = true
            position.value = coords.toButterfly()
            delegate.suppressAnimation = false
        }
    }
    
    private class SelectDelegate : NSObject, MKMapViewDelegate {
        
        var suppress = false
        var suppressAnimation = false
        
        let position: MutableObservableProperty<GeoCoordinate?>
        init(_ position: MutableObservableProperty<GeoCoordinate?>){
            self.position = position
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
            switch newState {
            case .starting:
                view.dragState = .dragging
            case .ending, .canceling:
                if let coordinate = (view.annotation as? MKPointAnnotation)?.coordinate, !suppress {
                    suppress = true
                    position.value = coordinate.toButterfly()
                    suppress = false
                }
                view.dragState = .none
            default: break
            }
        }
    }
    
}
