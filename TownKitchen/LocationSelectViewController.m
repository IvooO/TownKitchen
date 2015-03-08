//
//  LocationSelectViewController.m
//  TownKitchen
//
//  Created by Miles Spielberg on 3/5/15.
//  Copyright (c) 2015 The Town Kitchen. All rights reserved.
//

#import "LocationSelectViewController.h"
#import <MapKit/MapKit.h>
#import <LMGeocoder.h>

@interface LocationSelectViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIButton *setAddressButton;

@end

@implementation LocationSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}






#pragma mark Private Methods

- (void)setup {
    // Set up mapkit
    self.mapView.delegate = self;
}

#pragma mark MKMapViewDelegate Methods

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    // called when user's location changes
}

#pragma mark Actions

- (IBAction)onLocationButton:(id)sender {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

- (IBAction)onGetAddress:(id)sender {
    [[LMGeocoder sharedInstance] reverseGeocodeCoordinate:CLLocationCoordinate2DMake(37.785834, -122.406417)
                                                  service:kLMGeocoderGoogleService
                                        completionHandler:^(LMAddress *address, NSError *error) {
                                            if (address && !error) {
                                                NSLog(@"Address: %@", address.formattedAddress);
                                            }
                                            else {
                                                NSLog(@"Error: %@", error.description);
                                            }
                                        }];
}

- (IBAction)onGetCoordinates:(id)sender {
    [[LMGeocoder sharedInstance] geocodeAddressString:@"100 Mision Street"
                                              service:kLMGeocoderAppleService
                                    completionHandler:^(LMAddress *address, NSError *error) {
                                        if (address && !error) {
                                            NSLog(@"Coordinate: (%f, %f)", address.coordinate.latitude, address.coordinate.longitude);
                                        }
                                        else {
                                            NSLog(@"Error: %@", error.description);
                                        }
                                    }];
}

#pragma mark System Methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
