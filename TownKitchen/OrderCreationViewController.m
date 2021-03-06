//
//  OrderCreationViewController.m
//  TownKitchen
//
//  Created by Miles Spielberg on 3/5/15.
//  Copyright (c) 2015 The Town Kitchen. All rights reserved.
//

#import "OrderCreationViewController.h"

#import "AppDelegate.h"
#import "CheckoutViewController.h"
#import "DateLabelsViewSmall.h"
#import "DateUtils.h"
#import "Inventory.h"
#import "LocationSelectViewController.h"
#import <MBProgressHUD.h>
#import "Order.h"
#import "OrderButtonView.h"
#import "OrderCreationCell.h"
#import "OrderConfirmationViewController.h"
#import "OrdersViewController.h"
#import "ParseAPI.h"
#import "PaymentViewController.h"
#import "PopupAnimationController.h"
#import "PopupDismissAnimationController.h"
#import "STPCard.h"
#import "STPAPIClient.h"
#import "TKHeader.h"
#import <UIView+MTAnimation.h>


@interface OrderCreationViewController () <UITableViewDelegate, UITableViewDataSource, OrderCreationTableViewCellDelegate, CheckoutViewControllerDelegate, PaymentViewControllerDelegate, LocationSelectViewControllerDelegate, OrderButtonViewDelegate, OrderConfirmationViewControllerDelegate, UIViewControllerTransitioningDelegate>

@property (assign, nonatomic) CGFloat parentWidth;
@property (assign, nonatomic) CGFloat parentHeight;
@property (assign, nonatomic) CGFloat horizontalGapSize;
@property (assign, nonatomic) CGFloat navigationBarHeight;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet TKHeader *header;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet OrderButtonView *orderButtonView;

@property (strong, nonatomic) OrderCreationCell *sizingCell;
@property (strong, nonatomic) NSArray *menuOptionShortNames;
@property (strong, nonatomic) NSDictionary *shortNameToObject;
@property (strong, nonatomic) NSMutableDictionary *shortNameToQuantity;

@property (strong, nonatomic) Order *order;
@property (strong, nonatomic) DateLabelsViewSmall *dateLabelsViewSmall;
@property (strong, nonatomic) CheckoutViewController *checkoutViewController;
@property (strong, nonatomic) UIView *filterView;
@property (strong, nonatomic) PaymentViewController *paymentViewController;
@property (strong, nonatomic) LocationSelectViewController *locationSelectViewController;
@property (strong, nonatomic) OrderConfirmationViewController *orderConfirmationViewController;

@end

@implementation OrderCreationViewController

#pragma mark - View Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];

    Inventory *firstInventory = self.inventoryItems[0];
    self.title = [DateUtils monthAndDayFromDate:firstInventory.dateOffered];

    // retrieve MenuOption objects
    NSMutableArray *mutableMenuOptionShortNames = [NSMutableArray array];
    NSMutableDictionary *mutableShortNameToObject = [NSMutableDictionary dictionary];
    self.shortNameToQuantity = [NSMutableDictionary dictionary];

    for (Inventory *inventoryItem in self.inventoryItems) {
        NSString *shortName = inventoryItem.menuOptionShortName;

        [mutableMenuOptionShortNames addObject:shortName];

        MenuOption *menuOption = inventoryItem.menuOptionObject;
        [mutableShortNameToObject setObject:menuOption forKey:shortName];

        self.menuOptionShortNames = [NSArray arrayWithArray:mutableMenuOptionShortNames];
        self.shortNameToObject = [NSDictionary dictionaryWithDictionary:mutableShortNameToObject];
    }

    self.locationSelectViewController = [[LocationSelectViewController alloc] init];
    self.locationSelectViewController.delegate = self;
    
    self.paymentViewController = [[PaymentViewController alloc] init];
    self.paymentViewController.delegate = self;
    
    // Set up tableView
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"OrderCreationCell" bundle:nil] forCellReuseIdentifier:@"OrderCreationCell"];
    
    // add a footer so button does not hide menu options
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
    [self.tableView reloadData];
    
    // Set up custom header
    // Create date label
    DateLabelsViewSmall *dateLabelsViewSmall = [[DateLabelsViewSmall alloc] initWithFrame:self.header.titleView.bounds];
    dateLabelsViewSmall.weekdayLabel.text = [DateUtils dayOfTheWeekFromDate:firstInventory.dateOffered];
    dateLabelsViewSmall.monthAndDayLabel.text = [DateUtils monthAndDayFromDate:firstInventory.dateOffered];
    [self.header.titleView addSubview:dateLabelsViewSmall];
    
    // Create back button
    CGRect backButtonFrame = self.header.leftView.bounds;
    self.backButton = [[UIButton alloc] initWithFrame:backButtonFrame];
    [self.backButton addTarget:self action:@selector(onBackButton) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setImage:[UIImage imageNamed:@"back-button"] forState:UIControlStateNormal];
    [self.backButton setImage:[UIImage imageNamed:@"back-button-highlighted"] forState:UIControlStateHighlighted];
    [self.header.leftView addSubview:self.backButton];
    
    // Create cancel button
    CGRect cancelButtonFrame = self.header.leftView.bounds;
    self.cancelButton = [[UIButton alloc] initWithFrame:cancelButtonFrame];
    [self.cancelButton addTarget:self action:@selector(onCancelOrder) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setImage:[UIImage imageNamed:@"cancel-button"] forState:UIControlStateNormal];
    [self.cancelButton setImage:[UIImage imageNamed:@"cancel-button-highlighted"] forState:UIControlStateHighlighted];
    self.cancelButton.hidden = YES;
    self.cancelButton.enabled = NO;
    [self.header.leftView addSubview:self.cancelButton];
    
    // define frame variables
    self.parentWidth = self.view.bounds.size.width;
    self.parentHeight = self.view.bounds.size.height;
    self.horizontalGapSize = 20.0;
    self.navigationBarHeight = 64;
    
    // set up order button
    self.orderButtonView.delegate = self;
}

- (void)viewWillLayoutSubviews {

}

#pragma mark - OrderCreationTableViewCellDelegate Methods

- (void)orderCreationTableViewCell:(OrderCreationCell *)cell didUpdateQuantity:(NSNumber *)quantity {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSString *shortName = self.menuOptionShortNames[indexPath.row];
    if (quantity.integerValue == 0) {
        [self.shortNameToQuantity removeObjectForKey:shortName];
    } else {
        self.shortNameToQuantity[shortName] = quantity;
    }
    [self updateOrderObjectItems];
    NSLog(@"updated quantity for %@, quantities dictionary is now: %@", shortName, self.shortNameToQuantity);
}

#pragma mark - CheckoutViewControllerDelegate Methods

- (void)addressButtonPressedFromCheckoutViewController:(CheckoutViewController *)cvc {
    [self displayViewControllerAnimatedFromBottom:self.locationSelectViewController];
}

- (void)paymentButtonPressedFromCheckoutViewController:(CheckoutViewController *)cvc {
    [self displayViewControllerAnimatedFromRight:self.paymentViewController];
}

// Place order
- (void)orderButtonPressedFromCheckoutViewController:(CheckoutViewController *)cvc {
    NSLog(@"attempting to place order: %@", self.order);

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);  // slight delay to let UI draw HUD
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.order.user = [PFUser currentUser];
        
        STPCard *card = [[STPCard alloc] init];
        PTKView *paymentEntryView = self.paymentViewController.paymentEntryView;
        
        card.number = paymentEntryView.card.number;
        card.expMonth = paymentEntryView.card.expMonth;
        card.expYear = paymentEntryView.card.expYear;
        card.cvc = paymentEntryView.card.cvc;
        NSLog(@"Set up card: %@", card);
        NSLog(@"%@ %ld %ld %@", paymentEntryView.card.number, (long) paymentEntryView.card.expMonth, (long) paymentEntryView.card.expYear, paymentEntryView.card.cvc);
        
        [[STPAPIClient sharedClient] createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
            if (error) {
                NSLog(@"Error while handling card: %@", error);
            } else {
                [self createBackendChargeWithToken:token completion:nil];
            }
        }];
        
        NSLog(@"validating order: %@", self.order);
        NSLog(@"result: %hhd", (char)[[ParseAPI getInstance] validateOrder:self.order]);
        
        if ([[ParseAPI getInstance] validateOrder:self.order]) {
            self.order.status = @"paid";
            self.order.driverLocation = [PFGeoPoint geoPointWithLatitude:37.789329 longitude:-122.397533];
            [[ParseAPI getInstance] createOrder:self.order];

            self.orderConfirmationViewController = [[OrderConfirmationViewController alloc] init];
            self.orderConfirmationViewController.delegate = self;
            self.orderConfirmationViewController.email = [[PFUser currentUser] email];
            self.orderConfirmationViewController.transitioningDelegate = self;
            self.orderConfirmationViewController.modalPresentationStyle = UIModalPresentationCustom;
            [self presentViewController:self.orderConfirmationViewController animated:YES completion:nil];
            
            [[ParseAPI getInstance] sendEmailConfirmationForOrder:self.order];
            AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate registerForNotifications];
        } else {
            NSLog(@"Order failed");
        }
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

#pragma mark - LocationSelectViewControllerDelegate Methods

// user selected delivery address
- (void)locationSelectViewController:(LocationSelectViewController *)locationSelectViewController didSelectAddress:(NSString *)address withShortString:(NSString *)shortString {
    self.order.deliveryAddress = address;
    self.checkoutViewController.address = address;
    self.checkoutViewController.addressLabel.text = shortString;
    [[ParseAPI getInstance] setCurrentUserPreferredAddress:address withShortString:shortString];
    [self hideViewControllerAnimateToBottom:locationSelectViewController];
}

#pragma mark - PaymentViewControllerDelegate Methods

- (void)onSetPaymentButtonFromPaymentViewController:(PaymentViewController *)pvc withCardValidity:(BOOL)valid {
    NSLog(@"PaymentViewControllerDelegate method called");
    if (valid) {
        [[ParseAPI getInstance] setCurrentUserPaymentMethod:@"card"];
        self.checkoutViewController.buttonState = ButtonStatePlaceOrder;
    } else {
        self.checkoutViewController.buttonState = ButtonStateEnterPayment;
    }
    [self hideViewControllerAnimateToRight:self.paymentViewController];
}

#pragma mark - OrderButtonViewDelegate Methods

- (void)orderButtonPressedFromOrderButtonView:(OrderButtonView *)view {
    if (self.order.items.count > 0) {
        [self createOrderAndCheckout];
    } else {
        // bounce plus buttons
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BouncePlusButton" object:self];
    }
}

#pragma mark - OrderConfirmationViewControllerDelegate Methods

- (void)onDoneButtonTappedFromOrderConfirmationViewController:(OrderConfirmationViewController *)viewController {
    [self.orderConfirmationViewController dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate Methods

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (presented == self.orderConfirmationViewController) {
        return [PopupAnimationController new];
    } else {
        return nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (dismissed == self.orderConfirmationViewController) {
        return [PopupDismissAnimationController new];
    } else {
        return nil;
    }
}

#pragma mark - Table View Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuOptionShortNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OrderCreationCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OrderCreationCell"];
    cell.delegate = self;

    NSString *shortName = self.menuOptionShortNames[indexPath.row];
    cell.menuOption = self.shortNameToObject[shortName];
    cell.quantity = self.shortNameToQuantity[shortName];

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Initialize the sizing cell
    if (!self.sizingCell) {
        self.sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"OrderCreationCell"];
    }

    // Populate cell with the same data as the visible cell
    NSString *shortName = self.menuOptionShortNames[indexPath.row];
    self.sizingCell.menuOption = self.shortNameToObject[shortName];
    self.sizingCell.quantity = self.shortNameToQuantity[shortName];
    
    [self.sizingCell setNeedsUpdateConstraints];
    [self.sizingCell updateConstraintsIfNeeded];

    // Set cell width to the same width as tableView
    self.sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(self.sizingCell.bounds));
    [self.sizingCell setNeedsLayout];
    [self.sizingCell layoutIfNeeded];

    // Get the height of the sizing cell, adding one to compensate for cell separators
    CGFloat height = [self.sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1;
    return height;
}

#pragma mark - Private methods

- (void)createOrderAndCheckout {
    if (!self.order) {
        self.order = [Order object];
    }
    self.order.items = self.shortNameToQuantity;
    self.order.user = [PFUser currentUser];
    Inventory *firstInventory = self.inventoryItems[0];
    self.order.deliveryDateAndTime = [firstInventory dateOffered];
    self.order.shortNameToMenuOptionObject = self.shortNameToObject;
    
    self.order.totalPrice = @0;
    
    for (NSString *shortName in self.order.items) {
        MenuOption *menuOption = self.order.shortNameToMenuOptionObject[shortName];
        self.order.totalPrice = @([self.order.totalPrice doubleValue] + [menuOption.price doubleValue] * [self.order.items[shortName] doubleValue]);
    }
    
    NSLog(@"Creating order: %@", self.order);
    
    if (!self.checkoutViewController) {
        self.checkoutViewController = [[CheckoutViewController alloc] init];
    }
    
    self.checkoutViewController.shortNameToObject = self.shortNameToObject;
    self.checkoutViewController.menuOptionShortNames = self.menuOptionShortNames;
    self.checkoutViewController.delegate = self;
    
    [self setLeftButtonToCancel];
    [self displayViewControllerAnimatedFromBottomWithFilter:self.checkoutViewController];
    
    // call these after UI elements are loaded
    self.checkoutViewController.order = self.order;
    self.checkoutViewController.buttonState = ButtonStateEnterPayment;
    
    // prepopulate checkout fields if possible
    NSString *preferredAddress = (NSString *)[[PFUser currentUser] valueForKey:@"preferredAddress"];
    NSString *preferredAddressShort = (NSString *)[[PFUser currentUser] valueForKey:@"preferredAddressShort"];
    NSDate *preferredTime = (NSDate *)[[PFUser currentUser] valueForKey:@"preferredTime"];
    NSString *paymentMethod = (NSString *)[[PFUser currentUser] valueForKey:@"paymentMethod"];
    if (preferredAddress && preferredAddressShort) {
        self.checkoutViewController.address = preferredAddress;
        self.checkoutViewController.addressLabel.text = preferredAddressShort;
        self.order.deliveryAddress = preferredAddress;
    }
    if (preferredTime) {
        self.checkoutViewController.deliveryTime = preferredTime;
    }
    if (paymentMethod) {
        self.checkoutViewController.paymentMethod = paymentMethod;
    }
}

- (void)updateOrderObjectItems {
    if (!self.order) {
        self.order = [Order object];
    }
    self.order.items = self.shortNameToQuantity;
    self.order.totalPrice = @0;
    int totalQuantity = 0;
    
    for (NSString *shortName in self.order.items) {
        MenuOption *menuOption = self.shortNameToObject[shortName];
        self.order.totalPrice = @([self.order.totalPrice doubleValue] + [menuOption.price doubleValue] * [self.order.items[shortName] doubleValue]);
        
        totalQuantity += [self.shortNameToQuantity[shortName] intValue];
    }
    self.orderButtonView.price = self.order.totalPrice;
    self.orderButtonView.quantity = totalQuantity;
}

- (void)onCancelOrder {
    // dismiss checkout view
    [self setLeftButtonToBack];
    [self hideViewControllerAnimateToBottomRemoveFilter:self.checkoutViewController];
    
    // dismiss payment view
    [self hideViewControllerAnimateToBottom:self.paymentViewController];
    
    // dismiss location select view
    [self hideViewControllerAnimateToBottom:self.locationSelectViewController];
}

- (void)onBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createBackendChargeWithToken:(STPToken *)token completion:(void (^)(NSError *))completion {
    NSLog(@"Got the token: %@", token);
    //    NSURL *url = [NSURL URLWithString:@"https://example.com/token"];
    //    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    //    request.HTTPMethod = @"POST";
    //    NSString *body     = [NSString stringWithFormat:@"stripeToken=%@", token.tokenId];
    //    request.HTTPBody   = [body dataUsingEncoding:NSUTF8StringEncoding];
    //
    //    [NSURLConnection sendAsynchronousRequest:request
    //                                       queue:[NSOperationQueue mainQueue]
    //                           completionHandler:^(NSURLResponse *response,
    //                                               NSData *data,
    //                                               NSError *error) {
    //                               if (completion != nil) {
    //                                   completion(error);
    //                               }
    //                           }];
}

#pragma mark - View Controller Presentation Methods

- (void)displayViewController:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    viewController.view.frame = [self frameForModalViewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)hideViewController:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

- (void)displayViewControllerAnimatedFromBottom:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    
    // define initial and final frames
    CGRect finalFrame = [self frameForModalViewController];
    CGRect initialFrame = finalFrame;
    initialFrame.origin.y += initialFrame.size.height;
    viewController.view.frame = initialFrame;
    
    [self.view addSubview:viewController.view];
    
    // set shadow
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds];
    viewController.view.layer.masksToBounds = NO;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    viewController.view.layer.shadowRadius = 6;
    viewController.view.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    viewController.view.layer.shadowOpacity = 0.3;
    viewController.view.layer.shadowPath = shadowPath.CGPath;
    
    // animate transition
    [UIView mt_animateWithViews:@[viewController.view]
                       duration:0.5
                          delay:0.0
                 timingFunction:kMTEaseOutQuart
                     animations:^{
                         viewController.view.frame = finalFrame;
                     } completion:^{
                         // complete the transition
                         [viewController didMoveToParentViewController:self];
                     }];
}

- (void)displayViewControllerAnimatedFromBottomWithFilter:(UIViewController *)viewController {
    // create gray filter view
    self.filterView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBarHeight, self.parentWidth, self.parentHeight - self.navigationBarHeight)];
    self.filterView.backgroundColor = [UIColor colorWithWhite:0.75 alpha:0.75];
    self.filterView.alpha = 0.0;
    [self.view addSubview:self.filterView];

    [self addChildViewController:viewController];

    CGRect finalFrame = [self frameForModalViewController];
    CGRect initialFrame = finalFrame;
    initialFrame.origin.y += initialFrame.size.height;
    viewController.view.frame = initialFrame;
    [self.view addSubview:viewController.view];
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds];
    viewController.view.layer.masksToBounds = NO;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    viewController.view.layer.shadowRadius = 6;
    viewController.view.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    viewController.view.layer.shadowOpacity = 0.3;
    viewController.view.layer.shadowPath = shadowPath.CGPath;
    
    [UIView mt_animateWithViews:@[viewController.view]
                       duration:0.5
                          delay:0.0
                 timingFunction:kMTEaseOutQuart
                     animations:^{
                         viewController.view.frame = finalFrame;
                     } completion:^{
                         [viewController didMoveToParentViewController:self];
                     }];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.filterView.alpha = 1.0;
                     } completion:nil];
}

- (void)displayViewControllerAnimatedFromRight:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    
    // define initial and final frames
    CGRect finalFrame = [self frameForModalViewController];
    CGRect initialFrame = finalFrame;
    initialFrame.origin.x += initialFrame.size.width;
    viewController.view.frame = initialFrame;
    
    [self.view addSubview:viewController.view];
    
    // set shadow
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds];
    viewController.view.layer.masksToBounds = NO;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    viewController.view.layer.shadowRadius = 6;
    viewController.view.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    viewController.view.layer.shadowOpacity = 0.3;
    viewController.view.layer.shadowPath = shadowPath.CGPath;
    
    // animate transition
    [UIView mt_animateWithViews:@[viewController.view]
                       duration:0.5
                          delay:0.0
                 timingFunction:kMTEaseOutQuart
                     animations:^{
                         viewController.view.frame = finalFrame;
                     } completion:^{
                         // complete the transition
                         [viewController didMoveToParentViewController:self];
                     }];
}

- (void)hideViewControllerAnimateToBottom:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    
    CGRect finalFrame = [self frameForModalViewController];
    finalFrame.origin.y += finalFrame.size.height;
    
    [UIView mt_animateWithViews:@[viewController.view]
                       duration:0.5
                          delay:0.0
                 timingFunction:kMTEaseOutQuart
                     animations:^{
                         viewController.view.frame = finalFrame;
                     } completion:^{
                         [viewController.view removeFromSuperview];
                         [viewController removeFromParentViewController];
                     }];
}

- (void)hideViewControllerAnimateToBottomRemoveFilter:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    
    CGRect finalFrame = [self frameForModalViewController];
    finalFrame.origin.y += finalFrame.size.height;
    
    [UIView mt_animateWithViews:@[viewController.view]
                       duration:0.5
                          delay:0.0
                 timingFunction:kMTEaseOutQuart
                     animations:^{
                         viewController.view.frame = finalFrame;
                         self.filterView.alpha = 0.0;
                     } completion:^{
                         [viewController.view removeFromSuperview];
                         [viewController removeFromParentViewController];
                         [self.filterView removeFromSuperview];
                     }];
}


- (void)hideViewControllerAnimateToRight:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    
    CGRect finalFrame = [self frameForModalViewController];
    finalFrame.origin.x += finalFrame.size.width + (self.view.frame.size.width - finalFrame.size.width) / 2;
    
    [UIView mt_animateWithViews:@[viewController.view]
                       duration:0.5
                          delay:0.0
                 timingFunction:kMTEaseOutQuart
                     animations:^{
                         viewController.view.frame = finalFrame;
                     } completion:^{
                         [viewController.view removeFromSuperview];
                         [viewController removeFromParentViewController];
                     }];
}

- (void)displayPopupViewController:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    viewController.view.frame = [self frameForPopupViewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (CGRect)frameForModalViewController {
    CGFloat parentWidth = self.view.bounds.size.width;
    CGFloat parentHeight = self.view.bounds.size.height;
    CGFloat horizontalGapSize = 10.0;
    CGFloat navigationBarHeight = 64;
    
    return CGRectMake(horizontalGapSize, navigationBarHeight + horizontalGapSize, parentWidth - horizontalGapSize * 2, parentHeight - horizontalGapSize - navigationBarHeight);
}

- (CGRect)frameForPopupViewController {
    CGFloat popupWidth = 240;
    CGFloat popupHeight = 280;
    CGFloat parentWidth = self.view.bounds.size.width;
    CGFloat parentHeight = self.view.bounds.size.height;
    
    CGRect popupFrame = CGRectMake(parentWidth / 2.0 - popupWidth / 2.0,
                                   parentHeight / 2.0 - popupHeight / 2.0,
                                   popupWidth,
                                   popupHeight);
    return popupFrame;
}

- (void)setLeftButtonToCancel {
    self.backButton.alpha = 1.0;
    self.cancelButton.alpha = 0.0;
    self.cancelButton.hidden = NO;
    self.cancelButton.enabled = YES;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.backButton.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        self.backButton.hidden = YES;
        self.backButton.enabled = NO;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.cancelButton.alpha = 1.0;
        } completion:nil];
    }];
}

- (void)setLeftButtonToBack {
    self.backButton.alpha = 0.0;
    self.backButton.hidden = NO;
    self.backButton.enabled = YES;
    
    [UIView transitionWithView:self.cancelButton
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.cancelButton.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        self.cancelButton.hidden = YES;
                        self.cancelButton.enabled = NO;
                        
                        [UIView animateWithDuration:0.25 animations:^{
                            self.backButton.alpha = 1.0;
                        } completion:nil];
                    }];
}

@end