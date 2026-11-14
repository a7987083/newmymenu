#import <Foundation/Foundation.h>
#import "NMMachOSigner.h"
#include <stdio.h>
int main(int argc,char **argv){@autoreleasepool{if(argc!=3)return 2;NSError *error=nil;NSDictionary *r=[NMMachOSigner signedCopyFromPath:[NSString stringWithUTF8String:argv[1]] toPath:[NSString stringWithUTF8String:argv[2]] error:&error];if(!r){fprintf(stderr,"signer refused: %s\n",error.localizedDescription.UTF8String);return 1;}NSData *json=[NSJSONSerialization dataWithJSONObject:r options:NSJSONWritingSortedKeys error:&error];if(!json)return 3;puts([[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding].UTF8String);return 0;}}
