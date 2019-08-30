//
//  AppDelegate.m
//  c12tt
//
//  Created by Francisco Cardoso on 05/04/2018.
//  Copyright © 2019 c12. All rights reserved.
//

#import "AppDelegate.h"
#import "SettingsWindowController.h"

typedef enum {
    StartStopMenuItem,
    ResetMenuItem,
    ReportMenuItem,
    SettingsSeparatorMenuItem,
    SettingsMenuItem,
    ExitSeparatorMenuItem,
    ExitMenuItem
} MenuItems;

@interface AppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSMutableArray <NSArray <NSDate *> *> *logDates;
@property (nonatomic, strong) NSDate *currentLoginDate;
@property (nonatomic, strong) NSString *reportString;
@property (nonatomic, strong) SettingsWindowController *settingsWindowController;
@property (nonatomic) BOOL recording;
@property (nonatomic) BOOL paused;
@property (nonatomic) BOOL showTotals;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self createAppSupportDirectory];
    [self copyDefaultSettingsIfNecessary];
    
    self.logDates = [self loadTimesFromFile];

    if (!self.logDates) {
        self.logDates = [NSMutableArray array];
    }

    //Test data
//    NSDateFormatter *dateFormatter = [NSDateFormatter new];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-09 09:30"], [dateFormatter dateFromString:@"2018-04-09 12:10"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-09 13:10"], [dateFormatter dateFromString:@"2018-04-09 18:30"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-10 09:30"], [dateFormatter dateFromString:@"2018-04-10 12:05"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-10 13:18"], [dateFormatter dateFromString:@"2018-04-10 18:45"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-11 09:38"], [dateFormatter dateFromString:@"2018-04-11 12:31"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-11 13:33"], [dateFormatter dateFromString:@"2018-04-11 18:43"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-12 09:35"], [dateFormatter dateFromString:@"2018-04-12 12:08"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-12 13:15"], [dateFormatter dateFromString:@"2018-04-12 18:45"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-13 09:54"], [dateFormatter dateFromString:@"2018-04-13 12:10"]]];
//    [self.logDates addObject:@[[dateFormatter dateFromString:@"2018-04-13 12:50"], [dateFormatter dateFromString:@"2018-04-13 18:37"]]];

    self.recording = NO;
    self.paused = NO;
    self.showTotals = NO;
    
    [self loadSettings];
    
    NSLog(@"Report string: %@", self.reportString);
    NSLog(@"Show Totals: %d", self.showTotals);
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    NSStatusBarButton *statusBarButton = self.statusItem.button;
    statusBarButton.image = [NSImage imageNamed:@"barIcon.png"];
    [statusBarButton.image setTemplate:YES];
    statusBarButton.highlighted = NO;
    [statusBarButton setAction:@selector(itemClicked:)];
    [statusBarButton sendActionOn:(NSEventMaskLeftMouseDown)];
    
    self.menu = [NSMenu new];
    [self.menu setAutoenablesItems:NO];
    
    [self.menu addItem:[[NSMenuItem alloc] initWithTitle:@"Start" action:@selector(startStopRecording) keyEquivalent:@""]];
    [self.menu addItem:[[NSMenuItem alloc] initWithTitle:@"Reset" action:@selector(reset) keyEquivalent:@""]];
    [self.menu addItem:[[NSMenuItem alloc] initWithTitle:@"Report"action:@selector(report) keyEquivalent:@""]];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItem:[[NSMenuItem alloc] initWithTitle:@"Settings" action:@selector(settings) keyEquivalent:@""]];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItem:[[NSMenuItem alloc] initWithTitle:@"Exit" action:@selector(exit) keyEquivalent:@""]];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(receivedWakeNotification:)
                                                               name:NSWorkspaceDidWakeNotification
                                                             object:NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(receivedSleepNotification:)
                                                               name:NSWorkspaceWillSleepNotification
                                                             object:NULL];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(receivedLockNotification)
                                                            name:@"com.apple.screenIsLocked"
                                                          object:nil
     ];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(receivedUnlockNotification)
                                                            name:@"com.apple.screenIsUnlocked"
                                                          object:nil
     ];
    
    [self startStopRecording];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self saveTimesToFile];
}

#pragma mark - Notifications

- (void)receivedSleepNotification:(id)sender
{
    NSLog(@"receiveSleepNotification: %@", sender);
    [self pauseRecording];
}

- (void)receivedWakeNotification:(id)sender
{
    NSLog(@"receiveWakeNotification: %@", sender);
    [self resumeRecording];
}

- (void)receivedLockNotification
{
    BOOL isLunchTime = [self isItLunchTime];
    
    NSLog(@"receivedLockNotification, lunch time? %d", isLunchTime);
    
    if (isLunchTime) {
        [self pauseRecording];
    }
}


- (void)receivedUnlockNotification
{
    NSLog(@"receivedUnlockNotification, paused? %d", self.paused);
    
    if (self.paused) {
        [self resumeRecording];
    }
}

#pragma mark - Actions

- (void)itemClicked:(id)sender
{
    if (self.logDates.count == 0 && !self.currentLoginDate) {
        [self.menu itemAtIndex:ResetMenuItem].enabled = NO;
        [self.menu itemAtIndex:ReportMenuItem].enabled = NO;
    }
    else {
        [self.menu itemAtIndex:ResetMenuItem].enabled = YES;
        [self.menu itemAtIndex:ReportMenuItem].enabled = YES;
    }

    [self.statusItem popUpStatusItemMenu:self.menu];
}

- (void)settings
{
    NSLog(@"Settings");
    
    if (self.settingsWindowController == nil) {
        self.settingsWindowController = [[SettingsWindowController alloc] initWithWindowNibName:@"SettingsWindowController"];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(settingsWindowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:self.settingsWindowController.window];
    }

    [self.settingsWindowController.window makeKeyAndOrderFront:self.settingsWindowController];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)settingsWindowWillClose:(NSNotification *)notification
{
    NSWindow* window = notification.object;
    
    if (window == self.settingsWindowController.window) {
        self.settingsWindowController = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:window];
    
    [self loadSettings];
}

- (void)reset
{
    NSLog(@"Reset");
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Delete"];
    [alert setMessageText:@"Warning"];
    [alert setInformativeText:@"Do you really want to delete all data?"];
    [alert setAlertStyle:NSAlertStyleWarning];
    NSModalResponse action = [alert runModal];
    
    if(action == NSAlertSecondButtonReturn) {
        self.recording = NO;
        self.logDates = [NSMutableArray array];
        [self deleteTimesFile];
        [[self.menu itemAtIndex:StartStopMenuItem] setTitle:@"Start"];
        [self.menu itemAtIndex:ReportMenuItem].enabled = NO;
        [self.menu itemAtIndex:ResetMenuItem].enabled = NO;

    }
}

- (void)startStopRecording
{
    if (!self.recording) {
        self.recording = YES;
        self.currentLoginDate = [NSDate date];
        [[self.menu itemAtIndex:StartStopMenuItem] setTitle:@"Stop"];
        NSLog(@"Start: %@", self.currentLoginDate);
    }
    else {
        if (self.currentLoginDate != nil) {
            NSDate *logoutDate = [NSDate date];
            [self.logDates addObject:@[self.currentLoginDate, logoutDate]];
            NSLog(@"Stop: %@", logoutDate);
            [self saveTimesToFile];
            self.recording = NO;
        }

        [[self.menu itemAtIndex:StartStopMenuItem] setTitle:@"Start"];
    }
}

- (void)pauseRecording
{
    if (self.recording && self.currentLoginDate != nil) {
        self.paused = YES;
        NSDate *logoutDate = [NSDate date];
        [self.logDates addObject:@[self.currentLoginDate, logoutDate]];
        
        NSLog(@"Stop: %@", logoutDate);
    }
}

- (void)resumeRecording
{
    if (self.recording) {
        self.paused = NO;
        self.currentLoginDate = [NSDate date];
        NSLog(@"Start: %@", self.currentLoginDate);
    }
}

- (void)exit
{
    NSLog(@"Exit");
    [self saveTimesToFile];
    [NSApp terminate: nil];
}

- (void)report
{
    if (self.logDates.count > 0 || self.currentLoginDate) {
        NSInteger totalMinutes = 0;
        BOOL timeOnWeekend = NO;
        BOOL smallSession = NO;
        
        NSDateFormatter *dayDateFormatter = [NSDateFormatter new];
        [dayDateFormatter setDateFormat:@"yyyy-MM-dd"];
        
        NSDateFormatter *timeDateFormatter = [NSDateFormatter new];
        [timeDateFormatter setDateFormat:@"HH:mm"];

        NSString *firstDay = [dayDateFormatter stringFromDate:[self.logDates firstObject][0]];
        NSString *lastDay = [dayDateFormatter stringFromDate:[self.logDates lastObject][0]];
        
        if (!firstDay) {
            firstDay = [dayDateFormatter stringFromDate:self.currentLoginDate];
        }
        
        if (!lastDay) {
            lastDay = [dayDateFormatter stringFromDate:self.currentLoginDate];
        }
        
        NSString *filename = [NSString stringWithFormat:@"%@_%@.log", firstDay, lastDay];
        
        NSDate *currentDay = nil;
        NSMutableString *report = [NSMutableString string];
        NSMutableArray <NSString *> *errorStrings = [NSMutableArray array];

        if (self.recording && self.currentLoginDate) {
            //Add current session to report but remove it after generating report
            [self.logDates addObject:@[self.currentLoginDate, [NSDate date]]];
        }
        
        NSInteger dayTotalMinutes = 0;
        
        for (NSArray *session in self.logDates) {
            if (currentDay == nil || ![self isSameDay:currentDay otherDay:session[0]]) {
                if (self.showTotals && dayTotalMinutes > 0) {
                    [report appendFormat:@"\n***** Day total: %@ *****", minutesToTimeString(dayTotalMinutes)];
                    dayTotalMinutes = 0;
                }

                currentDay = session[0];
                [report appendString:@"\n\n"];
                [report appendString:[dayDateFormatter stringFromDate:session[0]]];
            }
            [report appendFormat:@"\n%@\t%@\t%@", [timeDateFormatter stringFromDate:session[0]], [timeDateFormatter stringFromDate:session[1]], self.reportString];

            NSInteger sessionMinutes = [self minutesFromStartDate:session[0] toEndDate:session[1]];
            
            dayTotalMinutes += sessionMinutes;
            
            totalMinutes += sessionMinutes;
            
            if (!timeOnWeekend && [self isDateOnWeeked:session[0]]) {
                NSLog(@"!!! Warning: time on weekend !!!");
                timeOnWeekend = YES;
                [errorStrings addObject:@"Time on weekend"];
            }
            
            if (!smallSession && sessionMinutes <= 10) {
                NSLog(@"!!! Warning: There is at least one session <= 10 minutes. !!!");
                smallSession = YES;
                [errorStrings addObject:@"There is at least one session <= 10 minutes"];
            }
        }
        
        if (self.showTotals) {
            [report appendFormat:@"\n***** Day total: %@ *****", minutesToTimeString(dayTotalMinutes)];
            [report appendFormat:@"\n\n***** Week total: %@ *****", minutesToTimeString(totalMinutes)];
        }
        
        if (self.recording && self.currentLoginDate) {
            //Add current session to report but remove it after generating report
            [self.logDates removeLastObject];
        }
        
        CGFloat totalHours = totalMinutes/60.0f;
        
        NSLog(@"total hours: %.2f", totalHours);
        NSLog(@"%@", report);
        
        if (totalHours > 42) {
            NSLog(@"!!! Warning: total hours > 42 !!!");
            [errorStrings addObject:@"Total hours greater than 42"];
        }

        if (totalHours < 40) {
            NSLog(@"!!! Warning: total hours < 40 !!!");
            [errorStrings addObject:@"Total hours lesser than 40"];
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES );
        NSString *desktopPath = [paths objectAtIndex:0];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", desktopPath, filename];
        NSLog(@"Writing file to: %@", filePath);
        
        NSError *error = nil;
        [report writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"Error writing to file %@", [error description]);
        }
        
        [self showReportAlertWithTotalHours:totalHours errors:errorStrings];
    }
}

#pragma mark - Utils

NSString *minutesToTimeString(int minutes)
{
    CGFloat hours = minutes / 60.0f;
    CGFloat decMinutes = hours - floor(hours);
    NSString *minutesString = nil;
    
    if ((long)(decMinutes*60.0f) < 10) {
        minutesString = [NSString stringWithFormat:@"0%ld", (long)(decMinutes*60.0f)];
    }
    else {
        minutesString = [NSString stringWithFormat:@"%ld", (long)(decMinutes*60.0f)];
    }
    
    return [NSString stringWithFormat:@"%ldh%@", (long)(floor(hours)), minutesString];
}

- (void)showReportAlertWithTotalHours:(NSInteger)totalHours errors:(NSArray*)errorStrings
{
    NSMutableString *reportString = [NSMutableString string];
    
    [reportString appendString:[NSString stringWithFormat:@"Total hours: %ld\n\n", (long)totalHours]];
    
    if (errorStrings.count > 0) {
        [reportString appendString:@"Errors:\n"];
        
        for (NSString *errorString in errorStrings) {
            [reportString appendString:[NSString stringWithFormat:@"- %@\n", errorString]];
        }
    }
    
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Report generated"];
    [alert setInformativeText:reportString];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
}

- (BOOL)isDateOnWeeked:(NSDate*)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [calendar isDateInWeekend:date];
}

- (NSInteger)minutesFromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitMinute fromDate:startDate toDate:endDate options:0];
    return components.minute;
}

- (BOOL)isSameDay:(NSDate*)date1 otherDay:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

- (BOOL)isItLunchTime
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                                   fromDate:[NSDate date]];
    NSInteger currentHour = [components hour];
    
    if (currentHour >= kLunchTimeStart
        && currentHour <= kLunchTimeEnd) {
        return YES;
    }
    
    return NO;
}

- (void)loadSettings
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", appSupportPath, kAppSupportDir, kSettingsFile];
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    
    if (exists) {
        NSDictionary *configData = [NSDictionary dictionaryWithContentsOfFile:filePath];
        self.reportString = [NSString stringWithFormat:@"%@\t%@\t%@\t%@", configData[kProjectManagerKey], configData[kCostCenterKey], configData[kProjectKey], configData[kTaskKey]];
        self.showTotals = [configData[kShowTotals] boolValue];
    }
    else {
        self.reportString = @"";
        self.showTotals = NO;
    }
}

#pragma mark - File operations

- (void)saveTimesToFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *dirPath = [paths objectAtIndex:0];
    
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating directory %@", [error description]);
            return;
        }
        else {
            NSLog(@"Created directory %@", dirPath);
        }
    }
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", dirPath, kAppSupportDir, kDbFile];
    NSLog(@"Writing file to: %@", filePath);
    
    [self.logDates writeToFile:filePath atomically:NO];
    
    if (error) {
        NSLog(@"Error writing to file %@", [error description]);
    }
}

- (NSMutableArray*)loadTimesFromFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", appSupportPath, kAppSupportDir, kDbFile];
    NSLog(@"Loading file: %@", filePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [NSMutableArray arrayWithContentsOfFile:filePath];
    }
    
    return nil;
}

- (void)deleteTimesFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", appSupportPath, kAppSupportDir, kDbFile];
    NSLog(@"Deleting file: %@", filePath);
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    
    if (error) {
        NSLog(@"Error deleting file %@", [error description]);
    }
}

- (void)copyDefaultSettingsIfNecessary
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", appSupportPath, kAppSupportDir, kSettingsFile];

    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
 
    if (!exists) {
        NSError *error;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"default_report_data" ofType:@"plist"];
        if (path != nil) {
            BOOL success = [[NSFileManager defaultManager] copyItemAtPath:path toPath:filePath error:&error];
            
            if(!success) {
                NSLog(@"Error copying default settings file, %@", error);
            }
            else {
                NSLog(@"Copied default settings file");
            }
        }
        else {
            BOOL success = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
            
            if (success) {
                NSLog(@"Created settings file");
            }
            else {
                NSLog(@"Couldn't create settings file");
            }
            
        }
    }
}

- (void)createAppSupportDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES );
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *dirPath = [NSString stringWithFormat:@"%@/%@", appSupportPath, kAppSupportDir];
    
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating directory %@", [error description]);
            return;
        }
        else {
            NSLog(@"Created directory %@", dirPath);
        }
    }
    else {
        NSLog(@"Directory already exists at path %@", dirPath);
    }
}

@end
