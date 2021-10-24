#import "md5chksum.h"
#import "CDVFile.h"
#import <Cordova/CDV.h>
#include <CommonCrypto/CommonDigest.h>
#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

@implementation md5chksum

- (NSString *)getUrl:(NSString *)urlString
{
    NSString *path = nil;
    id filePlugin = [self.commandDelegate getCommandInstance:@"File"];
    if (filePlugin != nil) {
        CDVFilesystemURL* url = [CDVFilesystemURL fileSystemURLWithString:urlString];
        path = [filePlugin filesystemPathForURL:url];
    }
    if (path == nil) {
        if ([urlString hasPrefix:@"file:"]) {
            path = [[NSURL URLWithString:urlString] path];
        }
    }
    return path;
}

- (NSURL *)assetLibraryURLForLocalURL:(CDVFilesystemURL *)path
{
    NSURL *r_url = [NSURL URLWithString:[NSString stringWithFormat:@"assets-library://asset/asset?id=%@", path]];

    return r_url;
}

- (void)asset:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        NSString *url  = [command.arguments objectAtIndex:0];

        NSUInteger chunkSize = 10 * 1024 * 1024;

        ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset* asset) {

            if (asset) {
                // We have the asset!  Get the data and send it off.
                ALAssetRepresentation* assetRepresentation = [asset defaultRepresentation];
                NSUInteger size = [assetRepresentation size];
                Byte* buffer = (Byte*)malloc(size);

                CC_MD5_CTX md5;
                CC_MD5_Init(&md5);
                BOOL done = NO;

                NSUInteger offset = 0;

                while(!done)
                {
                    @autoreleasepool {
                        NSUInteger bytesCopied = [assetRepresentation getBytes:buffer fromOffset:offset length:chunkSize error:nil];
                        offset += bytesCopied;
                        NSData *data = [[NSData alloc] initWithBytes:buffer length:bytesCopied];
                        CC_MD5_Update(&md5, [data bytes], [data length]);
                        if( [data length] == 0 ) done = YES;
                    }
                }

                free(buffer);

                unsigned char digest[CC_MD5_DIGEST_LENGTH];
                CC_MD5_Final(digest, &md5);
                NSString* hex = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];

                CDVPluginResult *pluginResult  = nil;

                if (hex != nil && [hex length] > 0) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:hex];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                }

                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } else {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        };


        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError* error) {
            // Retrieving the asset failed for some reason.  Send the appropriate error.
            NSLog(@"Error: %@", error);

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        };

        ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary assetForURL:[self assetLibraryURLForLocalURL:url] resultBlock:resultBlock failureBlock:failureBlock];


    }];
}

- (void)file:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        NSString *url  = [command.arguments objectAtIndex:0];
//        NSString *path = [self getUrl:url];
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:url];
        CC_MD5_CTX md5;
        CC_MD5_Init(&md5);
        BOOL done = NO;
        while(!done)
        {
            NSData* fileData = [handle readDataOfLength: 4096];
            CC_MD5_Update(&md5, [fileData bytes], [fileData length]);
            if( [fileData length] == 0 ) done = YES;
        }
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &md5);
        NSString* hex = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
        if (hex != nil && [hex length] > 0) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:hex];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}
@end