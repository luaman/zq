#import "QuakeApplication.h"
#import "common.h"
#import "sys_osx.h"

@implementation QuakeApplication

- (void) sendSuperEvent: (NSEvent *) theEvent
{
    [super sendEvent: theEvent];
}

- (void) sendEvent: (NSEvent *) theEvent
{
	extern qbool host_initialized;
	
    // we need to intercept NSApps "sendEvent:" action:
	//    if ([[self delegate] hostInitialized] == YES)
	if (host_initialized)
    {
        if ([self isHidden] == YES)
        {
            [super sendEvent: theEvent];
        }
        else
        {
            Sys_DoEvents (theEvent, [theEvent type]);
        }
    }
    else
    {
        [super sendEvent: theEvent];
    }
}
@end

