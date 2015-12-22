//
//  PAAddCustomerViewController.m
//  haofang
//
//  Created by Hui Xu on 1/4/15.
//  Copyright (c) 2015 平安好房. All rights reserved.
//

#import "PAForeignHouseAddCustomerViewController.h"
#import "PAForeignHouseAddCustomerViewModel.h"
#import "PADefaultFormView.h"
#import "PACustomerStatusModel.h"
#import "PAForeignHouseCustomerForm.h"

@interface PAForeignHouseAddCustomerViewController ()

@property (nonatomic, readonly) PAForeignHouseCustomerForm *form;
@property (nonatomic, strong) PAForeignHouseAddCustomerViewModel *viewModel;

@property (nonatomic, strong) MBProgressHUD *executingProgressHUD;

@end

@implementation PAForeignHouseAddCustomerViewController

#pragma mark - 对象和视图生命周期

- (instancetype) initWithQuery:(NSDictionary *)query {
    if (self = [super init]) {
        self.viewModel = [query objectForKey:@"_viewModel"];
    }
    return self;
}

- (void) dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"海外报备";
    
    // 将意向楼盘城市置空
    
    self.executingProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.executingProgressHUD.labelText = @"正在检查客户信息，请稍候...";
    [self.view addSubview:self.executingProgressHUD];
    [self.executingProgressHUD show:YES];
    self.disableInteractiveGesture = YES;
    
    [self setupDataBinding];
}

- (PAForm *)loadForm {
    return [[PAForeignHouseCustomerForm alloc] init];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 数据绑定

- (void) setupDataBinding {
    
    // 绑定表单数据
    
    RACChannelTo(self.form.customerNameField, value) = RACChannelTo(self, viewModel.customerName);
    RACChannelTo(self.form.customerPhoneNumberField, value) = RACChannelTo(self, viewModel.customerPhoneNumber);
    
    // 绑定进行中HUD
    RAC(self.executingProgressHUD, hidden) = [self.viewModel.validateCustomerCommand.executing not];
}


#pragma mark - 覆盖父类方法

- (void)didSelectField:(PAFormField *)field {
    [super didSelectField:field];
    
    if (field == self.form.nextStepField){
        [self.view endEditing:YES];
        
        BOOL enabled = ((PAButtonFormView *)field.instanceView).button.enabled;
        
        if (!enabled || ![self checkFormValid]) {
            return;
        }
        
        @weakify(self);
        // view model执行验证并对验证结果进行处理
        [[self.viewModel.validateCustomerCommand execute:nil]
            subscribeNext:^(PACustomerStatusModel *customerStatus) {
                @strongify(self);
                
                if (customerStatus.status != 0) {
                    // 客户已经被占用，设置错误信息
                    self.viewModel.error = [NSError errorWithDomain:PAErrorDomain
                                                               code:-1
                                                           userInfo:@{NSLocalizedDescriptionKey: customerStatus.reason}];
                }
                
                self.viewModel.customerName = self.form.customerNameField.value;
                self.viewModel.customerPhoneNumber = self.form.customerPhoneNumberField.value;
                
                PAForeignHouseCustomerIntentionListViewModel *viewModel = [[PAForeignHouseCustomerIntentionListViewModel alloc] init];
                viewModel.dataModel = self.viewModel.dataModel;
                [[PANavigator sharedInstance] gotoViewWithIdentifier:APPURL_VIEW_IDENTIFIER_HFT_ADDFOREIGNCUSTOMERINTENTION
                                                        queryForInit:@{@"_viewModel": viewModel}
                                                  propertyDictionary:nil];
            }
            error:^(NSError *error) {
                if ([error.domain isEqualToString:PAErrorDomain]) {
                    [PANoticeUtil showNotice:[error localizedDescription]];
                }
                else {
                    [PANoticeUtil showNotice:@"网络连接出现异常，请稍后重试"];
                }
            }];
    }
}


@end
