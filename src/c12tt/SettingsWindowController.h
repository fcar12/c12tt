//
//  SettingsWindowController.h
//  c12TT
//
//  Created by Francisco Cardoso on 29/08/2019.
//  Copyright © 2019 c12. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef DEBUG
#   define NSLog(...) NSLog(__VA_ARGS__)
#else
#   define NSLog(...) (void)0
#endif

NS_ASSUME_NONNULL_BEGIN

static const NSString *kDbFile = @"c12tt.db";
static const NSString *kAppSupportDir = @"c12tt";
static const NSString *kSettingsFile = @"report_data.plist";
static const NSString *kProjectManagerKey = @"ProjectManager";
static const NSString *kCostCenterKey = @"CostCenter";
static const NSString *kProjectKey = @"Project";
static const NSString *kTaskKey = @"Task";
static const NSString *kShowTotals = @"ShowTotals";
static const NSInteger kLunchTimeStart = 12;
static const NSInteger kLunchTimeEnd = 14;

@interface SettingsWindowController : NSWindowController

@end

NS_ASSUME_NONNULL_END
