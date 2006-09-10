/* QuakeApplication */

#import <Cocoa/Cocoa.h>

@interface QuakeApplication : NSApplication
{
}
- (void) sendSuperEvent: (NSEvent *) theEvent;
- (void) sendEvent: (NSEvent *) theEvent;
@end
