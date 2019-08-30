//
//  SettingsWindowController.m
//  c12TT
//
//  Created by Francisco Cardoso on 29/08/2019.
//  Copyright © 2019 c12. All rights reserved.
//

#import "SettingsWindowController.h"

@interface SettingsWindowController () <NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSTextField *projectManagerTextField;
@property (nonatomic, strong) IBOutlet NSTextField *costCenterTextField;
@property (nonatomic, strong) IBOutlet NSTextField *projectTextField;
@property (nonatomic, strong) IBOutlet NSTextField *taskTextField;
@property (nonatomic, strong) IBOutlet NSButtonCell *showTotalsCheckBox;

@end

@implementation SettingsWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.delegate = self;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", appSupportPath, kAppSupportDir, kSettingsFile];
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];

    if (exists) {
        NSLog(@"Settings file exists, loading");
        
        NSDictionary *configData = [NSDictionary dictionaryWithContentsOfFile:filePath];
        self.projectManagerTextField.stringValue = configData[kProjectManagerKey] ? : @"";
        self.costCenterTextField.stringValue = configData[kCostCenterKey]? : @"";
        self.projectTextField.stringValue = configData[kProjectKey]? : @"";
        self.taskTextField.stringValue = configData[kTaskKey]? : @"";
        self.showTotalsCheckBox.state = [configData[kShowTotals] boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
    }
    else {
        NSLog(@"Settings file doesn't exist");
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSMutableDictionary *newConfigData = [NSMutableDictionary dictionary];
    
    newConfigData[kProjectManagerKey] = self.projectManagerTextField.stringValue;
    newConfigData[kCostCenterKey] = self.costCenterTextField.stringValue;
    newConfigData[kProjectKey] = self.projectTextField.stringValue;
    newConfigData[kTaskKey] = self.taskTextField.stringValue;
    newConfigData[kShowTotals] = self.showTotalsCheckBox.state == NSControlStateValueOn ? @(YES) : @(NO);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", appSupportPath, kAppSupportDir, kSettingsFile];

    BOOL success = [newConfigData writeToFile:filePath atomically:YES];
    
    if (success) {
        NSLog(@"Wrote settings file");
    }
    else {
        NSLog(@"Couldn't wrote settings file");
    }
}

@end
