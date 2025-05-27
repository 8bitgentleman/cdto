//
//  main.m
//  cd to ...
//
//  Created by James Tuley on 10/9/19.
//  Copyright © 2019 Jay Tuley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>

#import "Finder.h"
#import "Terminal.h"

NSUInteger linesOfHistory(TerminalTab* tab) {
   NSString* hist = [[tab history] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [[hist componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        FinderApplication* finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.Finder"];
        TerminalApplication* terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
                
        FinderItem *target = [(NSArray*)[[finder selection] get] firstObject];
        FinderFinderWindow* findWin = [[finder FinderWindows] objectAtLocation:@1];
        findWin = [[finder FinderWindows] objectWithID:[NSNumber numberWithInteger: findWin.id]];
        bool selected = true;
        if (target == nil){
            target = [[findWin target] get];
            selected = false;
        }
        
        if ([[target kind] isEqualToString:@"Alias"]){
            target = (FinderItem*)[(FinderAliasFile*)target originalItem];
        }
        
        NSString* fileUrl = [target URL];
        if(fileUrl != nil && ![fileUrl hasSuffix:@"/"] && selected){
            fileUrl = [fileUrl stringByDeletingLastPathComponent];
        }
        
        NSURL* url = [NSURL URLWithString:fileUrl];
        if (url != nil){
            
            // Store initial window state for auto-close detection
            NSInteger initialWindowCount = [[terminal windows] count];
            NSMutableArray* initialWindowIds = [NSMutableArray array];
            if (initialWindowCount > 0) {
                NSArray* windows = [[terminal windows] get];
                for (TerminalWindow* win in windows) {
                    [initialWindowIds addObject:@(win.id)];
                }
            }
            
            // Get user's preferred profile setting
            NSString* userSetName = [[NSUserDefaults standardUserDefaults] stringForKey:@"cdto-new-window-setting"];
            TerminalSettingsSet* targetSettings = nil;
            
            // If user specified a profile, find it
            if(userSetName != nil && ![userSetName isEqualToString:@""]) {
                for (TerminalSettingsSet *set in [terminal settingsSets]) {
                    if([[set name] isEqualToString:userSetName]){
                        targetSettings = set;
                        break;
                    }
                }
            }
            
            // If no user preference or profile not found, use Terminal's current default
            if (targetSettings == nil) {
                targetSettings = [terminal defaultSettings];
            }
            
            // Open the directory (shell agnostic)
            [terminal open:@[url]];
            
            // Wait briefly for Terminal to create windows
            [NSThread sleepForTimeInterval:0.5f];
            
            NSInteger finalWindowCount = [[terminal windows] count];
            
            // Find the new window that was created and apply correct theme
            NSArray* allWindows = [[terminal windows] get];
            TerminalWindow* targetWindow = nil;
            TerminalWindow* extraWindow = nil;
            
            for (TerminalWindow* win in allWindows) {
                NSNumber* winId = @(win.id);
                
                // If this window wasn't there initially, it's new
                if (![initialWindowIds containsObject:winId]) {
                    // Check window properties to determine which is the target
                    NSArray* tabs = [[win tabs] get];
                    if([tabs count] == 1) {
                        TerminalTab* tab = [tabs firstObject];
                        
                        NSString* content = [tab contents];
                        NSUInteger contentLength = [content length];
                        NSUInteger historyLines = linesOfHistory(tab);
                        
                        // The window with more content/history is likely the target
                        if (contentLength > 50 || historyLines > 2) {
                            targetWindow = win;
                        } else {
                            extraWindow = win;
                        }
                    }
                }
            }
            
            // If we couldn't identify target window, use the frontmost new window
            if (targetWindow == nil && finalWindowCount > initialWindowCount) {
                targetWindow = [[terminal windows] objectAtLocation:@1];
            }
            
            // Apply correct profile to target window
            if (targetWindow != nil) {
                NSArray* tabs = [[targetWindow tabs] get];
                if([tabs count] == 1) {
                    TerminalTab* targetTab = [tabs firstObject];
                    
                    // Set the profile and refresh
                    targetTab.currentSettings = targetSettings;
                    [NSThread sleepForTimeInterval:0.2f];
                    targetWindow.frontmost = YES;
                }
            }
            
            // Enhanced auto-close logic
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"cdto-close-default-window"]){
                // If we started with 1 window and now have 2, close the original if it's unused
                if (initialWindowCount == 1 && finalWindowCount == 2 && targetWindow != nil) {
                    NSNumber* originalWindowId = [initialWindowIds firstObject];
                    
                    for (TerminalWindow* win in allWindows) {
                        if (win.id == [originalWindowId integerValue]) {
                            NSArray* tabs = [[win tabs] get];
                            if([tabs count] == 1) {
                                TerminalTab* tab = [tabs firstObject];
                                NSUInteger historyLines = linesOfHistory(tab);
                                
                                // If the original window has minimal activity, close it
                                if (historyLines <= 3 && ![tab busy]) {
                                    [win closeSaving:TerminalSaveOptionsNo savingIn:nil];
                                }
                            }
                            break;
                        }
                    }
                }
                // Handle case where extra new windows were created
                else if (extraWindow != nil) {
                    [extraWindow closeSaving:TerminalSaveOptionsNo savingIn:nil];
                }
            }
            
            [terminal activate];
        }
    }
}
