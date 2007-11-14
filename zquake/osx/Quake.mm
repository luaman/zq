#import "Cocoa/Cocoa.h"
#import "Quake.h"
#import "common.h"
#import "q_shared.h"
#import "mathlib.h"
#import "cmodel.h"
#import "pmove.h"
#import "input.h"

@interface Quake (NSApplicationDefined)
- (void) applicationDidFinishLaunching: (NSNotification *) theNote;
@end

@implementation Quake

extern int main_argc;
extern char *main_argv[];

- (void) timerTic: (NSTimer *) theTimer
{
    static double		mOldFrameTime;
	double	myNewFrameTime, myFrameTime;
	
    if ([NSApp isHidden] == YES) {
        return;
    }
    
    myNewFrameTime = Sys_DoubleTime ();
    myFrameTime = myNewFrameTime - mOldFrameTime;
    mOldFrameTime = myNewFrameTime;
	
    // finally do the frame:
    Host_Frame (myFrameTime);
	
	[self installFrameTimer];
}

//___________________________________________________________________________________________________________installFrameTimer

- (void) installFrameTimer
{
    if (mFrameTimer == NULL)
    {
		// we may not set the timer interval too small, otherwise we wouldn't get AppleScript commands. odd eh?
        mFrameTimer = [NSTimer scheduledTimerWithTimeInterval: 0.0003f //0.000001f
                                                       target: self
                                                     selector: @selector (timerTic:)
                                                     userInfo: NULL
                                                      repeats: YES];
        
        if (mFrameTimer == NULL)
        {
            Sys_Error ("Failed to install the renderer loop!");
        }
    }
}

//_____________________________________________________________________________________________________________fireFrameTimer:


- (IBAction)newGame: (id)sender
{
	int argc = main_argc;
	char **argv = main_argv;
	/*
	char *fakeargv[4] = {"", "-basedir", "/Users/tony/q", "+map dm6"};

	if (argc == 1) {
		argc = 4;
		argv = fakeargv;
	} */
	
	// we need to check for -noconinput and -nostdout
	// before Host_Init is called
	COM_InitArgv (argc, argv);
	
	Host_Init (argc, argv, 32*1024*1024);
	
	[self installFrameTimer];
}

- (void)applicationDidFinishLaunching: (NSNotification *) theNote
{
	[self newGame: nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{
	return YES;
}

//_______________________________________________________________________________________________________dealloc

- (void) dealloc
{
    if (mDistantPast != NULL)
    {
        [mDistantPast release];
        mDistantPast = NULL;
    }
}

//___________________________________________________________________________________________________distantPast

- (NSDate *) distantPast
{
    return (mDistantPast);
}

//__________________________________________________________________________________________________awakeFromNib

- (void) awakeFromNib
{
    // required for event handling:
    mDistantPast = [[NSDate distantPast] retain];
}	
	

@end
