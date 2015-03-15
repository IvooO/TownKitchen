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
#import "ParseAPI.h"

@interface CheckoutViewController () <UITableViewDataSource, UITableViewDelegate, LocationSelectViewControllerDelegate, TimeSelectViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (strong, nonatomic) NSArray *orderItems;

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) NSDate *selectedDate;

@property (strong, nonatomic) NSArray *menuOptionShortnames;
@property (strong, nonatomic) NSDictionary *shortNameToObject;

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
    
    // populate menu option shortnames and retrieve corresponding objects
    NSMutableArray *mutableMenuOptionShortnames = [NSMutableArray array];
    NSMutableDictionary *mutableShortNameToObject = [NSMutableDictionary dictionary];
    
    for (NSString *shortName in order.items) {
        if ([order.items[shortName] isEqualToNumber:@0]) {
            continue;
        }
        else {
            [mutableMenuOptionShortnames addObject:shortName];
            [mutableShortNameToObject addEntriesFromDictionary:@{ shortName : [[ParseAPI getInstance] menuOptionForShortName:shortName] }];
            self.menuOptionShortnames = [NSArray arrayWithArray:mutableMenuOptionShortnames];
            self.shortNameToObject = [NSDictionary dictionaryWithDictionary:mutableShortNameToObject];
            [self reloadTableData];
        }
    }
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
    self.order.deliveryAddress = address;
}

#pragma mark LocationSelectViewControllerDelegate Methods

- (void)timeSelectViewController:(TimeSelectViewController *)tvc didSetDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm a"];
    NSString *currentTime = [dateFormatter stringFromDate:date];
    NSLog(@"got time from selector: %@", currentTime);
    self.timeLabel.text = currentTime;
    self.selectedDate = date;
    self.order.deliveryDateAndTime = date;
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuOptionShortnames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CheckoutOrderItemCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"CheckoutOrderItemCell"];
    NSString *shortName = self.menuOptionShortnames[indexPath.row];
    MenuOption *menuOption = self.shortNameToObject[shortName];
    float menuOptionPrice = [menuOption.price floatValue];
    float quantity = [self.order.items[shortName] floatValue];
    float priceForQuantity = menuOptionPrice * quantity;
    
    cell.quantity = self.order.items[shortName];
    cell.price = [NSNumber numberWithFloat:priceForQuantity];
    cell.menuOption = menuOption;

    return cell;
}

#pragma mark Actions

- (IBAction)onPlaceOrder:(id)sender {
    self.order.user = [PFUser currentUser];
    
    NSLog(@"validating order: %@", self.order);
    NSLog(@"result: %hhd", (char)[[ParseAPI getInstance] validateOrder:self.order]);
    
    
//    OrdersViewController *ovc = [[OrdersViewController alloc] init];
//    [self.navigationController pushViewController:ovc animated:YES];
}

- (IBAction)onSetAddressButton:(id)sender {
    [self setAddress];
}

- (IBAction)onSetTimeButton:(id)sender {
    [self setTime];
}



@end
