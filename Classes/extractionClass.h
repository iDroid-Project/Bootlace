//
//  extractionClass.h
//  BootlaceV2
//
//  Created by Neonkoala on 15/06/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import <zlib.h>
#import <archive.h>
#import <archive_entry.h>
#import "installClass.h"

@class installClass;

@interface extractionClass : NSObject {
	installClass *installInstance;
}

@property (nonatomic, retain) installClass *installInstance;

- (int)inflateGzip:(NSString *)sourcePath toDest:(NSString *)destPath;
- (int)extractTar:(NSString *)sourcePath toDest:(NSString *)destPath;

@end
