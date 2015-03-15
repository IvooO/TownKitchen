//
//  CheckoutViewController.m
//  TownKitchen
//
//  Created by Miles Spielberg on 3/5/15.
//  Copyright (c) 2015 The Town Kitchen. All rights reserved.
//

#import "CheckoutViewController.h"
#import "CheckoutOrderItemCell.h"
#import "MenuOption.h"
#import "AddressInputViewController.h"
#import <GoogleKit.h>
#import "LocationSelectViewController.h"
#import "TimeSelectViewController.h"
#import "OrdersViewController.h"

@interface CheckoutViewController () <UITableViewDataSource, UITableViewDelegate, LocationSelectViewControllerDelegate, TimeSelectViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (strong, nonatomic) NSArray *orderItems;

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) NSDate *selectedDate;

@property (strong, nonatomic) NSArray *menuOptionItems;

@end

@implementation CheckoutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark custom setters

- (void)setOrder:(Order *)order {
    _order = order;
    [self reloadTableData];
    
    for (NSString *shortName in order.items) {
        NSLog(@"order short name: %@", shortName);
        if ([order.items[shortName] isEqualToNumber:@0]) {
            continue;
        }
        else {
            
        }
    }
    
//    NSMutableArray *mutableOrderItems = [NSMutableArray array];
//    for (NSString *menuItem in order.items) {
//        NSMutableDictionary *orderItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                          menuItem, @"menuItemName",
//                                        order.items[menuItem], @"quantity", nil];
//        [mutableOrderItems addObject:orderItem];
//    }
//    NSLog(@"mutableOrderItems: %@", mutableOrderItems);
//    
//    [mutableOrderItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        if (obj1[@"quantity"] > obj2[@"quantity"]) {
//            return NSOrderedAscending;
//        }
//        else if (obj1[@"quantity"] < obj2[@"quantity"]) {
//            return NSOrderedDescending;
//        }
//        else {
//            return NSOrderedSame;
//        }
//    }];
//    self.orderItems = [NSArray arrayWithArray:mutableOrderItems];
//        NSLog(@"%@", self.orderItems);
//    
//    // retrieve menu options from Parse
//    for (NSMutableDictionary *orderItem in self.orderItems) {
//        NSLog(@"looking for: %@", orderItem[@"menuItemName"]);
//        PFQuery *menuOptionQuery = [MenuOption query];
//        [menuOptionQuery whereKey:@"name" containsString:orderItem[@"menuItemName"]];
//        [menuOptionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//            orderItem[@"menuOption"] = [objects firstObject];
//            NSLog(@"orderItem is now: %@", orderItem);
//            [self reloadTableData];
//        }];
//    }
}

#pragma mark Private Methods

- (void)setup{
    // tableView methods
    self.title = @"Checkout";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"CheckoutOrderItemCell" bundle:nil] forCellReuseIdentifier:@"CheckoutOrderItemCell"];
    [self reloadTableData];
}

- (void)reloadTableData {
    [self.tableView reloadData];
}

- (void)setAddress {
    LocationSelectViewController *lvc = [[LocationSelectViewController alloc] init];
    lvc.delegate = self;
    [self presentViewController:lvc animated:YES completion:nil];
}

- (void)setTime {
    TimeSelectViewController *tvc = [[TimeSelectViewController alloc] init];
    tvc.delegate = self;
    [self presentViewController:tvc animated:YES completion:nil];
    if (self.selectedDate) {
        [tvc.datePicker setDate:self.selectedDate animated:NO];
    }
}

#pragma mark LocationSelectViewControllerDelegate methods

- (void)locationSelectViewController:(LocationSelectViewController *)locationSelectViewController didSelectAddress:(NSString *)address {
    self.addressLabel.text = address;
}

#pragma mark LocationSelectViewControllerDelegate Methods

- (void)timeSelectViewController:(TimeSelectViewController *)tvc didSetDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm a"];
    NSString *currentTime = [dateFormatter stringFromDate:date];
    NSLog(@"got time from selector: %@", currentTime);
    self.timeLabel.text = currentTime;
    self.selectedDate = date;
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.order.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CheckoutOrderItemCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"CheckoutOrderItemCell"];
    return cell;
}

#pragma mark Actions

- (IBAction)onPlaceOrder:(id)sender {
    self.order.user = [PFUser currentUser];
    [self.order save];
    OrdersViewController *ovc = [[OrdersViewController alloc] init];
    [self.navigationController pushViewController:ovc animated:YES];
}

- (IBAction)onSetAddressButton:(id)sender {
    [self setAddress];
}

- (IBAction)onSetTimeButton:(id)sender {
    [self setTime];
}



@end
