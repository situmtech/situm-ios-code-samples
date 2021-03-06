//
//  SGSUserInsideEventVC.m
//  GettingStarted
//
//  Created by Cristina Sánchez Barreiro on 11/09/2018.
//  Copyright © 2018 Situm Technologies S.L. All rights reserved.
//

#import "SGSUserInsideEventVC.h"
#import <SitumSDK/SitumSDK.h>

@interface SGSUserInsideEventVC () <SITLocationDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic) BOOL doNotShowAgain;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property(nonatomic, strong) UIAlertController *alert;

@end

@implementation SGSUserInsideEventVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self customizeNavigationBarWithTitle:@"User inside event"];
    [self.activityIndicator startAnimating];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.selectedBuildingInfo.events == nil || self.selectedBuildingInfo.events.count == 0) {
        [self showNoEventsAlert];
    } else {
        [self startPositioning];
        [self.infoLabel setText:@"Initializing positioning"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startPositioning {
    [SITLocationManager sharedInstance].delegate = self;
    SITLocationRequest *request = [[SITLocationRequest alloc] initWithBuildingId:self.selectedBuildingInfo.building.identifier];
    [[SITLocationManager sharedInstance] requestLocationUpdates:request];
}

#pragma mark - SITLocationDelegate methods
    
- (void)locationManager:(id<SITLocationInterface>)locationManager didFailWithError:(NSError *)error{
    NSLog(@"%@", error);
}

- (void)locationManager:(nonnull id<SITLocationInterface>)locationManager didUpdateLocation:(nonnull SITLocation *)location {
    [self.infoLabel setText:@"Calculating if the user is inside an event"];
    SITEvent *event = [self getEventForLocation: location];
    
    if (event != nil) {
        NSLog(@"%@", [NSString stringWithFormat:@"User inside event: %@", event.name]);
        if (!_doNotShowAgain && ![_alert isBeingPresented]) {
            [self showAlertWithEvent:event];
        }
    }
}

- (void)locationManager:(nonnull id<SITLocationInterface>)locationManager didUpdateState:(SITLocationState)state {
    NSLog(@"%d", state);
}

#pragma mark - Event detection methods

- (SITEvent*) getEventForLocation: (SITLocation*) location {
    for (SITEvent *event in self.selectedBuildingInfo.events) {
        if ([self isLocation: location insideEvent: event]) {
            return event;
        }
    }
    return nil;
}

- (BOOL) isLocation: (SITLocation*) location
        insideEvent: (SITEvent*) event {
    if (! [location.position.floorIdentifier isEqualToString:event.trigger.center.floorIdentifier]) {
        return false;
    }
    return [location.position distanceToPoint:event.trigger.center] < [event.trigger.radius floatValue];
}

#pragma mark - Alerts

- (void)showAlertWithEvent:(SITEvent *)event {
    _alert = [UIAlertController alertControllerWithTitle:@"Event" message:[NSString stringWithFormat:@"User inside event: %@", event.name] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissButton = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *doNotShowAgainButton = [UIAlertAction actionWithTitle:@"Do not show again" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        self.doNotShowAgain = true;
    }];
    [_alert addAction:dismissButton];
    [_alert addAction:doNotShowAgainButton];
    [self presentViewController:_alert animated:YES completion:nil];
}

- (void)showNoEventsAlert {
    _alert = [UIAlertController alertControllerWithTitle:@"Error" message: @"There are no events, please create them on the Dashboard, or try selecting a different building" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissButton = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [_alert addAction:dismissButton];
    
    [self presentViewController:_alert animated:YES completion:nil];
}

#pragma mark - Exit example
-(void)exitExample:(UIBarButtonItem *)sender{
    [[SITLocationManager sharedInstance] removeUpdates];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
