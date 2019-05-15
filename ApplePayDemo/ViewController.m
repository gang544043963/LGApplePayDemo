//
//  ViewController.m
//  ApplePayDemo
//
//  Created by ethan li on 2019/4/18.
//  Copyright © 2019 Ethan Li. All rights reserved.
//

#import "ViewController.h"

#import <PassKit/PassKit.h>//用户绑定的银行卡信息
#import <PassKit/PKPaymentAuthorizationViewController.h>//Apple pay的展示控件
#import <AddressBook/AddressBook.h>//用户联系信息相关

@interface ViewController () <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *summaryItems; //账单列表
@property (nonatomic, strong) PKPaymentAuthorizationViewController *payVC;
@property (nonatomic, strong) PKPaymentRequest *payRequest;
@property (nonatomic, strong) NSArray *supportedNetworkCards;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 9.2, *)) {
        self.supportedNetworkCards =@[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa, PKPaymentNetworkChinaUnionPay];
    }
    
    [self setupPayButton];
}

//MARK: - Pravite

- (BOOL)canMakePayment {
    if(![PKPaymentAuthorizationViewController class]) {
        //PKPaymentAuthorizationViewController需iOS8.0以上支持
        NSLog(@"操作系统不支持ApplePay，请升级至9.0以上版本，且iPhone6以上设备才支持");
        return NO;
    }
    
    if(![PKPaymentAuthorizationViewController canMakePayments]) {
        //支付需iOS9.0以上支持
        NSLog(@"设备不支持ApplePay，请升级至9.0以上版本，且iPhone6以上设备才支持");
        return NO;
    }
    
    if (@available(iOS 9.2, *)) {
        
        if(![PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:self.supportedNetworkCards]) {
            NSLog(@"没有绑定支付卡");
            return NO;
        }
    } else {
        // Fallback on earlier versions
    }
    
    NSLog(@"可以支付，开始建立支付请求");
    return YES;
}

- (void)setupPayButton {
    PKPaymentButton *payButton = [PKPaymentButton buttonWithType:PKPaymentButtonTypeBuy style:PKPaymentButtonStyleWhiteOutline];
    payButton.center = self.view.center;
    [payButton addTarget:self action:@selector(action) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:payButton];
    
    PKPaymentButton *setupButton = [PKPaymentButton buttonWithType:PKPaymentButtonTypeSetUp style:PKPaymentButtonStyleWhiteOutline];
    setupButton.center = CGPointMake(self.view.center.x, self.view.center.y + 50);
    [setupButton addTarget:self action:@selector(jump2MakePaymentsUsingNetworks) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setupButton];
}


//MARK: - Button Action

- (void)action {
    if ([self canMakePayment]) {
        [self configPaymentInformation];
        //初始化ApplePay控件
        self.payVC = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:self.payRequest];
        self.payVC.delegate = self;
        [self presentViewController:self.payVC animated:YES completion:nil];
    }
}

- (void)jump2MakePaymentsUsingNetworks {
    //跳转到添加银行卡界面,系统直接就给我们提供了一个方法,直接创建界面,然后open即可
    PKPassLibrary *library = [[PKPassLibrary alloc] init];
    
    //跳转到绑定银行卡界面
    [library openPaymentSetup];
}

- (void)configPaymentInformation {
    //开始配置支付信息
    self.payRequest = [[PKPaymentRequest alloc] init];
    self.payRequest.countryCode = @"US";             //国家代码
    self.payRequest.currencyCode = @"USD";           //RMB的币种代码
    self.payRequest.merchantIdentifier = @"merchant.com.aspiraconnect.demo";//申请的merchantID
    
    self.payRequest.supportedNetworks = self.supportedNetworkCards; //用户可以进行支付的银行卡
    
    self.payRequest.merchantCapabilities = PKMerchantCapability3DS | PKMerchantCapabilityEMV;
    //设置支持的交易处理协议, 3DS必须支持, EMV为可选
    
    //payRequest.requiredShippingAddressFields = \
    PKAddressFieldPostalAddress | PKAddressFieldPhone | PKAddressFieldName;
    //设置发货地址
    self.payRequest.requiredShippingAddressFields = PKAddressFieldNone;
    //空发货地址
    self.payRequest.shippingMethods = @[];
    NSDecimalNumber *totalAmount = \
    [NSDecimalNumber decimalNumberWithString:@"0.01"];//创建金额
    
    PKPaymentSummaryItem *total = \
    [PKPaymentSummaryItem summaryItemWithLabel:@"My Company Name" amount:totalAmount];
    self.summaryItems = [NSMutableArray arrayWithArray:@[total]];
    self.payRequest.paymentSummaryItems = self.summaryItems;
}

//MARK: - <PKPaymentAuthorizationViewControllerDelegate>

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
    //支付凭据, 发给服务器端进行验证支付师傅真是有效
    PKPaymentToken *payToken = payment.token;
    
    //账单信息
    PKContact *billingContact = payment.billingContact;
    
    //送货信息
    PKContact *shippingContact = payment.shippingContact;
    
    //送货方式
    PKContact *shippingMethod = payment.shippingMethod;
    
    //等待服务器返回结果后再进行系统block调用
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //模拟服务器通信
        completion(PKPaymentAuthorizationStatusSuccess);
    });
}


@end
