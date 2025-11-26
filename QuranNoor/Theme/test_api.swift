import MapKit
import Contacts

// Test to see what's available on iOS 26 MapKit types
func test() {
    let item: MKMapItem? = nil
    
    // Check MKAddressRepresentations
    if let reps = item?.addressRepresentations {
        // Try to access properties - this will show compile errors for what doesn't exist
        let _ = reps
    }
    
    // Check MKAddress
    if let addr = item?.address {
        let _ = addr
    }
}
