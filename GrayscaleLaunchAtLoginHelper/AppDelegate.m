/*
    GrayscaleLaunchAtLoginHelper - AppDelegate.m
 
    History:
 
    v. 1.0.0 (01/18/2019) - Initial version
 
    Copyright (c) 2019 Sriranga R. Veeraraghavan <ranga@calalum.org>
 
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
 
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
 
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */

#import "AppDelegate.h"
#import "Prefs.h"

/* Constants */

static int gDelayBeforeQuit = 15;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    BOOL alreadyRunning = NO;
    BOOL isActive = NO;
    BOOL launchAtLogin = YES;
    NSArray *running = nil;
    NSString *path = nil;
    NSString *newPath = nil;
    NSMutableArray *pathComponents = nil;
    NSRunningApplication *app = nil;
    NSUserDefaults *GSDefaults;
    
    /*
        Create a preference group to share preferences with the login
        helper app:
        https://stackoverflow.com/questions/14014417/reading-nsuserdefaults-from-helper-app-in-the-sandbox
     */

    GSDefaults = [[NSUserDefaults alloc] initWithSuiteName: gAppGroup];
    
    /* Get the user's preference for launching the app at login */
    
    launchAtLogin = [GSDefaults boolForKey: gPrefLaunchAtLogin];

    /* If the user doesn't want the app launched at login, terminate */
    
    if (!launchAtLogin)
    {
        sleep(gDelayBeforeQuit);
        [self actionTerminate];
    }
    
    /*
        Check if main app is already running; if yes, do nothing and terminate
        helper app

        From:
        https://blog.timschroeder.net/2012/07/03/the-launch-at-login-sandbox-project/
        https://blog.timschroeder.net/2014/01/25/detecting-launch-at-login-revisited/
     
        See also:
        http://martiancraft.com/blog/2015/01/login-items/
        https://stackoverflow.com/questions/30587446/smloginitemsetenabled-start-at-login-with-app-sandboxed-xcode-6-3-illustrat
     */
    
    running = [[NSWorkspace sharedWorkspace] runningApplications];
    if (running != nil) {
        for (app in running)
        {
            if ([[app bundleIdentifier] isEqualToString: gAppBundle])
            {
                alreadyRunning = YES;
                isActive = [app isActive];
                break;
            }
        }
    }
    
    if (!alreadyRunning || !isActive)
    {
        path = [[NSBundle mainBundle] bundlePath];
        pathComponents = [NSMutableArray arrayWithArray: [path pathComponents]];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject: @"MacOS"];
        [pathComponents addObject: gAppName];
        newPath = [NSString pathWithComponents: pathComponents];
        [[NSWorkspace sharedWorkspace] launchApplication: newPath];
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                            selector: @selector(actionTerminate)
                                                                name: gMsgTerminate
                                                              object: gAppBundle];
    }
    else
    {
        sleep(gDelayBeforeQuit);
        [self actionTerminate];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (void)actionTerminate
{
    [NSApp terminate: nil];
}

@end
