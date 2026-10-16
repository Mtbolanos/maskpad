// MaskPad AP: support for the Archipelago client of garrettjoecox's 2Ship fork on iOS.
#import <Foundation/Foundation.h>
#include "MaskPadAPSupport.h"
#include <SDL.h>

void MaskPad_InstallArchipelagoCertificates(void) {
    @autoreleasepool {
        NSString* bundled = [NSBundle.mainBundle pathForResource:@"cacert-bundle" ofType:@"crt"];
        if (bundled == nil) {
            SDL_Log("[MaskPad AP] no bundled CA list; Archipelago TLS connections will fail");
            return;
        }
        NSString* documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString* directory = [documents stringByAppendingPathComponent:@"networking"];
        NSString* target = [directory stringByAppendingPathComponent:@"cacert.pem"];
        NSFileManager* files = NSFileManager.defaultManager;
        NSData* source = [NSData dataWithContentsOfFile:bundled];
        // Refresh when the app ships a different list (an update), otherwise leave it alone.
        if ([files fileExistsAtPath:target] && [[NSData dataWithContentsOfFile:target] isEqualToData:source]) {
            return;
        }
        NSError* error = nil;
        [files createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        if (![source writeToFile:target options:NSDataWritingAtomic error:&error]) {
            SDL_Log("[MaskPad AP] could not install the CA list: %s", error.localizedDescription.UTF8String);
        }
    }
}
