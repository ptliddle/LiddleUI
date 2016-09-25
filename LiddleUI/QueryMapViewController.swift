//
//  QueryMapViewController.swift
//  SaveThePlace
//
//  Created by Peter Liddle on 5/19/16.
//  Copyright © 2016 Peter Liddle. All rights reserved.
//

import UIKit
import MapKit
import Parse

public extension PFGeoPoint {
    public func asCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}

open class PFMapObject : PFObject {
    @NSManaged open var coordinate : PFGeoPoint?
}

public protocol QueryMapDelegate {
    func mapView(_ mapView: MKMapView, viewForAnnotation annotation: MKAnnotation, dataModel : PFMapObject?) -> MKAnnotationView?
}

public extension MKPointAnnotation {
    static func withCoordinate(_ coordinate : CLLocationCoordinate2D) -> MKPointAnnotation {
        let point = MKPointAnnotation()
        point.coordinate = coordinate
        return point
    }
}

open class QueryMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet open var mapView : MKMapView!
    
    static let metersPerMile = 1609.34
    
    open var mapDistanceQueryUpdateTrigger : CLLocationDistance = 10
    
    let kCoordinateKey = "coordinate"
    let kOrderByKey = "createdAt"
    
    open var lastLocation : CLLocation?
    var lastRegion : MKCoordinateRegion?
    
    open var itemsToLoad : Int = 10
    open var parseClassName : String? = nil
    open var objectsPerArea : Int? = 25
    
    var firstLoad : Bool = false // Whether we have loaded the first set of objects
    var lastLoadCount : Int = -1 // The count of objects from the last load.
    // Set to -1 when objects haven't loaded, or there was an error.
    
    var mutableObjects : [PFObject] = []
    open var objectToAnnotations : [MKPointAnnotation : PFMapObject]? = [:]
    
    var loading : Bool = false
    var loadingViewEnabled = true;
    var loadingView : UIView?
    
    var forceNetworkQueryOnNoHits : Bool = false
    var stopTrackingUserLocationOnInteraction = false
    
    open var userDraggedMap : Bool = false
    open var updateFromLocationChange : Bool = false
    
    fileprivate var defaultUserTrackingMode : MKUserTrackingMode!
    fileprivate var supressRegionUpdate = false
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        defaultUserTrackingMode = mapView.userTrackingMode
    }
    
    open func createAnnotation(forObject object : PFMapObject) -> MKPointAnnotation {
        return MKPointAnnotation.withCoordinate(object.coordinate!.asCoordinate())
    }
}

extension CLLocation {
    public static func locationFromCoordinate(_ coordinate : CLLocationCoordinate2D) -> CLLocation {
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

//MARK - Map View Delegate Methods
extension QueryMapViewController {

    @objc(mapView:viewForAnnotation:) open func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let mapAnnotation = annotation as? MKPointAnnotation, let object = objectToAnnotations?[mapAnnotation] {
            return self.mapView(mapView, viewForAnnotation: mapAnnotation, dataModel: object)
        }
        return self.mapView(mapView, viewForAnnotation: annotation, dataModel: nil)
    }
    
    open func mapView(_ mapView: MKMapView, viewForAnnotation annotation: MKAnnotation, dataModel : PFMapObject? = nil) -> MKAnnotationView? {
        //Implement in sub class
        return nil
    }
    

    
    open func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Map Region Did Update")
        if regionChanged(mapView.region) {
            self.reloadDataForCurrentRegion()
        }
        
        lastRegion = mapView.region
    }
    
    @objc(mapView:didUpdateUserLocation:) open func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        updateFromLocationChange = true
        
        let region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100))
        supressRegionUpdate = true
        self.mapView.setRegion(region, animated: true)
        reloadDataForCurrentRegion {
            self.refreshMapDisplay()
        }
        
        
        
//        if let location = mapView.userLocation.location {
//            if let previousLocation = lastLocation {
//                if location.distanceFromLocation(previousLocation) > mapDistanceQueryUpdateTrigger {
//                    self.reloadDataForCurrentRegion()
//                }
//            }
//            else {
//                 self.reloadDataForCurrentRegion()
//            }
//            
//            lastLocation = location
//        }
    }
    
    
    
    public func regionChanged(_ region : MKCoordinateRegion) -> Bool {
        if let previousRegion : MKCoordinateRegion = lastRegion {
            let previousLocation = CLLocation.locationFromCoordinate(previousRegion.center)
            let currentLocation = CLLocation.locationFromCoordinate(region.center)
            
            if currentLocation.distance(from: previousLocation) < mapDistanceQueryUpdateTrigger {
                return false
            }
        }
        
        return true
    }
    
    public func reloadDataForCurrentRegion(_ complete : (() -> ())? = nil) {
        let searchRadius = calculateRegionRadius(mapView.region) / QueryMapViewController.metersPerMile
        loadObjects(searchRadius, clear: true, completion: complete)
    }
    
    public func calculateRegionRadius(_ region : MKCoordinateRegion) -> CLLocationDistance {
        let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let outPoint = CLLocation(latitude: region.center.latitude + region.span.latitudeDelta / 2, longitude: region.center.longitude + region.span.longitudeDelta / 2)
        return outPoint.distance(from: center)
    }
    
    public func userInteractedWithMap() {
        userDraggedMap = true
        let userTrackingMode = stopTrackingUserLocationOnInteraction ? MKUserTrackingMode.none : defaultUserTrackingMode
        self.mapView.setUserTrackingMode(userTrackingMode!, animated: false)
    }
    
    open func queryForMap() -> PFQuery<PFObject> {
        
        //Use guard here
        if let _ = self.parseClassName {} else {
            let exception = NSException(name: NSExceptionName.internalInconsistencyException, reason: "You need to specify a parseClassName for the PFQueryTableViewController.", userInfo: nil)
            exception.raise()
        }
        
        let query = PFQuery(className: self.parseClassName!)
        
        // If no objects are loaded in memory, we look to the cache first to fill the table
        // and then subsequently do a query against the network.
        if let objects = self.objectToAnnotations?.values , (objects.count == 0 && !Parse.isLocalDatastoreEnabled()) {
            query.cachePolicy = PFCachePolicy.cacheThenNetwork;
        }
        
        query.order(byDescending: kOrderByKey)
        
        return query
    }

    
    open func refreshMapDisplay() {
        DispatchQueue.main.async(execute: {
            self.mapView.setNeedsDisplay()
        })
    }
}

//MARK: Touch methods
public extension QueryMapViewController {
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       userInteractedWithMap()
    }
}

//MARK: Data Methods
public extension QueryMapViewController {
    
    public func objectsWillLoad() {
        if(firstLoad) {
            //_refreshLoadingView
        }
        self.refreshLoadingView()
    }
    
    public func objectsDidLoad(_ error : NSError?) {
        if (firstLoad) {
            firstLoad = false
        }
        self.refreshLoadingView()
    }
    
    // Alters a query to add functionality like pagination
    private func alterQuery(_ query: PFQuery<PFObject>, searchRadius : CLLocationDistance? = nil) {
        query.limit = self.objectsPerArea!
        addSearchRadiusToQuery(query, searchRadius: searchRadius)
    }
    
    private func addSearchRadiusToQuery(_ query : PFQuery<PFObject>, searchRadius : CLLocationDistance? = nil) {
        let coord = self.mapView.centerCoordinate
        
        if let _ = searchRadius {
            query.whereKey(kCoordinateKey, nearGeoPoint: PFGeoPoint(latitude: coord.latitude, longitude: coord.longitude), withinMiles: searchRadius!)
        }
        else {
            query.whereKey(kCoordinateKey, nearGeoPoint: PFGeoPoint(latitude: coord.latitude, longitude: coord.longitude))
        }
        
    }
    
    private func clear() {
        mutableObjects = []
    }
    
    func loadObjects(_ searchRadius : CLLocationDistance? = nil, clear : Bool = true, completion : (() -> ())? = nil) -> BFTask<AnyObject> {
        print("Load objects from Parse")
        self.loading = true
        self.objectsWillLoad()
        
        let query = self.queryForMap()
        self.alterQuery(query, searchRadius: searchRadius)
        
        let source : BFTaskCompletionSource = BFTaskCompletionSource<AnyObject>()
        query.findObjectsInBackground { (foundObjects, error) in
            if let errorCode = (error as? NSError)?.code , Parse.isLocalDatastoreEnabled() && query.cachePolicy != PFCachePolicy.cacheOnly && errorCode == PFErrorCode.errorCacheMiss.rawValue {
                // no-op on cache miss
                return
            }
            
            self.loading = false
            
            if let unwrappedError = error {
                self.lastLoadCount = -1
                self.loadObjectsFailed(unwrappedError as NSError)
            }
            else {
                self.lastLoadCount = foundObjects?.count ?? -1
                
                if clear {
                    self.mutableObjects = []
                }
                
                self.mutableObjects.append(contentsOf: foundObjects!)
                self.loadObjectsCompletedSuccesfully(foundObjects as! [PFMapObject], completion : completion)
            }
            
            self.objectsDidLoad(error as NSError?)
            
            if let _ = error {
                source.trySetError(error!)
            } else {
                source.trySetResult(foundObjects as AnyObject?)
            }
        }
        
        return source.task;
    }
    
    
    func loadObjectsCompletedSuccesfully(_ objects : [PFMapObject], completion : (() -> ())? = nil) {
        
        clearExistingAnnotations()
        
        objects.forEach { (object) in
            let annotation = createAnnotation(forObject: object)
            objectToAnnotations?[annotation] = object
            
            DispatchQueue.main.async(execute: {
                self.mapView.addAnnotation(annotation)
            })
        }
        
        completion?()
    }
    
    func loadObjectsFailed(_ error : NSError){
        print("failed to load objects with error: \(error)")
    }
    
    
    func clearExistingAnnotations() {
        DispatchQueue.main.async { 
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        self.objectToAnnotations?.removeAll(keepingCapacity: true)
    }
    
    open func refreshLoadingView() {
        //Can be overridden to show a loading view
        
        if loadingViewEnabled {
            loadingView?.removeFromSuperview()
            loadingViewEnabled = false
        }
        else {
            if let _ = loadingView { } else {
                let center = self.view.center
                let size = CGSize(width: self.view.frame.size.width / 3, height: self.view.frame.size.width / 3)
                loadingView = UIView(frame: CGRect(origin: center, size: size))
                loadingViewEnabled = false
            }
            
            self.view.addSubview(loadingView!)
        }
    }
}
